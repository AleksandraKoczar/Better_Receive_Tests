import AnalyticsKit
import ContactsKit
import Neptune
import Prism
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol QuickpayPayerFlowFactory: AnyObject {
    func makeFlow(
        nickname: String,
        amount: String?,
        currency: CurrencyCode?,
        description: String?,
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void>
}

public class QuickpayPayerFlowFactoryImpl: QuickpayPayerFlowFactory {
    private let payWithWiseFlowFactory: PayWithWiseFlowFactory
    private let featureService: FeatureService
    private let urlOpener: UrlOpener

    public init(
        payWithWiseFlowFactory: PayWithWiseFlowFactory,
        featureService: FeatureService = GOS[FeatureServiceKey.self],
        urlOpener: UrlOpener = UIApplication.shared
    ) {
        self.payWithWiseFlowFactory = payWithWiseFlowFactory
        self.featureService = featureService
        self.urlOpener = urlOpener
    }

    public func makeFlow(
        nickname: String,
        amount: String?,
        currency: CurrencyCode?,
        description: String?,
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        let prismTracker = MixpanelPrismTracker()
        let quickpayTracker = QuickpayTrackingFactory().make(
            onTrack: prismTracker.trackEvent(name:properties:)
        )

        let wisetagContactInteractor = WisetagContactInteractorFactory.make(
            profileId: profile.id,
            uriImageLoader: URIImageLoaderImpl(),
            svgImageLoader: ImageCacheImpl()
        )

        return QuickpayPayerFlow(
            profile: profile,
            nickname: nickname,
            amount: amount,
            currency: currency,
            description: description,
            navigationController: navigationController,
            viewControllerFactory: QuickpayPayerViewControllerFactoryImpl(),
            viewControllerPresenterFactory: ViewControllerPresenterFactoryImpl(),
            wisetagContactInteractor: wisetagContactInteractor,
            payWithWiseFlowFactory: payWithWiseFlowFactory,
            userProvider: GOS[UserProviderKey.self],
            analyticsTracker: quickpayTracker,
            urlOpener: urlOpener,
            scheduler: .main
        )
    }
}
