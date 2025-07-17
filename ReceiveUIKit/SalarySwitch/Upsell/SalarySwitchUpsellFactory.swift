import Neptune
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol SalarySwitchUpsellFactory {
    func makePresenter(
        profile: Profile,
        currency: CurrencyCode,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        navigationHost: UIViewController,
        presenterFactory: ViewControllerPresenterFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        factory: SalarySwitchFactory,
        articleFactory: HelpCenterArticleFactory,
        dismisserCapturer: @escaping (ViewControllerDismisser) -> Void
    ) -> SalarySwitchUpsellPresenter
}

struct SalarySwitchUpsellFactoryImpl: SalarySwitchUpsellFactory {
    func makePresenter(
        profile: Profile,
        currency: CurrencyCode,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        navigationHost: UIViewController,
        presenterFactory: ViewControllerPresenterFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        factory: SalarySwitchFactory,
        articleFactory: HelpCenterArticleFactory,
        dismisserCapturer: @escaping (ViewControllerDismisser) -> Void
    ) -> SalarySwitchUpsellPresenter {
        let useCase = SalarySwitchUpsellUseCaseFactory.make()
        let router = SalarySwitchUpsellRouterImpl(
            host: navigationHost,
            presenterFactory: presenterFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            factory: factory,
            articleFactory: articleFactory,
            dismisserCapturer: dismisserCapturer
        )
        return SalarySwitchUpsellPresenterImpl(
            profile: profile,
            currency: currency,
            accountDetailsRequirementStatus: accountDetailsRequirementStatus,
            useCase: useCase,
            router: router
        )
    }
}
