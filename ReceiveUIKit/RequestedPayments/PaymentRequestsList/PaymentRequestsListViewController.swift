import CombineSchedulers
import Differ
import LoggingKit
import Neptune
import TransferResources
import TWFoundation
import TWUI
import UIKit

// sourcery: AutoMockable
protocol PaymentRequestsListView: AnyObject {
    func configure(with viewModel: PaymentRequestsListViewModel)
    func showNewSections(_ newSections: [PaymentRequestsListViewModel.PaymentRequests.Section])
    func showRadioOptions(viewModel: PaymentRequestsListRadioOptionsViewModel)
    func updateRadioOptions(viewModel: PaymentRequestsListRadioOptionsViewModel)
    func dismissRadioOptions()
    func showLoading()
    func hideLoading()
    func showDismissableAlert(title: String, message: String)
}

final class PaymentRequestsListViewController: LCEViewController, OptsIntoAutoBackButton {
    private let presenter: PaymentRequestsListPresenter
    private var viewModel: PaymentRequestsListViewModel.PaymentRequests?
    private weak var bottomSheet: BottomSheet?
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var emptyViewController: TemplateLayoutViewController?

    private lazy var headerView = PaymentRequestsListHeaderView().with {
        $0.scrollObserver = tableView.scrollObserver()
        $0.delegate = self
    }

    private lazy var loadingSupplementaryView = TableLoadingSupplementaryView().with {
        $0.isHidden = true
    }

    private lazy var tableView = TWTableView().with {
        $0.delegate = self
        $0.dataSource = self
        $0.prefetchDataSource = self
        $0.backgroundColor = theme.color.background.screen.normal
        $0.showsVerticalScrollIndicator = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.register(cellType: NavigationOptionTableViewCell.self)
        $0.register(cellType: AvatarLoadableNavigationOptionTableViewCellImpl.self)
        $0.register(headerFooterType: TableSectionHeaderView.self)
    }

    // MARK: - Life cycle

    init(
        presenter: PaymentRequestsListPresenter,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.presenter = presenter
        self.scheduler = scheduler
        super.init { [weak presenter] in
            presenter?.refresh()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }

    // MARK: - Helpers

    private func setupSubviews() {
        emptyStateView?.isHidden = true
        contentScrollView = tableView // Don't use `contentView.addSubview` here
        pullToRefreshIsEnabled = true
        contentLayoutGuides = .safeContentArea
        tableView.addTableHeaderView(headerView)
    }

    private func configureContent(with viewModel: PaymentRequestsListViewModel.PaymentRequests) {
        tw_contentUnavailableConfiguration = nil

        if case let .empty(emptyViewModel) = viewModel.content {
            let emptyViewController = TemplateLayoutViewController(emptyViewModel: emptyViewModel).with {
                $0.view.backgroundColor = .clear
                $0.view.isUserInteractionEnabled = !emptyViewModel.primaryViewModel.isNil || !emptyViewModel.primaryViewModel.isNil
            }

            addEmbeddedViewController(emptyViewController)
            emptyStateView?.removeFromSuperview()
            emptyStateView = emptyViewController.view
            self.emptyViewController = emptyViewController
            tableView.isScrollEnabled = false
        } else {
            emptyViewController.map { removeEmbeddedViewController($0) }
            emptyViewController = nil
            emptyStateView = nil

            tableView.isScrollEnabled = true
        }

        tableView.reloadData()
    }

    private func configure(with viewModel: PaymentRequestsListViewModel.PaymentRequests) {
        self.viewModel = viewModel
        headerView.configure(with: viewModel.header)

        if viewModel.isCreatePaymentRequestHidden {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItems = []
            navigationItem.rightBarButtonItems = viewModel.navigationBarButtons.map { button in
                if let title = button.title {
                    let barButtonItem = UIBarButtonItem()
                    barButtonItem.customView = SmallButtonView(
                        title: title,
                        leadingIcon: button.icon,
                        handler: button.action
                    )
                    return barButtonItem
                } else {
                    let barButtonItem = UIBarButtonItem()
                    barButtonItem.customView = IconButtonView(
                        icon: button.icon,
                        discoverabilityTitle: button.icon.description,
                        style: .iconSecondaryNeutral(size: .size32),
                        handler: button.action
                    )
                    return barButtonItem
                }
            }
        }

        configureContent(with: viewModel)
    }

    private func configure(with emptyState: PaymentRequestsListViewModel.EmptyState) {
        navigationItem.rightBarButtonItem = nil
        tw_contentUnavailableConfiguration = .template(
            FooterTemplateLayoutViewConfiguration(
                asset: .illustration(emptyState.illustration),
                title: emptyState.title,
                additionalContent: emptyState.summaries.map {
                    .summary($0)
                },
                footer: .extended(secondaryView: .tertiary)
            ),
            primaryViewModel: emptyState.primaryButton,
            secondaryViewModel: emptyState.secondaryButton
        )
    }
}

// MARK: - CustomDismissActionProvider

extension PaymentRequestsListViewController: CustomDismissActionProvider {
    func provideCustomDismissAction(ofType type: DismissActionType) -> (() -> Void)? {
        presenter.dismiss
    }
}

// MARK: - PaymentRequestsListView

extension PaymentRequestsListViewController: PaymentRequestsListView {
    func configure(with viewModel: PaymentRequestsListViewModel) {
        switch viewModel {
        case let .emptyState(emptyState):
            configure(with: emptyState)
        case let .paymentRequests(paymentRequests):
            configure(with: paymentRequests)
        }
    }

