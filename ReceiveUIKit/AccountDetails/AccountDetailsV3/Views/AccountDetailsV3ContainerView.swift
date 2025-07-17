import LoggingKit
import Neptune
import ReceiveKit
import SwiftUI
import TransferResources
import TWUI
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsV3ViewActionDelegate: AnyObject {
    func containerTapped(content: AccountDetailsV3Information.InformationItem.DetailedSummary)
    func handleExternalAction(action: AccountDetailsExternalAction?)
    func handleCopyAction(copyText: String, feedbackText: String)
    func handleHeaderAction(_ action: AccountDetailsV3Method.DetailsHeader.AccountDetailsHeaderAction)
    func handleFeedbackAction()
    func handleAlertAction(uri: URI)
    func trackEvent(event: AccountDetailsV3AnalyticsEvent.Event)
}

final class AccountDetailsV3ContainerView: UIView {
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

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            inlineAlert,
            headerStackView,
            accountDetailsContainerView,
            keyInformationStackView,
            availabilityStackView,
            feedbackComponentView,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.value24
    ).with {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = .init(
            vertical: theme.spacing.vertical.componentDefault,
            horizontal: theme.spacing.horizontal.componentDefault
        )
    }

    private lazy var headerStackView = UIStackView(alignment: .center).with {
        $0.distribution = .fill
    }

    private lazy var keyInformationStackView = UIStackView(alignment: .center).with {
        $0.distribution = .fill
    }

    private lazy var availabilityStackView = UIStackView(alignment: .center).with {
        $0.distribution = .fill
    }

    private lazy var feedbackComponentView = FeedbackComponentView()

    private lazy var accountDetailsContainerView = AccountDetailsListItemContainerView()

    private lazy var inlineAlert = InlineAlertView()

    weak var delegate: AccountDetailsV3ViewActionDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(with viewModel: AccountDetailsV3) {
        setupAlert(model: viewModel.alert)
        setupHeader(model: viewModel.method.header)
        setupAccountDetailsContainer(
            details: viewModel.method.details,
            detailsFooter: viewModel.method.detailsFooter
        )
        setupKeyInformation(model: viewModel.information)
        setupAvailability(model: viewModel.availability)
        setupFeedback()
    }
}

private extension AccountDetailsV3ContainerView {
    func setupSubviews() {
        backgroundColor = .clear
        addSubview(stackView)
        stackView.constrainToSuperview()
    }

    func mapAlertStyle(type: AccountDetailsV3Alert.`Type`) -> InlineAlertStyle {
        switch type {
        case .warning:
            .warning
        case .neutral:
            .neutral
        case .positive:
            .positive
        case .negative:
            .negative
        }
    }

    func setupAlert(model: AccountDetailsV3Alert?) {
        let alertAction: Action? = {
            guard let alertAction = model?.action else {
                return nil
            }
            return Action(title: alertAction.title) { [weak self] in
                guard let self else { return }

                guard let uri = URI(string: alertAction.value) else { return }
                delegate?.handleAlertAction(uri: uri)
            }
        }()

        guard let model else {
            stackView.hideArrangedSubviews([inlineAlert])
            return
        }

        inlineAlert.setStyle(mapAlertStyle(type: model.type))
        inlineAlert.configure(
            with: .init(message: model.body, action: alertAction)
        )
        stackView.showArrangedSubviews([inlineAlert])
    }

    func setupAccountDetailsContainer(
        details: [AccountDetailsV3Method.AccountDetailsItem],
        detailsFooter: AccountDetailsV3Method.AccountDetailsFooter?
    ) {
        let model = AccountDetailsV3ViewModelMapper.mapAccountDetailsContainer(
            details: details,
            footer: detailsFooter,
            delegate: delegate
        )
        accountDetailsContainerView.configure(with: model)
    }

    func setupKeyInformation(model: AccountDetailsV3Information) {
        keyInformationStackView.removeAllArrangedSubviews()
        let keyInformationModel = AccountDetailsV3ViewModelMapper.mapKeyInformation(model: model, delegate: delegate)
        let keyInformationView = KeyInformationView(model: keyInformationModel)
        let controller = SwiftUIHostingController<KeyInformationView>(
            content: { keyInformationView }
        )

        keyInformationStackView.addArrangedSubviews(controller.view)
    }

    func setupAvailability(model: AccountDetailsV3Availability) {
        availabilityStackView.removeAllArrangedSubviews()
        let availabilityModel = AccountDetailsV3ViewModelMapper.mapAvailability(model: model)
        let availabilityView = AvailabilityView(model: availabilityModel)
        let controller = SwiftUIHostingController<AvailabilityView>(
            content: { availabilityView }
        )
        availabilityStackView.addArrangedSubviews(controller.view)
    }

    func setupHeader(model: AccountDetailsV3Method.DetailsHeader) {
        headerStackView.removeAllArrangedSubviews()
        let headerModel = AccountDetailsV3ViewModelMapper.mapHeader(model: model, delegate: delegate)
        let headerView = AccountDetailsHeaderView(viewModel: headerModel)
        let controller = SwiftUIHostingController<AccountDetailsHeaderView>(
            content: { headerView }
        )
        headerStackView.addArrangedSubviews(controller.view)
    }

    func setupFeedback() {
        feedbackComponentView.configure(
            with: FeedbackComponentViewModel(
                text: L10n.AccountDetailsV3.FeedbackForm.title,
                action: .init(title: L10n.AccountDetailsV3.FeedbackForm.actionTitle, handler: { [weak self] in
                    guard let self else { return }
                    delegate?.handleFeedbackAction()
                })
            )
        )
    }
}
