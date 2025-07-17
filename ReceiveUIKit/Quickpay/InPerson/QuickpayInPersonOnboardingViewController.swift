import Foundation
import Neptune
import ReceiveKit
import TransferResources
import TWUI
import UIKit

final class QuickpayInPersonOnboardingViewController: AbstractViewController, OptsIntoAutoBackButton {
    private lazy var scrollView = UIScrollView(contentView: stackView)

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            topStackView,
            bottomStackView,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.value32
    )

    private let imageView = UIImageView(image: ReceiveKitImages.quickpayQrCode)

    private let titleLabel = StackLabel().with {
        $0.setStyle(\.display)
        $0.textAlignment = .center
    }

    private let topStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    private let bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing * 0.5
        return stackView
    }()

    private let summaries = [
        SummaryViewModel(
            title: L10n.Quickpay.InPersonOnboarding.FirstSummary.title,
            description: L10n.Quickpay.InPersonOnboarding.FirstSummary.subtitle,
            icon: Icons.scanQrCode.image
        ),
        SummaryViewModel(
            title: L10n.Quickpay.InPersonOnboarding.SecondSummary.title,
            description: L10n.Quickpay.InPersonOnboarding.SecondSummary.subtitle,
            icon: Icons.money.image
        ),
        SummaryViewModel(
            title: L10n.Quickpay.InPersonOnboarding.ThirdSummary.title,
            description: L10n.Quickpay.InPersonOnboarding.SecondSummary.subtitle,
            icon: Icons.lightningBolt.image
        ),
    ]

    private let footerView = FooterView()
    private let footerAction: Action

    // MARK: - Initialization

    init(primaryAction: @escaping () -> Void) {
        footerAction = Action(
            title: L10n.Quickpay.InPersonOnboarding.Continue.title,
            handler: primaryAction
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    private func configureViews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.contentArea)
        view.addSubview(footerView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 220).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 220).isActive = true
        topStackView.addArrangedSubview(imageView)
        topStackView.addArrangedSubview(titleLabel)

        summaries.forEach { summary in
            let summaryView = StackSummaryView()
            summaryView.configure(with: summary)
            bottomStackView.addArrangedSubview(summaryView)
        }
        titleLabel.configure(with: L10n.Quickpay.InPersonOnboarding.title)
        footerView.primaryViewModel = .init(title: footerAction.title, handler: footerAction.handler)
    }
}
