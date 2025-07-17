import LoggingKit
import Neptune
import TransferResources
import TWUI
import UIKit

// sourcery: AutoMockable
protocol AccountDetailsListView: AnyObject {
    func configureHeader(viewModel: LargeTitleViewModel)
    func setupNavigationLeftButton(buttonStyle: UIBarButtonItem.BackButtonType, buttonAction: @escaping () -> Void)

    func updateList(sections: [AccountDetailListSectionModel])

    func showHud()
    func hideHud()

    func showInfoModal(title: String, message: String)

    func presentAlert(message: String, backAction: @escaping () -> Void)
    func presentSnackBar(message: String)
}

final class AccountDetailsListViewController: AbstractViewController, OptsIntoAutoBackButton, HasPostStandardDismissAction {
    private let keyboardDismisser = KeyboardDismisser()

    private let presenter: AccountDetailListPresenter
    private var sectionViewModels: [AccountDetailListSectionModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    init(presenter: AccountDetailListPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardDismisser.attach(toView: view)

        setupView()
        presenter.start(withView: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.viewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        headerView.clearSearchText()
        presenter.updateSearchQuery("")
    }

    func performPostStandardDismissAction(ofType type: DismissActionType) {
        presenter.dismissed()
    }

    private func setupView() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(tableView)
        tableView.addTableHeaderView(headerView)
        tableView.constrainToSuperview(.contentArea)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        headerView.frame.size.height = headerView.size(fittingWidth: tableView.frame.width).height
    }

    private lazy var tableView: UITableView = {
        let t = TWTableView()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.register(cellType: NavigationOptionTableViewCell.self)
        t.register(headerFooterType: TableSectionHeaderView.self)
        t.register(headerFooterType: AccountDetailsListFooterView.self)
        t.rowHeight = UITableView.automaticDimension
        t.sectionHeaderHeight = UITableView.automaticDimension
        t.sectionFooterHeight = UITableView.automaticDimension
        t.estimatedRowHeight = NavigationOptionTableViewCell.estimatedRowHeight
        t.delegate = self
        t.dataSource = self
        t.backgroundColor = .clear
        return t
    }()

    private lazy var headerView = LargeTitleView(
        scrollObserver: tableView.scrollObserver(),
        delegate: self,
        padding: LargeTitleView.topAndHorizontalPadding
    )
    .with {
        $0.onSearchTextFieldDidChange { [weak self] searchText in
            guard let self,
                  let text = searchText else {
                return
            }
            presenter.updateSearchQuery(text)
        }
    }
}

// MARK: AccountDetailList Protocol Implemenation

extension AccountDetailsListViewController: AccountDetailsListView {
    func configureHeader(viewModel: LargeTitleViewModel) {
        headerView.configure(with: viewModel)
    }

    func setupNavigationLeftButton(buttonStyle: UIBarButtonItem.BackButtonType, buttonAction: @escaping () -> Void) {
        navigationItem.leftBarButtonItem = UIBarButtonItem.backButton(buttonStyle, action: buttonAction)
    }

    func updateList(sections: [AccountDetailListSectionModel]) {
        sectionViewModels = sections
    }

    func showInfoModal(title: String, message: String) {
        presentInfoSheet(viewModel: InfoSheetViewModel(title: title, info: .markup(message)))
    }

    func presentAlert(message: String, backAction: @escaping () -> Void) {
        let alert = UIAlertController(title: L10n.AccountDetails.Error.General.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: L10n.AccountDetails.Error.General.backAction,
            style: .default,
            handler: { _ in
                backAction()
            }
        ))
        present(alert, animated: UIView.shouldAnimate)
    }

    func presentSnackBar(message: String) {
        let snackBar = SnackBarView(configuration: SnackBarConfiguration(message: message))
        snackBar.show(with: SnackBarBottomPosition(superview: tableView))
    }
}

// MARK: Tableview Delegate implementation

extension AccountDetailsListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sectionViewModels.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sectionViewModels[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: NavigationOptionTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        let currency = sectionViewModels[indexPath.section].items[indexPath.item]
        cell.configure(with: OptionViewModel(
            title: currency.title,
            subtitle: currency.info,
            leadingView: currency.image.map {
                .avatar(
                    .image(
                        $0,
                        badge: currency.hasWarning ? Icons.alert.image : nil
                    )
                )
            }
        ))

        cell.view.setLeadingAvatarViewStyle(
            .size48.with {
                $0.badge = .iconStyle(
                    tintColor: \.base.dark,
                    secondaryTintColor: \.sentiment.warning.primary
                )
            }
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.cellTapped(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerModel = sectionViewModels[section].header else { return nil }

        let header: TableSectionHeaderView = tableView.dequeueReusableHeaderFooter()
        header.configure(with: headerModel)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let header = sectionViewModels[section].header else { return 0 }

        return TableSectionHeaderView.boundingSize(
            for: header,
            style: .groupTitle,
            in: CGSize(width: tableView.bounds.width, height: .greatestFiniteMagnitude),
            context: self
        ).height
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerTitle = sectionViewModels[section].footer else { return nil }

        let footer: AccountDetailsListFooterView = tableView.dequeueReusableHeaderFooter()
        footer.configure(title: footerTitle) { [weak self] in
            self?.presenter.footerTapped()
        }
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let footer = sectionViewModels[section].footer else { return 0 }

        return LargePrimaryButtonAppearance.largePrimary.boundingSize(
            title: footer,
            targetSize: CGSize(width: tableView.bounds.width, height: .greatestFiniteMagnitude),
            context: self
        ).height + .defaultMargin * 2
    }
}

private final class AccountDetailsListFooterView: UITableViewHeaderFooterView {
    let button = LargeButtonView()

    private func setupSubviews() {
        addSubview(button)
        button.constrainToSuperview(insets: UIEdgeInsets(value: .defaultMargin))
    }

    func configure(title: String, action: @escaping Action.Handler) {
        button.configure(with: .init(title: title, handler: action))
        button.setStyle(.largeTertiary)
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }
}
