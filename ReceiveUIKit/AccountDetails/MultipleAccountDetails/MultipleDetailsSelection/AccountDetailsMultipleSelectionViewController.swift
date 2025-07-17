import BalanceKit
import Neptune
import TransferResources
import TWFoundation
import TWUI
import UIKit
import WiseCore

struct AccountDetailsMultipleSelectionViewModel: Equatable {
    struct Section: Equatable {
        struct Item: Equatable {
            let currencyCode: CurrencyCode
            let image: UIImage?
            let title: String
            let description: String?
        }

        let title: String
        let actionTitle: String
        let items: [Item]
    }

    let sections: [Section]
}

protocol AccountDetailsMultipleSelectionView: AnyObject {
    func configureHeader(viewModel: LargeTitleViewModel)
    func updateList(viewModel: AccountDetailsMultipleSelectionViewModel)
    func updateButtonState(enabled: Bool)
    func presentSnackBar(message: String)
    func showHud()
    func hideHud()
}

final class AccountDetailsMultipleSelectionViewController: AbstractViewController, OptsIntoAutoBackButton {
    private let keyboardDismisser = KeyboardDismisser()
    private let presenter: AccountDetailsMultipleSelectionPresenter
    private var viewModel: AccountDetailsMultipleSelectionViewModel = .init(sections: []) {
        didSet {
            MainQueueScheduler().execute {
                self.tableView.reloadData()
            }
        }
    }

    private lazy var headerView = LargeTitleView(
        scrollObserver: tableView.scrollObserver(),
        delegate: self,
        padding: LargeTitleView.topAndHorizontalPadding
    ).with { $0.searchFieldDelegate = self }

    private lazy var tableView: UITableView = {
        let t = TWTableView()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.register(cellType: CheckboxOptionTableViewCell.self)
        t.register(headerFooterType: TableSectionHeaderView.self)
        t.rowHeight = UITableView.automaticDimension
        t.sectionHeaderHeight = UITableView.automaticDimension
        t.estimatedRowHeight = NavigationOptionTableViewCell.estimatedRowHeight
        t.delegate = self
        t.dataSource = self
        t.allowsMultipleSelection = true
        t.backgroundColor = .clear
        return t
    }()

    private lazy var continueButton = FooterView(
        configuration: .extended(
            primaryView: .primary,
            secondaryView: .tertiary
        )
    ).with {
        $0.primaryViewModel = .init(
            title: L10n.AccountDetails.MultipleSelection.buttonTitle,
            isEnabled: false,
            handler: { [weak self] in
                self?.presenter.continueButtonTapped()
            }
        )

        $0.secondaryViewModel = .init(
            title: L10n.AccountDetails.MultipleSelection.secondaryButtonTitle,
            handler: { [weak self] in
                self?.presenter.secondaryActionTapped()
            }
        )
    }

    init(presenter: AccountDetailsMultipleSelectionPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardDismisser.attach(toView: view)

        setupView()
        presenter.start(withView: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        headerView.clearSearchText()
        presenter.searchQueryUpdated("")
    }

    private func setupView() {
        view.addSubview(tableView)
        view.addSubview(continueButton)
        tableView.addTableHeaderView(headerView)
        tableView.constrainToSuperview(.contentArea)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        headerView.frame.size.height = headerView.size(fittingWidth: tableView.frame.width).height
    }
}

// MARK: - AccountDetailsMultipleSelectionView

extension AccountDetailsMultipleSelectionViewController: AccountDetailsMultipleSelectionView {
    func configureHeader(viewModel: LargeTitleViewModel) {
        headerView.configure(with: viewModel)
    }

    func updateList(viewModel: AccountDetailsMultipleSelectionViewModel) {
        self.viewModel = viewModel
    }

    func updateButtonState(enabled: Bool) {
        continueButton.primaryViewModel?.isEnabled = enabled
    }

    func presentSnackBar(message: String) {
        let snackBar = SnackBarView(configuration: SnackBarConfiguration(message: message))
        snackBar.show(with: SnackBarBottomPosition(superview: view))
    }
}

// MARK: - Table view delegate & data source

extension AccountDetailsMultipleSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CheckboxOptionTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        let currency = viewModel.sections[indexPath.section].items[indexPath.item]
        cell.configure(with: .init(model: .init(
            title: currency.title,
            subtitle: currency.description,
            leadingView: currency.image.map { .avatar(.image($0)) }
        )))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currency = viewModel.sections[indexPath.section].items[indexPath.item]
        presenter.cellTapped(currencyCode: currency.currencyCode)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let currency = viewModel.sections[indexPath.section].items[indexPath.item]
        presenter.cellTapped(currencyCode: currency.currencyCode)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let currency = viewModel.sections[indexPath.section].items[indexPath.item]
        if presenter.isCurrencySelected(currency.currencyCode) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = viewModel.sections[section]

        let header: TableSectionHeaderView = tableView.dequeueReusableHeaderFooter()
        header.configure(
            with: .init(
                title: section.title,
                action: .init(
                    title: section.actionTitle,
                    handler: { [weak self] in
                        self?.sectionHeaderTapped()
                    }
                )
            )
        )
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = viewModel.sections[section]

        return TableSectionHeaderView.boundingSize(
            for: .init(
                title: section.title,
                action: .init(title: section.actionTitle, handler: {})
            ),
            style: .groupTitle,
            in: CGSize(width: tableView.bounds.width, height: .greatestFiniteMagnitude),
            context: self
        ).height
    }

    private func sectionHeaderTapped() {
        presenter.sectionHeaderTapped()
    }
}

// MARK: - UITextFieldDelegate

extension AccountDetailsMultipleSelectionViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        presenter.searchQueryUpdated(textField.text ?? "")
    }
}
