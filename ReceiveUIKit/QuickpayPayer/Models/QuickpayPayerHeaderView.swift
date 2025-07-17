import Combine
import LoggingKit
import Neptune
import TWUI

final class QuickpayPayerHeaderView: UIView, ComponentView {
    private var cancellable: AnyCancellable?

    private lazy var headerStackView = UIStackView(
        arrangedSubviews: [
            avatarView,
            titleLabel,
            subtitleLabel,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.betweenText,
        alignment: .leading
    ).with {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(left: theme.spacing.vertical.value8)
    }

    private let avatarView = AvatarView().with {
        $0.setStyle(.size56)
    }

    private let titleLabel = StackLabel().with {
        $0.setStyle(\.screenTitle)
    }

    private let subtitleLabel = StackLabel().with {
        $0.setStyle(\.largeBody)
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerStackView)
        headerStackView.constrainToSuperview(.contentArea)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    func configure(with viewModel: QuickpayPayerViewModel) {
        cancellable = viewModel.avatar.sink { [weak self] in
            self?.avatarView.configure(with: $0)
        }
        titleLabel.configure(with: viewModel.businessName)
        subtitleLabel.configure(with: viewModel.subtitle)
        layoutIfNeeded()
    }
}
