import AnalyticsKit
import ContactsKit
import DeepLinkKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: Buildable
enum PayWithWiseFlowNavigationStep {
    case info
    case singlePagePayer
    case rejected
    case success
}

// sourcery: AutoMockable
protocol PayWithWiseFlowNavigationDelegate: AnyObject {
    func startRequestMoneyFlow(profile: Profile)
    func dismissed(at: PayWithWiseFlowNavigationStep)
}

final class PayWithWiseFlow: Flow {
    // sourcery: Buildable
    enum PaymentInitializationSource {
        case paymentKey(DeepLinkPayWithWiseSource)
        case paymentRequestId(PaymentRequestId)
        case quickpay(QuickpayPayerData, ContactSearch)

        var isRequestFromContact: Bool {
            switch self {
            case let .paymentKey(deeplinkSource):
                switch deeplinkSource {
                case .request:
                    false
                case .contact:
                    true
                }
            case .paymentRequestId:
                true
            case .quickpay:
                false
            }
        }
    }

    var flowHandler: FlowHandler<Void> = .empty

    private let profile: Profile
    private let host: UINavigationController
    private let presenterFactory: ViewControllerPresenterFactory
    private let viewControllerFactory: PayWithWiseViewControllerFactory
    private let requestMoneyFlowFactory: RequestMoneyFlowFactory
    private let analyticsFlowTracker: AnalyticsFlowTrackerImpl<PayWithWiseFlowAnalytics>

    private var requestMoneyFlow: (any Flow<Void>)?

    private lazy var presenter: ViewControllerPresenter = presenterFactory.makePushPresenter(
        navigationController: host
    )

    private var dismisser: ViewControllerDismisser?

    init(
        profile: Profile,
        host: UINavigationController,
        presenterFactory: ViewControllerPresenterFactory,
        viewControllerFactory: PayWithWiseViewControllerFactory,
        requestMoneyFlowFactory: RequestMoneyFlowFactory,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self]
    ) {
        self.profile = profile
        self.host = host
        self.presenterFactory = presenterFactory
        self.viewControllerFactory = viewControllerFactory
        self.requestMoneyFlowFactory = requestMoneyFlowFactory
        analyticsFlowTracker = AnalyticsFlowTrackerImpl(
            contextIdentity: PayWithWiseFlowAnalytics.identity,
            analyticsTracker: analyticsTracker
        )

        viewControllerFactory.setFlowNavigationDelegate(self)
    }

    func start() {
        flowHandler.flowStarted()
        analyticsFlowTracker.trackFlow(
            .started,
            properties: [
                PayWithWiseFlowAnalytics.IsSinglePagePayerAnalyticsProperty(
                    isSinglePagePayer: true
                ),
            ]
        )
        showPayerPage()
    }

    func terminate() {
        analyticsFlowTracker.trackFlow(.finished)
        flowHandler.flowFinished(result: (), dismisser: dismisser)
    }
}

// MARK: - Helpers

private extension PayWithWiseFlow {
    func showPayerPage() {
        let viewController = viewControllerFactory.makeViewController(
            profile: profile,
            host: host
        )
        dismisser = presenter.present(viewController: viewController)
    }
}

extension PayWithWiseFlow: PayWithWiseFlowNavigationDelegate {
    func startRequestMoneyFlow(profile: Profile) {
        let flow = requestMoneyFlowFactory.makeFlowForPayWithWiseSuccess(
            profile: profile,
            navigationController: host
        )
        flow.onFinish { [weak self] _, dismisser in
            self?.requestMoneyFlow = nil
            self?.flowHandler.flowFinished(result: (), dismisser: dismisser)
        }
        requestMoneyFlow = flow
        flow.start()
    }

    func dismissed(at: PayWithWiseFlowNavigationStep) {
        flowHandler.flowFinished(result: (), dismisser: dismisser)
    }
}
