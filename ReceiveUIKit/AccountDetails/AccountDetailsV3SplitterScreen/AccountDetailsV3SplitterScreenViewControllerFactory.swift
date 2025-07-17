import AnalyticsKit
import Prism
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsSplitterScreenViewControllerFactory: AnyObject {
    func make(
        profile: Profile,
        currency: CurrencyCode,
        source: AccountDetailsInfoInvocationSource,
        host: UINavigationController
    ) -> UIViewController
}

public class AccountDetailsSplitterScreenViewControllerFactoryImpl: AccountDetailsSplitterScreenViewControllerFactory {
    private let accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory
    private let accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory

    public init(
        accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory
    ) {
        self.accountDetailsInfoFactory = accountDetailsInfoFactory
        self.accountDetailsCreationFlowFactory = accountDetailsCreationFlowFactory
    }

    public func make(
        profile: Profile,
        currency: CurrencyCode,
        source: AccountDetailsInfoInvocationSource,
        host: UINavigationController
    ) -> UIViewController {
        let router = AccountDetailsV3ListRouterImpl(
            navigationHost: host,
            source: source,
            accountDetailsInfoFactory: accountDetailsInfoFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            accountDetailsSplitterViewControllerFactory: self,
            profile: profile
        )
        let prismTracker = MixpanelPrismTracker()
        let receiveMethodsNavigationTracking = ReceiveMethodsNavigationTrackingFactory().make(
            onTrack: prismTracker.trackEvent(name:properties:)
        )

        let presenter = AccountDetailsV3SplitterScreenPresenterImpl(
            currency: currency,
            profile: profile,
            router: router,
            receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCaseFactory.make(),
            analyticsTracker: receiveMethodsNavigationTracking
        )
        return AccountDetailsV3SplitterScreenViewController(presenter: presenter)
    }
}
