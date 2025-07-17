import BalanceKit
import LoggingKit
import Neptune
import TransferResources
import UIKit

final class AccountDetailsReceiveOptionInfoV2View: UIView {
    private enum Constants {
        static let cornerRadius: CGFloat = 10
        static let rowValueStyle = LabelStyle.largeBody.with {
            $0.semanticColor = \.content.primary
            $0.paragraphSpacing = 0
        }

        static let obfuscatedRowValueStyle = { (_: SemanticContext) in
            Constants.rowValueStyle.with {
                $0.semanticFont = \.screenTitle
                $0.maximumLineHeight = 32
            }
        }
    }

    private lazy var stackView = UIStackView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.alignment = .fill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = Constants.cornerRadius
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = NSDirectionalEdgeInsets(
            value: theme.spacing.horizontal.componentDefault
        )
        $0.spacing = theme.spacing.vertical.componentDefault
    }

    // MARK: - Lifecycle

    init() {
        super.init(frame: .zero)
        setupSubviews()
        updateAppearance()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
    }
}

// MARK: - Interface

extension AccountDetailsReceiveOptionInfoV2View {
    func configure(with model: AccountDetailsReceiveOptionInfoV2ViewModel) {
        stackView.removeAllArrangedSubviews()

        let headerView = AccountDetailsInfoHeaderV2View()
        headerView.configure(viewModel: model.header)
        stackView.addArrangedSubview(headerView)

        let rows = model.rows.map { rowModel in
            makeRow(with: rowModel)
        }
        stackView.addArrangedSubviews(rows)
    }
}

// MARK: - Helpers

private extension AccountDetailsReceiveOptionInfoV2View {
    func makeRow(with viewModel: AccountDetailsInfoRowV2ViewModel) -> UIView {
        makeAccountDetailsListItemView(
            viewModel: viewModel
        )
    }

    func makeAccountDetailsListItemView(
        viewModel: AccountDetailsInfoRowV2ViewModel
    ) -> UIView {
        let view = StackAccountDetailsListItemView()
        view.setStyle(
            AccountDetailsListItemViewStyle(
                value: valueLabelStyle(
                    for: viewModel
                )
            )
        )

        view.configure(
            with: AccountDetailsListItemViewModel(
                title: viewModel.title,
                subtitle: subtitle(for: viewModel),
                action: viewModel.action,
                tooltip: viewModel.tooltip
            )
        )
        view.padding = .zero
        return view
    }

    func valueLabelStyle(
        for viewModel: AccountDetailsInfoRowV2ViewModel
    ) -> LabelStyle {
        viewModel.isObfuscated
            ? Constants.obfuscatedRowValueStyle(self)
            : Constants.rowValueStyle
    }

    func subtitle(
        for viewModel: AccountDetailsInfoRowV2ViewModel
    ) -> String {
        viewModel.isObfuscated
            // use fixed number of characters to avoid truncating text
            ? String(repeating: "·", count: 10)
            : viewModel.information
    }

    func setupSubviews() {
        addSubview(stackView)
        stackView.constrainToSuperview()
    }

    func updateAppearance() {
        backgroundColor = theme.color.background.neutral.normal
    }
}
