import Neptune
import TWUI

final class SalarySwitchOptionSelectionViewController: AbstractViewController, CanHaveCustomModalDismissAction, OptsIntoAutoBackButton {
    private lazy var tableView: UITableView = {
        let t = UITableView()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.register(cellType: NavigationOptionTableViewCell.self)
        t.register(headerFooterType: TableSectionHeaderView.self)
        t.rowHeight = UITableView.automaticDimension
        t.estimatedRowHeight = UITableView.automaticDimension
        t.estimatedSectionHeaderHeight = TableSectionHeaderView.estimatedHeight
        t.sectionHeaderHeight = UITableView.automaticDimension
        t.backgroundColor = .clear
        t.delegate = self
        t.dataSource = self
        t.separatorStyle = .none
        return t
    }()

    private lazy var headerView = LargeTitleView(
        scrollObserver: tableView.scrollObserver(),
        delegate: self,
        padding: LargeTitleView.padding.horizontal
    )

    private let presenter: SalarySwitchOptionSelectionPresenter
    private var sections: [SalarySwitchOptionSelectionViewModel.Section] = []

    var modalDismissAction: (() -> Void)?

    // MARK: - Lifecycle

    init(presenter: SalarySwitchOptionSelectionPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.start(view: self)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension SalarySwitchOptionSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].options.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let model = SectionHeaderViewModel(title: sections[section].title)
        let view: TableSectionHeaderView = tableView.dequeueReusableHeaderFooter()
        view.configure(with: model)
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let model = SectionHeaderViewModel(title: sections[section].title)
        return TableSectionHeaderView.boundingSize(
            for: model,
            style: .groupTitle,
            in: CGSize(width: tableView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude),
            context: self
        ).height
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let item = section.options[indexPath.row]
        let cell: NavigationOptionTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(with: item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        presenter.selectedOption(at: indexPath.row, sender: cell)
    }
}

extension SalarySwitchOptionSelectionViewController: SalarySwitchOptionSelectionView {
    var documentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate {
        self
    }

    func configure(viewModel: SalarySwitchOptionSelectionViewModel) {
        headerView.removeFromSuperview()
        headerView.configure(with: viewModel.titleViewModel)
        tableView.addTableHeaderView(headerView)
        sections = viewModel.sections
        tableView.reloadData()
    }
}

extension SalarySwitchOptionSelectionViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(
        _ controller: UIDocumentInteractionController
    ) -> UIViewController {
        self
    }
}

// MARK: - Helpers

private extension SalarySwitchOptionSelectionViewController {
    func setupView() {
        view.addSubview(tableView)
        tableView.constrainToSuperview(.contentArea)
    }
}
