import Combine
import CombineSchedulers
import ContactsKit
import LoggingKit
import Neptune
import ReceiveKit
import SwiftUI
import TWFoundation
import TWUI
import UIKit

// sourcery: AutoMockable
protocol RequestMoneyContactPickerView: AnyObject {
    func configure(viewModel: RequestMoneyContactPickerViewModel)
    func reset()
    func showLoading()
    func hideLoading()
    func showErrorAlert(title: String, message: String)
}

final class RequestMoneyContactPickerViewController: AbstractViewController, OptsIntoAutoBackButton {
    private enum Constants {
        static let recentContactsCell = "recentContactsCell"
    }

    private(set) lazy var tableView: TWTableView = {
        let t = TWTableView()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.accessibilityIdentifier = "Contacts list"
        t.estimatedRowHeight = NavigationOptionTableViewCell.estimatedRowHeight
        t.register(cellType: ContainerTableViewCell<EmptyContentView>.self)
        t.register(cellType: NavigationOptionTableViewCell.self)
        t.register(cellType: AvatarLoadableNavigationOptionTableViewCellImpl.self)
        t.register(cellType: RecipientSearchCell.self)
        t.register(cellType: OptionTableViewCell.self)
        t.register(cellType: NudgeTableViewCell.self)
        t.register(
            RecentContactHostingTableViewCell<AnyView>.self,
            forCellReuseIdentifier: Constants.recentContactsCell
        )
        t.register(headerFooterType: TableSectionHeaderView.self)
        t.register(cellType: UITableViewCell.self)
        t.delegate = self
        t.dataSource = self
        t.prefetchDataSource = self
        return t
    }()

    private lazy var titleView: LargeTitleView = {
        let titleView = LargeTitleView(
            scrollObserver: tableView.scrollObserver(),
            padding: UIEdgeInsets(
                top: 0,
                left: theme.spacing.horizontal.componentDefault,
                bottom: theme.spacing.vertical.componentDefault,
                right: theme.spacing.horizontal.componentDefault
            )
        )
        titleView.delegate = self
        return titleView
    }()

    private lazy var loadingSupplementaryView = TableLoadingSupplementaryView().with {
        $0.isHidden = true
    }

    private let presenter: RequestMoneyContactPickerPresenter
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var viewModel: RequestMoneyContactPickerViewModel?

    init(
        presenter: RequestMoneyContactPickerPresenter,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.presenter = presenter
        self.scheduler = scheduler
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.start(with: self)
    }
}

// MARK: - RequestMoneyContactPickerView

extension RequestMoneyContactPickerViewController: RequestMoneyContactPickerView {
    func configure(viewModel: RequestMoneyContactPickerViewModel) {
        titleView.configure(with: viewModel.titleViewModel)

        let contactSectionIndex = Self.findContactSectionIndex(for: viewModel) ?? 0
        let previousVMLastSectionCellCount = Self.lastSectionCellCount(
            for: self.viewModel
        )
        let startIndex = previousVMLastSectionCellCount
        let endIndex = Self.lastSectionCellCount(for: viewModel)
        let indexPaths = (startIndex..<endIndex).map {
            IndexPath(row: $0, section: contactSectionIndex)
        }
        // If previously it is just default option then reload
        if previousVMLastSectionCellCount <= 1
            || indexPaths.isEmpty {
            self.viewModel = viewModel
            tableView.reloadData()
        } else {
            self.viewModel = viewModel
            tableView.insertRows(at: indexPaths, with: .fade)
        }
    }

    func reset() {
        viewModel = nil
    }

    func showLoading() {
        loadingSupplementaryView.isHidden = false
    }

    func hideLoading() {
        loadingSupplementaryView.isHidden = true
    }
}

// MARK: - UITableViewDataSourcePrefetching

extension RequestMoneyContactPickerViewController: UITableViewDataSourcePrefetching {
    func tableView(
        _ tableView: UITableView,
        prefetchRowsAt indexPaths: [IndexPath]
    ) {
        let maxIndex = indexPaths
            .lazy
            .map { $0.row }
            .max() ?? 0

        if maxIndex > max(0, Self.lastSectionCellCount(for: viewModel) - 4) {
            presenter.loadMore()
        }
    }
}

// MARK: - UITableViewDelegate

extension RequestMoneyContactPickerViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        guard let section = viewModel?.sections[safe: indexPath.section], let row = section.cells[safe: indexPath.row] else {
            softFailure("[REC] Attempt to select an index path \(indexPath.description) without corresponding view model")
            return tableView.estimatedRowHeight
        }
        return getRowHeight(row: row)
    }

    func getRowHeight(row: RequestMoneyContactPickerViewModel.Cell) -> CGFloat {
        switch row {
        case .recentContacts:
            return UITableView.automaticDimension
        case let .nudge(nudge):
            return NudgeView.boundingSize(
                for: nudge,
                in: CGSize(
                    width: tableView.bounds.size.width,
                    height: .greatestFiniteMagnitude
                ),
                context: self
            ).height
        case .spacingBetweenNudgeAndOption:
            return theme.spacing.vertical.dividerToOption
        case let .contact(contact):
            let optionViewModel = OptionViewModel(
                title: contact.title,
                subtitle: contact.subtitle,
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
        case let .optionItem(viewModel):
            let optionViewModel = OptionViewModel(
                title: viewModel.title,
                subtitle: viewModel.subtitle,
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
        case let .noContacts(viewModel):
            let optionViewModel = OptionViewModel(
                title: viewModel.title,
                subtitle: viewModel.subtitle,
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
        case .search:
            return tableView.estimatedRowHeight
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = viewModel?.sections[safe: indexPath.section], let row = section.cells[safe: indexPath.row] else {
            softFailure("[REC] Attempt to select an index path \(indexPath.description) without corresponding view model")
            return
        }
        switch row {
        case let .contact(contact):
            presenter.select(contact: contact)
        case .optionItem:
            presenter.select(contact: nil)
        case .search,
             .noContacts,
             .recentContacts,
             .nudge,
             .spacingBetweenNudgeAndOption:
            break
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = viewModel?.sections[safe: section],
              !section.isSectionHeaderHidden,
              let viewModel = section.viewModel else {
            return nil
        }
        let headerView: TableSectionHeaderView = tableView.dequeueReusableHeaderFooter()
        headerView.configure(with: viewModel)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = viewModel?.sections[safe: section],
              !section.isSectionHeaderHidden,
              let model = section.viewModel else {
            return 0
        }
        return TableSectionHeaderView.boundingSize(
            for: model,
            style: .groupTitle,
            in: CGSize(
                width: tableView.bounds.size.width,
                height: .greatestFiniteMagnitude
            ),
            context: self
        ).height
    }
}

// MARK: - UITableViewDataSource

extension RequestMoneyContactPickerViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        viewModel?.sections[safe: section]?.cells.count ?? 0
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel?.sections.count ?? 0
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let section = viewModel?.sections[safe: indexPath.section],
              let row = section.cells[safe: indexPath.row] else {
            softFailure("[REC] Attempt to configure table view at index path \(indexPath.description) without corresponding view model")
            return UITableViewCell()
        }

        switch row {
        case let .noContacts(viewModel):
            let cell: OptionTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(with: viewModel)
            return cell
        case let .contact(contact):
            let cell: AvatarLoadableNavigationOptionTableViewCellImpl = tableView.dequeueReusableCell(for: indexPath)
            if cell.presenter == nil {
                cell.presenter = AvatarLoadableNavigationOptionTableViewCellPresenterImpl(
                    avatarFetcher: CancellableAvatarFetcherImpl(
                        scheduler: scheduler
                    )
                )
            }
            cell.presenter?.start(
                title: contact.title,
                subtitle: contact.subtitle,
                avatarPublisher: contact.avatarPublisher,
                cell: cell
            )
            return cell
        case let .recentContacts(contacts):
            let recentContacts = contacts.map(ContactPickerRecentContact.init(contact:))

            let recentContactView = ContactPickerRecentContactsHorizontalSectionView(
                models: recentContacts,
                onTapped: { [weak self] contact in
                    guard let self else { return }
                    presenter.select(contact: contact.contact)
                }
            )

            let paddedContactView = AnyView(recentContactView.preferredPadding())
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.recentContactsCell) as! RecentContactHostingTableViewCell<AnyView>
            cell.backgroundColor = theme.color.background.screen.normal
            cell.host(rootView: paddedContactView, parentController: self)
            return cell
        case let .optionItem(viewModel):
            let cell: NavigationOptionTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(with: viewModel)
            return cell
        case .search:
            let cell: RecipientSearchCell = tableView.dequeueReusableCell(for: indexPath)
            cell.onTap = { [weak self] in
                self?.presenter.startSearch()

                /// This is a (nasty) shortcut to completely reset Search Input
                /// Search Input here is only used as glorified button to show Contacts Search
                /// Copied from ContactsUIKit
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.1,
                    execute: {
                        tableView.reloadData()
                    }
                )
            }
            return cell
        case let .nudge(viewModel):
            let cell: NudgeTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(with: viewModel)
            return cell
        case .spacingBetweenNudgeAndOption:
            let cell: ContainerTableViewCell<EmptyContentView> = tableView.dequeueReusableCell(for: indexPath)
            cell.setSeparatorHidden(true)
            cell.selectionStyle = .none
            return cell
        }
    }
}

// MARK: - HasPreDismissAction

extension RequestMoneyContactPickerViewController: HasPreDismissAction {
    func performPreDismissAction(ofType type: DismissActionType) {
        if type == .modalDismissal {
            presenter.dismiss()
        }
    }
}

// MARK: - Helpers

private extension RequestMoneyContactPickerViewController {
    func setupView() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(tableView)
        tableView.addTableHeaderView(titleView)
        tableView.constrainToSuperview(.contentArea)
    }

    static func lastSectionCellCount(
        for viewModel: RequestMoneyContactPickerViewModel?
    ) -> Int {
        guard let viewModel,
              let sectionIndex = findContactSectionIndex(for: viewModel) else {
            return 0
        }
        return viewModel.sections[sectionIndex].cells.count
    }

    static func findContactSectionIndex(
        for viewModel: RequestMoneyContactPickerViewModel
    ) -> Int? {
        guard let sectionIndex = viewModel.sections.firstIndex(
            where: {
                $0.cells.contains(
                    where: {
                        guard case .contact = $0 else {
                            return false
                        }
                        return true
                    }
                )
            }
        ) else {
            return nil
        }
        return sectionIndex
    }
}
