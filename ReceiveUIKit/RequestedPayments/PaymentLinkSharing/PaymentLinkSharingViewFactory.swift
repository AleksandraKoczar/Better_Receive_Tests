import AnalyticsKit
import MacrosKit
import Prism
import TWFoundation
import UIKit
import UserKit
import WiseCore

@MainActor
public protocol PaymentLinkSharingViewFactory {
    func make(
        paymentRequestId: PaymentRequestId,
        source: PaymentLinkSharingSource,
        profile: Profile,
        navigationController: UINavigationController,
        paymentRequestDetailsHandler: @escaping (PaymentRequestId) -> Void
    ) -> UIViewController
}

@Init
public struct PaymentLinkSharingViewFactoryImpl: PaymentLinkSharingViewFactory {
    @Init(default: GOS[AnalyticsTrackerKey.self])
    private let analyticsTracker: AnalyticsTracker

    public func make(
        paymentRequestId: PaymentRequestId,
        source: PaymentLinkSharingSource,
        profile: Profile,
        navigationController: UINavigationController,
        paymentRequestDetailsHandler: @escaping (PaymentRequestId) -> Void
    ) -> UIViewController {
        let interactor = PaymentLinkSharingInteractorImpl(paymentRequestId: paymentRequestId, profileId: profile.id)
        let router = PaymentLinkSharingRouterImpl(
            profile: profile,
            paymentRequestDetailsHandler: paymentRequestDetailsHandler,
            navigationController: navigationController
        )
        let mixpanelTracker = MixpanelPrismTracker(analyticsTracker: analyticsTracker)
        let tracking = PaymentRequestShareModalTrackingFactory().make(
            onTrack: mixpanelTracker.trackEvent(name:properties:)
        )

        let presenter = PaymentLinkSharingPresenterImpl(
            source: source,
            interactor: interactor,
            router: router,
            tracking: tracking
        )

        return PaymentLinkSharingViewController(presenter: presenter)
    }
}
