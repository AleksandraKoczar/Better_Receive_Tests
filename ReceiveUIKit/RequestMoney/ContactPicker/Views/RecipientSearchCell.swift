import Foundation
import LoggingKit
import Neptune
import TransferResources
import UIKit

/// A glorified Button to trigger Contacts Search.
final class RecipientSearchCell: UITableViewCell {
    private let searchInput: SearchInputView = {
        let view = SearchInputView()
        /// Neptune is not handling this gracefully. If set to `nil` placeholder will be used to label search input.
        /// By using "" we avoid search input being labeled.
        view.label = ""
        view.text = nil
        view.placeholder = L10n.Contacts.Search.Input.placeholder
        return view
    }()

    // MARK: - Init

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(
            style: style,
            reuseIdentifier: reuseIdentifier
        )
        /// We need to know when `SearchTextField` becomes active to show another VC.
        searchInput.addTarget(
            target: self,
            action: #selector(onSearchInputTap),
            for: .editingDidBegin
        )
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    // MARK: - Public interface

    /// This cell is purely cosmetic - another VC will be shown immediately after Cst has tapped this cell.
    /// But as the cell contains a `UITextField` subclass using regular `UITableView.didSelectRowAt` won't work.
    /// Hence we need a custom `onTap` closure to call.
    var onTap: (() -> Void)?

    override func setHighlighted(
        _ highlighted: Bool,
        animated: Bool
    ) {
        // Should not be highlighted
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        searchInput.prepareForReuse()
        searchInput.isActive = false
        onTap = nil
        super.isHighlighted = false
    }

    // MARK: - Private

    private func setupSubviews() {
        selectionStyle = .none
        backgroundColor = theme.color.background.screen.normal
        contentView.addSubview(searchInput)
        NSLayoutConstraint.activate([
            searchInput.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .defaultMargin),
            searchInput.topAnchor.constraint(equalTo: contentView.topAnchor),
            searchInput.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.defaultMargin),
            searchInput.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.defaultMargin),
        ])
    }

    @objc
    private func onSearchInputTap(
        searchInput: UITextField
    ) {
        searchInput.resignFirstResponder()
        onTap?()
    }
}
