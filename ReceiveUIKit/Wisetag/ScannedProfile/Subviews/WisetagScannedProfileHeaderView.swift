import Combine
import LoggingKit
import Neptune
import TWUI

final class WisetagScannedProfileHeaderView: UIView, ComponentView {
    private lazy var headerStackView = UIStackView(
        arrangedSubviews: [
            avatarView,
            titleLabel,
            subtitleLabel,
            inlineAlertView,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.betweenText,
        alignment: .center
    )

    private let avatarView = AvatarView().with {
        $0.setStyle(.size72)
    }

    private let titleLabel = StackLabel().with {
        $0.setStyle(\.subsectionTitle)
    }

    private let subtitleLabel = StackLabel().with {
        $0.setStyle(\.defaultBody)
        $0.textAlignment = .center
    }

    private let inlineAlertView = InlineAlertView(style: .neutral)

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerStackView)
        headerStackView.constrainToSuperview(.contentArea)
    }

    private var cancellable: AnyCancellable?

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    func configure(with viewModel: WisetagScannedProfileViewModel.HeaderViewModel) {
        cancellable = viewModel.avatar.sink { [weak self] in
            self?.avatarView.configure(with: $0)
        }
        titleLabel.configure(with: viewModel.title)
        subtitleLabel.configure(with: viewModel.subtitle)
        configureAlert(with: viewModel.alert)
        layoutIfNeeded()
    }

    private func configureAlert(with alert: WisetagScannedProfileViewModel.HeaderViewModel.Alert?) {
        guard let alert else {
            headerStackView.hideArrangedSubviews([inlineAlertView])
            return
        }

        inlineAlertView.configure(with: alert.viewModel)
        inlineAlertView.setStyle(alert.style)
        headerStackView.showArrangedSubviews([inlineAlertView])
    }
}
