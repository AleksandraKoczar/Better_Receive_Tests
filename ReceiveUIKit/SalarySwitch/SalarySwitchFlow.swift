import AnalyticsKit
import Neptune
import TWFoundation
import TWUI
import UserKit
import WiseCore

final class SalarySwitchFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private let origin: SalarySwitchFlowStartOrigin
    private let accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus
    private let currencyCode: CurrencyCode
    private let presenterFactory: ViewControllerPresenterFactory
    private let articleFactory: HelpCenterArticleFactory
    private let profile: Profile
    private let host: UIViewController
    private let flowTracker: SalarySwitchFlowAnalyticsTracker
    private let orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    private let salarySwitchUpsellFactory: SalarySwitchUpsellFactory
    private let analyticsTracker: AnalyticsTracker

    private var navigationController: UINavigationController?
    private var dismisser: ViewControllerDismisser?

    private var upsellPresenter: SalarySwitchUpsellPresenter?

    init(
        origin: SalarySwitchFlowStartOrigin,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        profile: Profile,
        currencyCode: CurrencyCode,
        presenterFactory: ViewControllerPresenterFactory,
        host: UIViewController,
        articleFactory: HelpCenterArticleFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        salarySwitchUpsellFactory: SalarySwitchUpsellFactory = SalarySwitchUpsellFactoryImpl(),
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self]
    ) {
        self.origin = origin
        self.accountDetailsRequirementStatus = accountDetailsRequirementStatus
        self.profile = profile
        self.currencyCode = currencyCode
        self.presenterFactory = presenterFactory
        self.host = host
        self.articleFactory = articleFactory
        self.orderAccountDetailsFlowFactory = orderAccountDetailsFlowFactory
        self.salarySwitchUpsellFactory = salarySwitchUpsellFactory
        self.analyticsTracker = analyticsTracker

        flowTracker = SalarySwitchFlowAnalyticsTracker(
            contextIdentity: SalarySwitchFlowAnalytics.identity,
            analyticsTracker: analyticsTracker
        )
    }

    func start() {
        flowTracker.trackFlow(
            .started,
            properties: [
                SalarySwitchFlowAnalytics.CurrencyProperty(
                    currencyCode: currencyCode
                ),
                SalarySwitchFlowAnalytics.OriginProperty(
                    origin: origin
                ),
                SalarySwitchFlowAnalytics.ProfileIdProperty(
                    value: String(profile.id.value)
                ),
            ]
        )
        showUpsell()
        flowHandler.flowStarted()
    }

    func terminate() {
        flowTracker.trackFlow(.finished)
        flowHandler.flowFinished(result: (), dismisser: dismisser)
    }
}

// MARK: - Navigation

private extension SalarySwitchFlow {
    func showUpsell() {
        let factory = SalarySwitchFactoryImpl(
            analyticsFlowTracker: flowTracker,
            onDismiss: { [weak self] in
                guard let self else { return }
                flowTracker.trackFlow(.finished)
                flowHandler.flowFinished(result: (), dismisser: dismisser)
            }
        )

        upsellPresenter = salarySwitchUpsellFactory.makePresenter(
            profile: profile,
            currency: currencyCode,
            accountDetailsRequirementStatus: accountDetailsRequirementStatus,
            navigationHost: host,
            presenterFactory: presenterFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            factory: factory,
            articleFactory: articleFactory,
            dismisserCapturer: { [weak self] dismisser in
                self?.dismisser = dismisser
            }
        )
        upsellPresenter?.start()
        flowTracker.trackStep(SalarySwitchFlowAnalytics.Upsell(), .started)
    }
}
