import DeepLinkKit
import DeepLinkKitTestingSupport
import NeptuneTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

final class RequestMoneyFlowTests: TWTestCase {
    private let paymentRequestId = PaymentRequestId("some-payment-request-id")
    private var flowFinished = false

    private var requestMoneyFlow: RequestMoneyFlow!
    private var navigationController: MockNavigationController!
    private var paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCaseMock!
    private var accountDetailsFlowFactory: SingleAccountDetailsFlowFactoryMock!
    private var createPaymentRequestFlowFactory: CreatePaymentRequestFlowFactoryMock!
    private var managePaymentRequestsFlowFactory: ManagePaymentRequestsFlowFactoryMock!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var webViewControllerFactory: WebViewControllerFactoryMock.Type!
    private var deepLinkNavigator: DeepLinkNavigatorMock!
    private var dismisser: FakeViewControllerDismisser!
    private var uriHandler: DeepLinkURIHandlerMock!

    override func setUp() {
        super.setUp()

        navigationController = MockNavigationController()
        paymentRequestEligibilityUseCase = PaymentRequestEligibilityUseCaseMock()
        accountDetailsFlowFactory = SingleAccountDetailsFlowFactoryMock()
        createPaymentRequestFlowFactory = CreatePaymentRequestFlowFactoryMock()
        managePaymentRequestsFlowFactory = ManagePaymentRequestsFlowFactoryMock()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        webViewControllerFactory = WebViewControllerFactoryMock.self
        deepLinkNavigator = DeepLinkNavigatorMock()
        dismisser = FakeViewControllerDismisser()
        uriHandler = DeepLinkURIHandlerMock()
        requestMoneyFlow = makeFlow(isPaymentRequestListOnScreen: false)
    }

    override func tearDown() {
        flowFinished = false
        requestMoneyFlow = nil
        navigationController = nil
        paymentRequestEligibilityUseCase = nil
        accountDetailsFlowFactory = nil
        createPaymentRequestFlowFactory = nil
        managePaymentRequestsFlowFactory = nil
        viewControllerPresenterFactory = nil
        webViewControllerFactory = nil
        deepLinkNavigator = nil
        dismisser = nil
        uriHandler = nil

        super.tearDown()
    }

