import DeepLinkKit
import ReceiveKit
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol RequestMoneyFlowFactory: AnyObject {
    func makeModalForDeeplinkUIFactory(
        profile: Profile,
        balanceId: BalanceId?,
        contact: RequestMoneyContact?,
        rootViewController: UIViewController
    ) -> any Flow<Void>

    func makeModalForLaunchpadFactory(
        profile: Profile,
        balanceId: BalanceId?,
        contact: RequestMoneyContact?,
        rootViewController: UIViewController
    ) -> any Flow<Void>

    func makeModalFlowForBalance(
        profile: Profile,
        selectedBalanceInfo: (BalanceId, CurrencyCode)?,
        rootViewController: UIViewController
    ) -> any Flow<Void>

    func makeModalFlowForCardOnboardingDeeplink(
        profile: Profile,
        rootViewController: UIViewController
    ) -> any Flow<Void>

    func makeModalFlowForContactList(
        profile: Profile,
        contact: RequestMoneyContact,
        rootViewController: UIViewController
    ) -> any Flow<Void>

    func makeModalFlowForRecentContact(
        profile: Profile,
        contact: RequestMoneyContact,
        rootViewController: UIViewController
    ) -> any Flow<Void>

    func makeModalFlowForPaymentRequestList(
        profile: Profile,
        rootViewController: UIViewController
    ) -> any Flow<Void>

    func makeFlowForPayWithWiseSuccess(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void>
}

public final class RequestMoneyFlowFactoryImpl: RequestMoneyFlowFactory {
    private let currencySelectorFactory: ReceiveCurrencySelectorFactory
    private let inviteFlowFactory: ReceiveInviteFlowFactory
    private let accountDetailsFlowFactory: SingleAccountDetailsFlowFactory
    private let contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory
    private let createPaymentRequestFlowFactory: CreatePaymentRequestFlowFactory
    private let managePaymentRequestsFlowFactory: ManagePaymentRequestsFlowFactory
    private let findFriendsFlowFactory: FindFriendsFlowFactory
    private let deeplinkRouteFactory: DeepLinkRouteFactory
    private let deepLinkNavigator: DeepLinkNavigator? // Mark it as optional to avoid force unwrap in `Wise` target
    private let webViewControllerFactory: WebViewControllerFactory.Type

    public init(
        currencySelectorFactory: ReceiveCurrencySelectorFactory,
        inviteFlowFactory: ReceiveInviteFlowFactory,
        accountDetailsFlowFactory: SingleAccountDetailsFlowFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory,
        eligibilityService: ReceiveEligibilityService,
        feedbackService: FeedbackService,
        webViewControllerFactory: WebViewControllerFactory.Type,
        helpCenterArticleFactory: HelpCenterArticleFactory,
        deeplinkRouteFactory: DeepLinkRouteFactory,
        deepLinkNavigator: DeepLinkNavigator?
    ) {
        self.currencySelectorFactory = currencySelectorFactory
        self.inviteFlowFactory = inviteFlowFactory
        self.accountDetailsFlowFactory = accountDetailsFlowFactory
        self.contactSearchViewControllerFactory = contactSearchViewControllerFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.deeplinkRouteFactory = deeplinkRouteFactory
        self.deepLinkNavigator = deepLinkNavigator
        findFriendsFlowFactory = FindFriendsFlowFactoryImpl(
            helpCenterArticleFactory: helpCenterArticleFactory
        )
        createPaymentRequestFlowFactory = CreatePaymentRequestFlowFactoryImpl(
            inviteFlowFactory: inviteFlowFactory,
            eligibilityService: eligibilityService,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            findFriendsFlowFactory: findFriendsFlowFactory,
            feedbackService: feedbackService,
            webViewControllerFactory: webViewControllerFactory
        )
        managePaymentRequestsFlowFactory = ManagePaymentRequestsFlowFactoryImpl(
            currencySelectorFactory: currencySelectorFactory,
            webViewControllerFactory: webViewControllerFactory,
            helpCenterArticleFactory: helpCenterArticleFactory
        )
    }

    public func makeModalForLaunchpadFactory(
        profile: Profile,
        balanceId: BalanceId?,
        contact: RequestMoneyContact?,
        rootViewController: UIViewController
    ) -> any Flow<Void> {
        let selectedBalanceInfo: (BalanceId, CurrencyCode?)? = {
            guard let balanceId else { return nil }
            return (balanceId, nil)
        }()
        return makeModalFlow(
            isPaymentRequestListOnScreen: false,
            entryPoint: .launchpad,
            profile: profile,
            selectedBalanceInfo: selectedBalanceInfo,
            contact: contact,
            rootViewController: rootViewController
        )
    }

    public func makeModalForDeeplinkUIFactory(
        profile: Profile,
        balanceId: BalanceId?,
        contact: RequestMoneyContact?,
        rootViewController: UIViewController
    ) -> any Flow<Void> {
        let selectedBalanceInfo: (BalanceId, CurrencyCode?)? = {
            guard let balanceId else { return nil }
            return (balanceId, nil)
        }()
        return makeModalFlow(
            isPaymentRequestListOnScreen: false,
            entryPoint: .deeplink,
            profile: profile,
            selectedBalanceInfo: selectedBalanceInfo,
            contact: contact,
            rootViewController: rootViewController
        )
    }

    public func makeModalFlowForBalance(
        profile: Profile,
        selectedBalanceInfo: (BalanceId, CurrencyCode)?,
        rootViewController: UIViewController
    ) -> any Flow<Void> {
        makeModalFlow(
            isPaymentRequestListOnScreen: false,
            entryPoint: .balance,
            profile: profile,
            selectedBalanceInfo: selectedBalanceInfo,
            contact: nil,
            rootViewController: rootViewController
        )
    }

    public func makeModalFlowForCardOnboardingDeeplink(
        profile: Profile,
        rootViewController: UIViewController
    ) -> any Flow<Void> {
        makeModalFlow(
            isPaymentRequestListOnScreen: false,
            entryPoint: .cardOnboardingDeeplink,
            profile: profile,
            selectedBalanceInfo: nil,
            contact: nil,
            rootViewController: rootViewController
        )
    }

    public func makeModalFlowForContactList(
        profile: Profile,
        contact: RequestMoneyContact,
        rootViewController: UIViewController
    ) -> any Flow<Void> {
        makeModalFlow(
            isPaymentRequestListOnScreen: false,
            entryPoint: .contactList,
            profile: profile,
            selectedBalanceInfo: nil,
            contact: contact,
            rootViewController: rootViewController
        )
    }

    public func makeModalFlowForRecentContact(
        profile: Profile,
        contact: RequestMoneyContact,
        rootViewController: UIViewController
    ) -> any Flow<Void> {
        makeModalFlow(
            isPaymentRequestListOnScreen: false,
            entryPoint: .recentContact,
            profile: profile,
            selectedBalanceInfo: nil,
            contact: contact,
            rootViewController: rootViewController
        )
    }

    public func makeModalFlowForPaymentRequestList(
        profile: Profile,
        rootViewController: UIViewController
    ) -> any Flow<Void> {
        makeModalFlow(
            isPaymentRequestListOnScreen: true,
            entryPoint: .paymentRequestList,
            profile: profile,
            selectedBalanceInfo: nil,
            contact: nil,
            rootViewController: rootViewController
        )
    }

    public func makeFlowForPayWithWiseSuccess(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        makeFlow(
            isPaymentRequestListOnScreen: false,
            entryPoint: .payWithWiseSuccess,
            profile: profile,
            selectedBalanceInfo: nil,
            contact: nil,
            navigationController: navigationController
        )
    }
}

private extension RequestMoneyFlowFactoryImpl {
    func makeModalFlow(
        isPaymentRequestListOnScreen: Bool,
        entryPoint: RequestMoneyFlow.EntryPoint,
        profile: Profile,
        selectedBalanceInfo: (BalanceId, CurrencyCode?)?,
        contact: RequestMoneyContact?,
        rootViewController: UIViewController
    ) -> any Flow<Void> {
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        let balanceInfo: RequestMoneyFlow.BalanceInfo? = {
            guard let selectedBalanceInfo else { return nil }
            return .init(
                id: selectedBalanceInfo.0,
                currencyCode: selectedBalanceInfo.1
            )
        }()
        let flow = RequestMoneyFlow(
            isPaymentRequestListOnScreen: isPaymentRequestListOnScreen,
            entryPoint: entryPoint,
            profile: profile,
            selectedBalanceInfo: balanceInfo,
            contact: contact,
            deepLinkNavigator: deepLinkNavigator,
            inviteFlowFactory: inviteFlowFactory,
            navigationController: navigationController,
            accountDetailsFlowFactory: accountDetailsFlowFactory,
            webViewControllerFactory: webViewControllerFactory,
            createPaymentRequestFlowFactory: createPaymentRequestFlowFactory,
            managePaymentRequestsFlowFactory: managePaymentRequestsFlowFactory,
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            uriHandler: DeepLinkURIHandlerImpl(
                deeplinkRouteFactory: deeplinkRouteFactory
            )
        )
        return ModalPresentationFlow(
            flow: flow,
            rootViewController: rootViewController,
            flowController: navigationController
        )
    }

    func makeFlow(
        isPaymentRequestListOnScreen: Bool,
        entryPoint: RequestMoneyFlow.EntryPoint,
        profile: Profile,
        selectedBalanceInfo: (BalanceId, CurrencyCode?)?,
        contact: RequestMoneyContact?,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        let balanceInfo: RequestMoneyFlow.BalanceInfo? = {
            guard let selectedBalanceInfo else { return nil }
            return .init(
                id: selectedBalanceInfo.0,
                currencyCode: selectedBalanceInfo.1
            )
        }()
        return RequestMoneyFlow(
            isPaymentRequestListOnScreen: isPaymentRequestListOnScreen,
            entryPoint: entryPoint,
            profile: profile,
            selectedBalanceInfo: balanceInfo,
            contact: contact,
            deepLinkNavigator: deepLinkNavigator,
            inviteFlowFactory: inviteFlowFactory,
            navigationController: navigationController,
            accountDetailsFlowFactory: accountDetailsFlowFactory,
            webViewControllerFactory: webViewControllerFactory,
            createPaymentRequestFlowFactory: createPaymentRequestFlowFactory,
            managePaymentRequestsFlowFactory: managePaymentRequestsFlowFactory,
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            uriHandler: DeepLinkURIHandlerImpl(
                deeplinkRouteFactory: deeplinkRouteFactory
            )
        )
    }
}
