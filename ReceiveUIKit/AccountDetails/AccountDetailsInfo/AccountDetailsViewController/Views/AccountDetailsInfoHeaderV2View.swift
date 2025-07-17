import LoggingKit
import Neptune
import TransferResources
import UIKit

final class AccountDetailsInfoHeaderV2View: UIView {
    private lazy var containerStackView = UIStackView(
        arrangedSubviews: [
            avatarView,
            label,
            actionButton,
        ],
        axis: .horizontal,
        spacing: theme.spacing.horizontal.betweenChips,
        alignment: .center
    )

    private let avatarView = AvatarView().with {
        $0.setStyle(.size24)
    }

    private let label = Label().with {
        $0.numberOfLines = 0
        $0.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        $0.setStyle(
            LabelStyle.defaultBodyBold.with {
                $0.semanticColor = \.content.primary
            }
        )
    }

    private let actionButton = SmallButtonView().with {
        $0.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }
}

// MARK: - Interface

extension AccountDetailsInfoHeaderV2View {
    func configure(viewModel: AccountDetailsInfoHeaderV2ViewModel) {
        avatarView.configure(
            with: .image(
                viewModel.avatarImageCreator(self)
            )
        )
        avatarView.accessibilityLabel = L10n.AccountDetails.Info.Details.Header.CurrencyFlag.accessibilityLabel
        avatarView.accessibilityValue = viewModel.avatarAccessibilityValue
        label.configure(with: viewModel.title)
        viewModel.shareButton.map { buttonModel in
            actionButton.configure(
                with: SmallButton.ViewModel(
                    title: buttonModel.title,
                    handler: { [unowned self] in
                        buttonModel.action(self)
                    }
                )
            )
        }
    }
}

// MARK: - Helpers

private extension AccountDetailsInfoHeaderV2View {
    func setupView() {
        addSubview(containerStackView)
        containerStackView.constrainToSuperview()
    }
}
