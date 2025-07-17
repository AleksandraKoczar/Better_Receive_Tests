import Foundation
import LoggingKit
import Neptune
import TransferResources

final class AccountDetailsReceiveOptionV2PageView: UIView {
    private enum Constants {
        static let cornerRadius: CGFloat = 16
    }

    private lazy var summariesStackView = UIStackView().with { sv in
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.backgroundColor = theme.color.background.neutral.normal
        Self.modifyCornerRadius(view: sv)
    }

    private let inlineAlert = InlineAlertView(style: .neutral)
    private lazy var infoComponent = AccountDetailsReceiveOptionInfoV2View().with {
        Self.modifyCornerRadius(view: $0)
        $0.setContentCompressionResistancePriority(
            .required,
            for: .vertical
        )
    }

    private lazy var contentStackView = UIStackView().with { sv in
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = theme.spacing.vertical.value24
    }

    // MARK: - Lifecycle

    init(viewModel: AccountDetailsReceiveOptionV2PageViewModel) {
        super.init(frame: .zero)

        setupSubviews()
        configure(viewModel: viewModel)
    }

    @available(*, unavailable)
    override init(frame: CGRect) {
        hardFailure("init(frame:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }
}

// MARK: - Configuration

private extension AccountDetailsReceiveOptionV2PageView {
    func configure(
        viewModel: AccountDetailsReceiveOptionV2PageViewModel
    ) {
        if let alert = viewModel.alert {
            inlineAlert.configure(with: alert.viewModel)
            inlineAlert.setStyle(alert.style)
            contentStackView.addArrangedSubview(inlineAlert)
        }

        if let infoViewModel = viewModel.infoViewModel {
            infoComponent.configure(with: infoViewModel)
            contentStackView.addArrangedSubview(infoComponent)
        }

        viewModel.summaries.forEach { infoModel in
            let summaryView = StackSummaryView()
            summaryView.backgroundColor = .clear
            summaryView.padding.horizontal(theme.spacing.horizontal.componentDefault)
            summaryView.configure(with: infoModel)
            summariesStackView.addArrangedSubview(summaryView)
            summaryView.setContentCompressionResistancePriority(
                .defaultLow,
                for: .vertical
            )
        }

        contentStackView.addArrangedSubview(summariesStackView)

        let nudge = StackNudgeView(
            viewModel: viewModel.nudge
        ).with {
            $0.padding.horizontal(.zero)
        }

        nudge.view.backgroundColor = theme.color.background.neutral.normal
        contentStackView.addArrangedSubview(nudge)
    }
}

// MARK: - UI Helpers

private extension AccountDetailsReceiveOptionV2PageView {
    func setupSubviews() {
        backgroundColor = theme.color.background.screen.normal
        addSubview(contentStackView)
        contentStackView.constrainToSuperview(
            insets: UIEdgeInsets(value: theme.spacing.horizontal.componentDefault)
        )

        NSLayoutConstraint.activate([
            contentStackView.widthAnchor.constraint(
                equalTo: widthAnchor,
                constant: -theme.spacing.horizontal.value32
            ),
        ])
    }

    static func modifyCornerRadius(view: UIView) {
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.masksToBounds = true
    }
}
