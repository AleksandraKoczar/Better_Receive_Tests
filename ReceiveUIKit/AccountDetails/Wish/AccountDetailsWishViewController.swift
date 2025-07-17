import BalanceKit
import Foundation
import Neptune
import TransferResources
import TWUI
import UIKit

protocol AccountDetailsWishView: AnyObject {
    func configure(options: [OptionViewModel])
    func showHud()
    func hideHud()
    func showRetryAlert(withTitle title: String, message: String, action: @escaping () -> Void, cancelAction: (() -> Void)?)
    func dismiss()
}

final class AccountDetailsWishViewController: AbstractViewController, OptsIntoAutoBackButton {
    private var options: [OptionViewModel] = []
    private let presenter: AccountDetailsWishListPresenter

    private lazy var headerView = LargeTitleView(
        scrollObserver: tableView.scrollObserver(),
        delegate: self,
        padding: LargeTitleView.topAndHorizontalPadding
    ).with {
        $0.searchFieldDelegate = self
        $0.configure(
            with: .init(
                title: L10n.AccountDetails.List.Request.title,
                shortTitle: L10n.AccountDetails.List.Request.shortTitle,
                description: L10n.AccountDetails.List.Request.subtitle,
                searchFieldPlaceholder: L10n.AccountDetails.List.Request.search
            )
        )
    }

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)
        .with {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.preservesSuperviewLayoutMargins = true
            $0.backgroundColor = theme.color.background.screen.normal
            $0.separatorStyle = .none
            $0.register(cellType: OptionTableViewCell.self)
            $0.keyboardDismissMode = .onDrag
            $0.delegate = self
            $0.dataSource = self
            $0.contentInsetAdjustmentBehavior = .never
            $0.rowHeight = UITableView.automaticDimension
            $0.sectionHeaderHeight = UITableView.automaticDimension
            $0.sectionFooterHeight = UITableView.automaticDimension
        }

    init(presenter: AccountDetailsWishListPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.start(with: self)
    }

    private func setupView() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(tableView)
        tableView.constrainToSuperview(.safeArea)
        tableView.addTableHeaderView(headerView)
    }
}

extension AccountDetailsWishViewController: AccountDetailsWishView {
    func configure(options: [OptionViewModel]) {
        self.options = options
        tableView.reloadData()
    }

    func dismiss() {
        navigationController?.popViewController(animated: UIView.shouldAnimate)
    }
}

extension AccountDetailsWishViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OptionTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(with: options[indexPath.item])
        return cell
    }
}

extension AccountDetailsWishViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
        presenter.toggleSelection(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: UIView.shouldAnimate)
    }
}

// MARK: - UITextFieldDelegate

extension AccountDetailsWishViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        presenter.updateSearchQuery(textField.text ?? "")
    }
}