    func test_start_givenEligible_thenStartCreatePaymentRequestFlow() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .eligible(
                defaultBalance: .canned,
                eligibleBalances: .canned
            )
        )
        let createPaymentRequestFlow = MockFlow<CreatePaymentRequestFlowResult>()
        createPaymentRequestFlowFactory.makeForRequestMoneyFlowReturnValue = createPaymentRequestFlow

        requestMoneyFlow.start()

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        XCTAssertTrue(createPaymentRequestFlowFactory.makeForRequestMoneyFlowCalled)
        XCTAssertTrue(createPaymentRequestFlow.startCalled)
    }

    func test_start_givenIneligible_thenStartAccountDetailsFlow() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(.ineligible)
        let accountDetailsFlow = MockFlow<AccountDetailsFlowResult>()
        accountDetailsFlowFactory.makeReturnValue = accountDetailsFlow

        requestMoneyFlow.start()

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        XCTAssertEqual(accountDetailsFlowFactory.makeCallsCount, 1)
        XCTAssertTrue(accountDetailsFlow.startCalled)
    }

    func test_start_givenFailure_thenShowError() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .fail(with: MockError.dummy)

        requestMoneyFlow.start()

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        XCTAssertTrue(navigationController.didShowDismissableAlert)
    }

    func test_accountDetailsFlowFinished() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(.ineligible)
        let accountDetailsFlow = MockFlow<AccountDetailsFlowResult>()
        accountDetailsFlowFactory.makeReturnValue = accountDetailsFlow
        requestMoneyFlow.start()

        accountDetailsFlow.flowHandler.flowFinished(
            result: .interrupted,
            dismisser: dismisser
        )

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertTrue(flowFinished)
    }

    func test_createPaymentRequestFlowFinished_givenSuccessResult_andCompletedContext_thenFinishFlow() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .eligible(
                defaultBalance: .canned,
                eligibleBalances: .canned
            )
        )
        let createPaymentRequestFlow = MockFlow<CreatePaymentRequestFlowResult>()
        createPaymentRequestFlowFactory.makeForRequestMoneyFlowReturnValue = createPaymentRequestFlow
        requestMoneyFlow.start()

        createPaymentRequestFlow.flowHandler.flowFinished(
            result: .success(
                paymentRequestId: paymentRequestId,
                context: .completed
            ),
            dismisser: dismisser
        )

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(dismisser.dismissAnimated, false)
        XCTAssertTrue(flowFinished)
    }

    func test_createPaymentRequestFlowFinished_givenSuccessResult_andPaymentRequestListIsOnScreen_andLinkCreationContext_thenStartPaymentRequestListFlow() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .eligible(
                defaultBalance: .canned,
                eligibleBalances: .canned
            )
        )
        let createPaymentRequestFlow = MockFlow<CreatePaymentRequestFlowResult>()
        createPaymentRequestFlowFactory.makeForRequestMoneyFlowReturnValue = createPaymentRequestFlow
        requestMoneyFlow = makeFlow(isPaymentRequestListOnScreen: true)
        requestMoneyFlow.start()

        createPaymentRequestFlow.flowHandler.flowFinished(
            result: .success(
                paymentRequestId: paymentRequestId,
                context: .linkCreation
            ),
            dismisser: dismisser
        )

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(dismisser.dismissAnimated, false)
        XCTAssertTrue(flowFinished)
    }

    func test_createPaymentRequestFlowFinished_givenSuccessResult_andPaymentRequestListIsNotOnScreen_andLinkCreationContext_thenFinishFlow() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .eligible(
                defaultBalance: .canned,
                eligibleBalances: .canned
            )
        )
        let createPaymentRequestFlow = MockFlow<CreatePaymentRequestFlowResult>()
        createPaymentRequestFlowFactory.makeForRequestMoneyFlowReturnValue = createPaymentRequestFlow
        let paymentRequestListFlow = MockFlow<Void>()
        managePaymentRequestsFlowFactory.makePaymentRequestListWithMostRecentlyRequestedVisibleReturnValue = paymentRequestListFlow
        requestMoneyFlow.start()

        createPaymentRequestFlow.flowHandler.flowFinished(
            result: .success(
                paymentRequestId: paymentRequestId,
                context: .linkCreation
            ),
            dismisser: dismisser
        )

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(dismisser.dismissAnimated, false)
        XCTAssertTrue(managePaymentRequestsFlowFactory.makePaymentRequestListWithMostRecentlyRequestedVisibleCalled)
        XCTAssertTrue(paymentRequestListFlow.startCalled)
        XCTAssertFalse(flowFinished)
    }

    func test_createPaymentRequestFlowFinished_givenSuccessResult_andRequestFromContactContext_thenStartPaymentRequestDetailsFlow() throws {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .eligible(
                defaultBalance: .canned,
                eligibleBalances: .canned
            )
        )
        let createPaymentRequestFlow = MockFlow<CreatePaymentRequestFlowResult>()
        createPaymentRequestFlowFactory.makeForRequestMoneyFlowReturnValue = createPaymentRequestFlow
        let paymentRequestDetailsFlow = MockFlow<Void>()
        managePaymentRequestsFlowFactory.makePaymentRequestDetailsFlowReturnValue = paymentRequestDetailsFlow
        requestMoneyFlow.start()

        createPaymentRequestFlow.flowHandler.flowFinished(
            result: .success(
                paymentRequestId: paymentRequestId,
                context: .requestFromContact
            ),
            dismisser: dismisser
        )

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(dismisser.dismissAnimated, false)
        XCTAssertTrue(managePaymentRequestsFlowFactory.makePaymentRequestDetailsFlowCalled)
        let arguments = try XCTUnwrap(managePaymentRequestsFlowFactory.makePaymentRequestDetailsFlowReceivedArguments)
        XCTAssertEqual(arguments.paymentRequestId, paymentRequestId)
        XCTAssertTrue(paymentRequestDetailsFlow.startCalled)
        XCTAssertFalse(flowFinished)
    }

    func test_createPaymentRequestFlowFinished_givenAbortedResult_thenFinishFlow() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .eligible(
                defaultBalance: .canned,
                eligibleBalances: .canned
            )
        )
        let createPaymentRequestFlow = MockFlow<CreatePaymentRequestFlowResult>()
        createPaymentRequestFlowFactory.makeForRequestMoneyFlowReturnValue = createPaymentRequestFlow
        requestMoneyFlow.start()

        createPaymentRequestFlow.flowHandler.flowFinished(
            result: .aborted,
            dismisser: dismisser
        )

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertTrue(flowFinished)
    }

    func test_paymentRequestListFlowFinished() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .eligible(
                defaultBalance: .canned,
                eligibleBalances: .canned
            )
        )
        let createPaymentRequestFlow = MockFlow<CreatePaymentRequestFlowResult>()
        createPaymentRequestFlowFactory.makeForRequestMoneyFlowReturnValue = createPaymentRequestFlow
        let paymentRequestListFlow = MockFlow<Void>()
        managePaymentRequestsFlowFactory.makePaymentRequestListWithMostRecentlyRequestedVisibleReturnValue = paymentRequestListFlow
        requestMoneyFlow.start()
        createPaymentRequestFlow.flowHandler.flowFinished(
            result: .success(
                paymentRequestId: paymentRequestId,
                context: .linkCreation
            ),
            dismisser: dismisser
        )
        deepLinkNavigator.performNavigationWithRouteReturnValue = true

        paymentRequestListFlow.flowHandler.flowFinished(result: (), dismisser: dismisser)

        XCTAssertEqual(deepLinkNavigator.performNavigationWithRouteCallsCount, 1)
        XCTAssertTrue(deepLinkNavigator.performNavigationWithRouteReceivedRoute is DeepLinkRequestMoneyCompletedRoute)
        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertTrue(flowFinished)
    }

    func test_paymentRequestDetailsFlowFinished() {
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .eligible(
                defaultBalance: .canned,
                eligibleBalances: .canned
            )
        )
        let createPaymentRequestFlow = MockFlow<CreatePaymentRequestFlowResult>()
        createPaymentRequestFlowFactory.makeForRequestMoneyFlowReturnValue = createPaymentRequestFlow
        let paymentRequestDetailsFlow = MockFlow<Void>()
        managePaymentRequestsFlowFactory.makePaymentRequestDetailsFlowReturnValue = paymentRequestDetailsFlow
        requestMoneyFlow.start()
        createPaymentRequestFlow.flowHandler.flowFinished(
            result: .success(
                paymentRequestId: paymentRequestId,
                context: .requestFromContact
            ),
            dismisser: dismisser
        )
        deepLinkNavigator.performNavigationWithRouteReturnValue = true

        paymentRequestDetailsFlow.flowHandler.flowFinished(result: (), dismisser: dismisser)

        XCTAssertEqual(deepLinkNavigator.performNavigationWithRouteCallsCount, 1)
        XCTAssertTrue(deepLinkNavigator.performNavigationWithRouteReceivedRoute is DeepLinkRequestMoneyCompletedRoute)
        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertTrue(flowFinished)
    }

    func test_paymentRequestEligibility_GivenUnavailableWithExpectedReason_ThenCorrectMethodsCalled() {
        let expectedReason = "LoremIpsum.short"
        let mockFlow = MockFlow<Void>()
        uriHandler.makeFlowReturnValue = mockFlow
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .unavailable(
                PaymentRequestEligibilityResult.Unavailable.build(
                    reasonMessage: expectedReason
                )
            )
        )
        requestMoneyFlow.start()

        XCTAssertTrue(viewControllerPresenterFactory.makeModalPresenterCalled)
    }

    func test_paymentRequestEligibility_GivenUnavailableWithURI_ThenCorrectMethodsCalled() {
        let expectedUri = URI(string: "https://avasd.com")
        let mockFlow = MockFlow<Void>()
        uriHandler.makeFlowReturnValue = mockFlow
        paymentRequestEligibilityUseCase.checkEligibilityReturnValue = .just(
            .unavailable(
                PaymentRequestEligibilityResult.Unavailable.build(
                    uri: expectedUri
                )
            )
        )
        requestMoneyFlow.start()

        XCTAssertTrue(uriHandler.makeFlowCalled)
        XCTAssertTrue(mockFlow.startCalled)
    }
}

