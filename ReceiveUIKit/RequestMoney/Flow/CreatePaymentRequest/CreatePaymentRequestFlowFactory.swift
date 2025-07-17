import ReceiveKit
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol CreatePaymentRequestFlowFactory: AnyObject {
    func makeForRequestMoneyFlow(
        entryPoint: RequestMoneyFlow.EntryPoint,
        profile: Profile,
        contact: RequestMoneyContact?,
        preSelectedBalanceCurrencyCode: CurrencyCode?,
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances,
        contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory,
        navigationController: UINavigationController
    ) -> any Flow<CreatePaymentRequestFlowResult>
}

final class CreatePaymentRequestFlowFactoryImpl: CreatePaymentRequestFlowFactory {
    private let viewControllerFactory: CreatePaymentRequestViewControllerFactory
    private let accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory
    private let inviteFlowFactory: ReceiveInviteFlowFactory
    private let findFriendsFlowFactory: FindFriendsFlowFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let feedbackService: FeedbackService

    init(
        inviteFlowFactory: ReceiveInviteFlowFactory,
        eligibilityService: ReceiveEligibilityService,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        findFriendsFlowFactory: FindFriendsFlowFactory,
        feedbackService: FeedbackService,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) {
        self.accountDetailsCreationFlowFactory = accountDetailsCreationFlowFactory
        self.inviteFlowFactory = inviteFlowFactory
        self.findFriendsFlowFactory = findFriendsFlowFactory
        self.feedbackService = feedbackService
        self.webViewControllerFactory = webViewControllerFactory
        viewControllerFactory = CreatePaymentRequestViewControllerFactoryImpl(
            eligibilityService: eligibilityService,
            feedbackService: feedbackService,
            webViewControllerFactory: webViewControllerFactory
        )
    }

    func makeForRequestMoneyFlow(
        entryPoint: RequestMoneyFlow.EntryPoint,
        profile: Profile,
        contact: RequestMoneyContact?,
        preSelectedBalanceCurrencyCode: CurrencyCode?,
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances,
        contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory,
        navigationController: UINavigationController
    ) -> any Flow<CreatePaymentRequestFlowResult> {
        make(
            entryPoint: CreatePaymentRequestFlow.EntryPoint(
                requestMoneyFlowEntryPoint: entryPoint
            ),
            profile: profile,
            contact: contact,
            preSelectedBalanceCurrencyCode: preSelectedBalanceCurrencyCode,
            defaultBalance: defaultBalance,
            eligibleBalances: eligibleBalances,
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            inviteFlowFactory: inviteFlowFactory,
            findFriendsFlowFactory: findFriendsFlowFactory,
            navigationController: navigationController
        )
    }
}

// MARK: - Initializers

private extension CreatePaymentRequestFlowFactoryImpl {
    func make(
        entryPoint: CreatePaymentRequestFlow.EntryPoint,
        profile: Profile,
        contact: RequestMoneyContact?,
        preSelectedBalanceCurrencyCode: CurrencyCode?,
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances,
        contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory,
        inviteFlowFactory: ReceiveInviteFlowFactory,
        findFriendsFlowFactory: FindFriendsFlowFactory,
        navigationController: UINavigationController
    ) -> any Flow<CreatePaymentRequestFlowResult> {
        CreatePaymentRequestFlow(
            entryPoint: entryPoint,
            profile: profile,
            contact: contact,
            preSelectedBalanceCurrencyCode: preSelectedBalanceCurrencyCode,
            defaultBalance: defaultBalance,
            eligibleBalances: eligibleBalances,
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            paymentMethodsDynamicFlowHandler: PaymentMethodsDynamicFlowHandlerImpl(navigationController: navigationController),
            webViewControllerFactory: webViewControllerFactory,
            navController: navigationController,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            findFriendsFlowFactory: findFriendsFlowFactory,
            viewControllerFactory: viewControllerFactory,
            inviteFlowFactory: inviteFlowFactory
        )
    }
}
