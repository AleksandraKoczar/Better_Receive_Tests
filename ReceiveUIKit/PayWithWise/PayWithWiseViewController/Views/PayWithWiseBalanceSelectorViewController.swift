import LoggingKit
import Neptune

final class PayWithWiseBalanceSelectorViewController: UIViewController {
    private lazy var headerView = LargeTitleView(
        scrollObserver: tableView.scrollObserver(),
        delegate: self,
        padding: LargeTitleView.padding.horizontal
    )

    private lazy var tableView = UITableView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.showsVerticalScrollIndicator = false
        $0.dataSource = self
        $0.delegate = self
        $0.estimatedRowHeight = NavigationOptionTableViewCell.estimatedRowHeight
        $0.register(cellType: NavigationOptionTableViewCell.self)
        $0.register(headerFooterType: TableSectionHeaderView.self)
    }

    private let viewModel: PayWithWiseBalanceSelectorViewModel

    // MARK: - Lifecycle

    init(viewModel: PayWithWiseBalanceSelectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        updateAppearance()
    }

    func setupView() {
        view.addSubview(tableView)
        tableView.addTableHeaderView(headerView)
        tableView.constrainToSuperview(.contentArea)

        headerView.configure(title: viewModel.title)
    }
}

// MARK: - UITableViewDataSource

extension PayWithWiseBalanceSelectorViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        viewModel.sections[section].options.count
    }

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        let header: TableSectionHeaderView = tableView.dequeueReusableHeaderFooter()
        header.configure(
            with: viewModel.sections[section].headerViewModel
        )
        return header
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        TableSectionHeaderView.boundingSize(
            for: viewModel.sections[section].headerViewModel,
            style: .groupTitle,
            in: CGSize(
                width: tableView.bounds.width,
                height: .greatestFiniteMagnitude
            ),
            context: self
        ).height
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            for: indexPath,
            cellType: NavigationOptionTableViewCell.self
        )
        cell.configure(
            with: viewModel
                .sections[indexPath.section]
                .options[indexPath.row]
        )
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PayWithWiseBalanceSelectorViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        viewModel.selectAction(indexPath)
    }
}

// MARK: - Helpers

private extension PayWithWiseBalanceSelectorViewController {
    func updateAppearance() {
        view.backgroundColor = theme.color.background.screen.normal
    }
}