// MARK: - Helpers

private extension RequestMoneyFlowTests {
    func makeFlow(isPaymentRequestListOnScreen: Bool) -> RequestMoneyFlow {
        let flow = RequestMoneyFlow(
            isPaymentRequestListOnScreen: isPaymentRequestListOnScreen,
            entryPoint: .canned,
            profile: FakePersonalProfileInfo().asProfile(),
            selectedBalanceInfo: RequestMoneyFlow.BalanceInfo.canned,
            contact: .canned,
            deepLinkNavigator: deepLinkNavigator,
            inviteFlowFactory: ReceiveInviteFlowFactoryMock(),
            navigationController: navigationController,
            accountDetailsFlowFactory: accountDetailsFlowFactory,
            webViewControllerFactory: webViewControllerFactory,
            paymentRequestEligibilityUseCase: paymentRequestEligibilityUseCase,
            createPaymentRequestFlowFactory: createPaymentRequestFlowFactory,
            managePaymentRequestsFlowFactory: managePaymentRequestsFlowFactory,
            contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactoryMock(),
            viewControllerPresenterFactory: viewControllerPresenterFactory,
            uriHandler: uriHandler,
            scheduler: .immediate
        )
        flow.onFinish { _, _ in self.flowFinished = true }
        return flow
    }
}
