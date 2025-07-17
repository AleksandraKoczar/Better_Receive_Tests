import AnalyticsKit
import LoggingKit
import Neptune
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

final class AccountDetailsIntroFlow: Flow {
    var flowHandler: FlowHandler<AccountDetailsIntroFlowResult> = .empty

    private let origin: AccountDetailsIntroFlowStartOrigin
    private let shouldShowDetailsSummary: Bool
    private let navigationHost: UIViewController
    private let analyticsFlowTracker: AccountDetailsIntroFlowAnalyticsTracker
    private let presenterFactory: ViewControllerPresenterFactory
    private let currencyCode: CurrencyCode
    private let profile: Profile
    private let receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type
    private let accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type
    private let orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    private let accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory
    private let feedbackService: FeedbackService
    private let articleFactory: HelpCenterArticleFactory
    private var viewControllerDismisser: ViewControllerDismisser?

    init(
        origin: AccountDetailsIntroFlowStartOrigin,
        shouldShowDetailsSummary: Bool,
        navigationHost: UIViewController,
        presenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl(),
        currencyCode: CurrencyCode,
        profile: Profile,
        receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type,
        accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        articleFactory: HelpCenterArticleFactory,
        feedbackService: FeedbackService,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self]
    ) {
        self.origin = origin
        self.shouldShowDetailsSummary = shouldShowDetailsSummary
        self.navigationHost = navigationHost
        self.presenterFactory = presenterFactory
        self.currencyCode = currencyCode
        self.profile = profile
        self.receiveSpaceFactoryType = receiveSpaceFactoryType
        self.accountDetailsTipsFlowFactoryType = accountDetailsTipsFlowFactoryType
        self.orderAccountDetailsFlowFactory = orderAccountDetailsFlowFactory
        self.accountDetailsCreationFlowFactory = accountDetailsCreationFlowFactory
        self.articleFactory = articleFactory
        self.feedbackService = feedbackService
        analyticsFlowTracker = AnalyticsFlowTrackerImpl(
            contextIdentity: AccountDetailsIntroFlowAnalytics.identity,
            analyticsTracker: analyticsTracker
        )
    }

    func start() {
        let navigationController = TWNavigationController()
        let viewController = AccountDetailsInfoIntroViewControllerFactory.make(
            shouldShowDetailsSummary: shouldShowDetailsSummary,
            navigationHost: navigationController,
            profile: profile,
            currencyCode: currencyCode,
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            articleFactory: articleFactory,
            feedbackService: feedbackService,
            onDismiss: { [weak self] in
                guard let self else { return }
                analyticsFlowTracker.trackFlow(.finished)
                flowHandler.flowFinished(result: .none, dismisser: viewControllerDismisser)
            }
        )
        navigationController.viewControllers = [viewController]

        let presenter = presenterFactory.makeModalPresenter(parent: navigationHost)

        viewControllerDismisser = presenter.present(viewController: navigationController) { [weak self] in
            guard let self else { return }
            flowHandler.flowStarted()
            analyticsFlowTracker.trackFlow(
                .started,
                properties: [
                    AccountDetailsIntroFlowAnalytics.StartOriginProperty(
                        origin: origin
                    ),
                    SalarySwitchFlowAnalytics.CurrencyProperty(
                        currencyCode: currencyCode
                    ),
                ]
            )
        }
    }

    func terminate() {
        flowHandler.flowFinished(result: .none, dismisser: viewControllerDismisser)

        viewControllerDismisser?.dismiss { [weak self] in
            self?.analyticsFlowTracker.trackFlow(.finished)
        }
    }
}