    func showNewSections(_ newSections: [PaymentRequestsListViewModel.PaymentRequests.Section]) {
        let oldData = viewModel?.sections ?? []
        viewModel?.append(newSections)
        guard let sections = viewModel?.sections else {
            return
        }
        if sections.count > 1 {
            tableView.animateRowAndSectionChanges(
                oldData: oldData.map { $0.rows },
                newData: sections.map { $0.rows },
                isEqualElement: { $0.id == $1.id },
                rowDeletionAnimation: .fade,
                rowInsertionAnimation: .fade,
                sectionDeletionAnimation: .fade,
                sectionInsertionAnimation: .fade
            )
        } else {
            tableView.animateRowChanges(
                oldData: oldData.flatMap { $0.rows },
                newData: sections.flatMap { $0.rows },
                isEqual: { $0.id == $1.id },
                deletionAnimation: .fade,
                insertionAnimation: .fade
            )
        }
    }

    func showRadioOptions(viewModel: PaymentRequestsListRadioOptionsViewModel) {
        var primaryAction: LargeButtonView.ViewModel?
        var secondaryAction: LargeButtonView.ViewModel?
        let action = LargeButtonView.ViewModel(
            title: viewModel.action.title,
            handler: viewModel.action.handler
        )
        if viewModel.action.style is LargePrimaryButtonAppearance {
            primaryAction = action
        } else {
            secondaryAction = action
        }
        bottomSheet = presentRadioOptionsSheet(
            title: viewModel.title,
            items: viewModel.options,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            footer: .extended(
                secondaryView: viewModel.action.style is LargeTertiaryButtonAppearance
                    ? .tertiary
                    : .secondaryNeutral
            ),
            handler: viewModel.handler,
            dismissOnSelection: viewModel.dismissOnSelection
        )
    }

    func updateRadioOptions(viewModel: PaymentRequestsListRadioOptionsViewModel) {
        let newContent = BottomSheetViewController.makeRadioOptionSheet(
            title: viewModel.title,
            items: viewModel.options,
            primaryAction: .init(
                title: viewModel.action.title,
                handler: viewModel.action.handler
            ),
            dismissOnSelection: viewModel.dismissOnSelection,
            handler: viewModel.handler
        )
        bottomSheet?.updateContent(newContent, animated: false)
    }

    func dismissRadioOptions() {
        bottomSheet?.dismiss(animated: true)
    }

    func showLoading() {
        loadingSupplementaryView.isHidden = false
    }

    func hideLoading() {
        loadingSupplementaryView.isHidden = true
        loadingStopped(hasContent: true, hasError: false)
    }
}

// MARK: - UITableViewDelegate

extension PaymentRequestsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = viewModel?.sections[safe: indexPath.section],
              let row = section.rows[safe: indexPath.row] else {
            softFailure("Attempt to select an index path \(indexPath.description) without corresponding view model")
            return
        }
        presenter.rowTapped(id: row.id)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = viewModel?.sections[safe: section],
              !section.isSectionHeaderHidden else {
            return theme.spacing.vertical.value24
        }
        return TableSectionHeaderView.boundingSize(
            for: section.viewModel,
            style: .groupTitle,
            in: CGSize(
                width: tableView.bounds.size.width,
                height: .greatestFiniteMagnitude
            ),
            context: self
        ).height
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let isLastSection = section == tableView.numberOfSections - 1
        guard isLastSection else {
            return .zero
        }
        return TableLoadingSupplementaryView.boundingSize(
            in: CGSize(
                width: tableView.bounds.width,
                height: .greatestFiniteMagnitude
            ),
            context: self
        ).height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = viewModel?.sections[safe: section],
              !section.isSectionHeaderHidden else {
            return nil
        }
        let headerView: TableSectionHeaderView = tableView.dequeueReusableHeaderFooter()
        headerView.configure(with: section.viewModel)
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let isLastSection = section == tableView.numberOfSections - 1
        guard isLastSection else {
            return nil
        }
        return loadingSupplementaryView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = viewModel?.sections[safe: indexPath.section],
              let row = section.rows[safe: indexPath.row] else {
            return tableView.estimatedRowHeight
        }
        let optionViewModel = OptionViewModel(
            title: row.title,
            subtitle: row.subtitle,
            avatar: .icon(Icons.fastFlag.image) // Just a placeholder for row height calculation
        )
        return AvatarLoadableNavigationOptionTableViewCellImpl.boundingSize(
            for: optionViewModel,
            in: CGSize(
                width: tableView.bounds.size.width,
                height: .greatestFiniteMagnitude
            ),
            context: self
        ).height
    }
}

// MARK: - UITableViewDataSource

extension PaymentRequestsListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel?.sections.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel?.sections[safe: section]?.rows.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = viewModel?.sections[safe: indexPath.section],
              let row = section.rows[safe: indexPath.row] else {
            softFailure("Attempt to configure table view at index path \(indexPath.description) without corresponding view model")
            return UITableViewCell()
        }
        let cell: AvatarLoadableNavigationOptionTableViewCellImpl = tableView.dequeueReusableCell(for: indexPath)
        if cell.presenter == nil {
            cell.presenter = AvatarLoadableNavigationOptionTableViewCellPresenterImpl(
                avatarFetcher: CancellableAvatarFetcherImpl(
                    scheduler: scheduler
                )
            )
        }
        cell.setLeadingAvatarViewStyle(row.avatarStyle)
        cell.presenter?.start(title: row.title, subtitle: row.subtitle, avatarPublisher: row.avatarPublisher, cell: cell)
        return cell
    }
}

// MARK: - UITableViewDataSourcePrefetching

extension PaymentRequestsListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard let indexPath = indexPaths.last,
              let section = viewModel?.sections[safe: indexPath.section],
              let row = section.rows[safe: indexPath.row] else {
            return
        }
        presenter.prefetch(id: row.id)
    }
}
