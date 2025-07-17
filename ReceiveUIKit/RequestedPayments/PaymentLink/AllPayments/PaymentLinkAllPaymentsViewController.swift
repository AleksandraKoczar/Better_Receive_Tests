import Differ
import LoggingKit
import Neptune
import TransferResources
import TWFoundation
import TWUI
import UIKit

// sourcery: AutoMockable
protocol PaymentLinkAllPaymentsView: AnyObject {
    func configure(with viewModel: PaymentLinkAllPaymentsViewModel)
    func showDismissableAlert(title: String, message: String)
    func showNewSections(_ newSections: [PaymentLinkAllPaymentsViewModel.Section])
    func showHud()
    func hideHud()
}

final class PaymentLinkAllPaymentsViewController: AbstractViewController {
    private var viewModel: PaymentLinkAllPaymentsViewModel?
    private let presenter: PaymentLinkAllPaymentsPresenter

    private lazy var headerView = LargeTitleView().with {
        $0.scrollObserver = tableView.scrollObserver()
        $0.delegate = self
        $0.padding = .horizontal(.defaultMargin)
    }

    private lazy var tableView = TWTableView().with {
        $0.delegate = self
        $0.dataSource = self
        $0.prefetchDataSource = self
        $0.backgroundColor = theme.color.background.screen.normal
        $0.showsVerticalScrollIndicator = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.estimatedSectionHeaderHeight = theme.spacing.vertical.value24
        $0.register(cellType: NavigationOptionTableViewCell.self)
        $0.register(headerFooterType: TableSectionHeaderView.self)
    }

    // MARK: - Life cycle

    init(presenter: PaymentLinkAllPaymentsPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }

    private func setupSubviews() {
        emptyStateView?.isHidden = true
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(tableView)
        tableView.addTableHeaderView(headerView)
        tableView.constrainToSuperview(.contentArea)
    }

    private func configureContent(with viewModel: PaymentLinkAllPaymentsViewModel) {
        emptyStateView?.isHidden = true
        tableView.isScrollEnabled = true
        tableView.reloadData()
    }
}

// MARK: - PaymentLinkAllPaymentsView

extension PaymentLinkAllPaymentsViewController: PaymentLinkAllPaymentsView {
    func configure(with viewModel: PaymentLinkAllPaymentsViewModel) {
        self.viewModel = viewModel
        headerView.configure(with: viewModel.title)
        configureContent(with: viewModel)
    }

    func showNewSections(_ newSections: [PaymentLinkAllPaymentsViewModel.Section]) {
        let oldData = viewModel?.sections ?? []
        viewModel?.append(newSections)
        guard let sections = viewModel?.sections else {
            return
        }
        if sections.count > 1 {
            tableView.animateRowAndSectionChanges(
                oldData: oldData.map { $0.items },
                newData: sections.map { $0.items },
                isEqualElement: { $0.id == $1.id },
                rowDeletionAnimation: .fade,
                rowInsertionAnimation: .fade,
                sectionDeletionAnimation: .fade,
                sectionInsertionAnimation: .fade
            )
        } else {
            tableView.animateRowChanges(
                oldData: oldData.flatMap { $0.items },
                newData: sections.flatMap { $0.items },
                isEqual: { $0.id == $1.id },
                deletionAnimation: .fade,
                insertionAnimation: .fade
            )
        }
    }
}

// MARK: - UITableViewDelegate

extension PaymentLinkAllPaymentsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = viewModel?.sections[safe: section] else {
            return tableView.estimatedSectionHeaderHeight
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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = viewModel?.sections[safe: section] else {
            return nil
        }
        let headerView: TableSectionHeaderView = tableView.dequeueReusableHeaderFooter()
        headerView.configure(with: section.viewModel)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = viewModel?.sections[safe: indexPath.section],
              let row = section.items[safe: indexPath.row] else {
            return tableView.estimatedRowHeight
        }
        let optionViewModel = OptionViewModel(
            title: row.option.title,
            subtitle: row.option.subtitle,
            avatar: .icon(Icons.fastFlag.image) // Just a placeholder for row height calculation
        )
        return NavigationOptionTableViewCell.boundingSize(
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

extension PaymentLinkAllPaymentsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel?.sections.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel?.sections[safe: section]?.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = viewModel?.sections[safe: indexPath.section],
              let row = section.items[safe: indexPath.row] else {
            softFailure("Attempt to configure table view at index path \(indexPath.description) without corresponding view model")
            return UITableViewCell()
        }
        let cell: NavigationOptionTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(with: row.option)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = viewModel?.sections[safe: indexPath.section],
              let row = section.items[safe: indexPath.row] else {
            softFailure("Attempt to select an index path \(indexPath.description) without corresponding view model")
            return
        }
        presenter.rowTapped(action: row.actionType)
    }
}

// MARK: - UITableViewDataSourcePrefetching

extension PaymentLinkAllPaymentsViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard let indexPath = indexPaths.last,
              let section = viewModel?.sections[safe: indexPath.section],
              let row = section.items[safe: indexPath.row] else {
            return
        }
        presenter.prefetch(id: row.id)
    }
}
