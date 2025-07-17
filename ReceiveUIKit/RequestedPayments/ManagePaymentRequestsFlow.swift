import AnalyticsKit
import ReceiveKit
import TWFoundation
import TWUI
import UserKit

final class ManagePaymentRequestsFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private let shouldSupportInvoiceOnly: Bool
    private let shouldShowMostRecentlyRequestedIfApplicable: Bool
    private let profile: Profile
    private let navigationController: UINavigationController
    private let flowTracker: ManagePaymentRequestFlowAnalyticsTracker
    private let viewControllerFactory: ManagePaymentRequestViewControllerFactory
    private let featureService: FeatureService

    private let presenterFactory: ViewControllerPresenterFactory
    private var pushPresenter: NavigationViewControllerPresenter
    private var dismisser: ViewControllerDismisser?

    init(
        shouldSupportInvoiceOnly: Bool,
        shouldShowMostRecentlyRequestedIfApplicable: Bool,
        profile: Profile,
        viewControllerFactory: ManagePaymentRequestViewControllerFactory,
        navigationController: UINavigationController,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        featureService: FeatureService = GOS[FeatureServiceKey.self],
        presenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl()
    ) {
        self.shouldSupportInvoiceOnly = shouldSupportInvoiceOnly
        self.shouldShowMostRecentlyRequestedIfApplicable = shouldShowMostRecentlyRequestedIfApplicable
        self.profile = profile
        self.navigationController = navigationController
        self.viewControllerFactory = viewControllerFactory
        self.presenterFactory = presenterFactory
        self.featureService = featureService
        flowTracker = AnalyticsFlowTrackerImpl<ManagePaymentRequestFlowAnalytics>(
            contextIdentity: ManagePaymentRequestFlowAnalytics.identity,
            analyticsTracker: analyticsTracker
        )
        pushPresenter = presenterFactory.makePushPresenter(navigationController: navigationController)
    }

    func start() {
        flowTracker.trackFlow(.started)
        showList()
        flowHandler.flowStarted()
    }

    func terminate() {
        flowFinished()
    }
}

// MARK: - Helpers

private extension ManagePaymentRequestsFlow {
    func getSupportedPaymentRequestType(
        isReusableLinkEnabled: Bool
    ) -> SupportedPaymentRequestType {
        if shouldSupportInvoiceOnly {
            return .invoiceOnly
        }
        switch profile.type {
        case .personal:
            return .singleUseOnly
        case .business:
            return isReusableLinkEnabled ? .singleUseAndReusable : .singleUseOnly
        }
    }

    func getVisibleState(
        isReusableLinkEnabled: Bool
    ) -> PaymentRequestSummaryList.State {
        if shouldSupportInvoiceOnly {
            return .upcoming(.closestToExpiry)
        }
        switch profile.type {
        case .business where isReusableLinkEnabled:
            return .active
        case .business,
             .personal:
            return shouldShowMostRecentlyRequestedIfApplicable
                ? .unpaid(.mostRecentlyRequested)
                : .unpaid(.closestToExpiry)
        }
    }

    func showList() {
        let isReusableLinkEnabled = featureService.getValue(for: ReceiveKitFeatures.reusablePaymentLinksEnabled)
        let supportedPaymentRequestType = getSupportedPaymentRequestType(
            isReusableLinkEnabled: isReusableLinkEnabled
        )
        let visibleState = getVisibleState(
            isReusableLinkEnabled: isReusableLinkEnabled
        )
        let viewController = viewControllerFactory.makePaymentRquestList(
            supportedPaymentRequestType: supportedPaymentRequestType,
            visibleState: visibleState,
            profile: profile,
            navigationController: navigationController,
            flowDismissed: { [weak self] in
                self?.flowFinished()
            }
        )
        dismisser = pushPresenter.present(viewController: viewController)
    }

    func flowFinished() {
        flowTracker.trackFlow(.finished)
        flowHandler.flowFinished(result: (), dismisser: dismisser)
    }
}
