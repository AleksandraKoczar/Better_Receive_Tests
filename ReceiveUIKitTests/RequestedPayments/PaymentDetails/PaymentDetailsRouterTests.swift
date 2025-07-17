import ApiKit
import ApiKitTestingSupport
import DeepLinkKit
import DeepLinkKitTestingSupport
import PersistenceKit
import PersistenceKitTestingSupport
import ReceiveKit
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import UserKit
import UserKitTestingSupport
import WiseCore

final class PaymentDetailsRouterTests: TWTestCase {
    private let paymentRequestId = PaymentRequestId("some-payment-request-id")

    private var router: PaymentDetailsRouterImpl!
    private var navigationController: MockNavigationController!
    private var paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegateMock!
    private var webViewControllerFactory: WebViewControllerFactoryMock.Type!
    private var refundFlowFactory: PaymentRequestRefundFlowFactoryMock!
    private var userProvider: StubUserProvider!
    private var featureService: StubFeatureService!
    private var flowDispatcher: TestFlowDispatcher!

    override func setUp() {
        super.setUp()
        navigationController = MockNavigationController()
        paymentDetailsRefundFlowDelegate = PaymentDetailsRefundFlowDelegateMock()
        webViewControllerFactory = WebViewControllerFactoryMock.self
        userProvider = StubUserProvider()
        featureService = StubFeatureService()
        flowDispatcher = TestFlowDispatcher()
        refundFlowFactory = PaymentRequestRefundFlowFactoryMock()

        router = PaymentDetailsRouterImpl(
            paymentRequestId: paymentRequestId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            webViewControllerFactory: webViewControllerFactory,
            refundFlowFactory: refundFlowFactory,
            userProvider: userProvider,
            featureService: featureService,
            flowPresenter: .test(with: flowDispatcher)
        )
    }

    override func tearDown() {
        router = nil
        webViewControllerFactory = nil
        paymentDetailsRefundFlowDelegate = nil
        navigationController = nil
        userProvider = nil
        featureService = nil
        refundFlowFactory = nil
        flowDispatcher = nil
        super.tearDown()
    }

    @MainActor
    func test_showRefundFlowInWeb_givenFeatureDisabled_thenShowWebView() {
        let expectedProfileId = ProfileId(128)
        let expectedUserId = UserId(64)
        userProvider.activeProfile = FakeBusinessProfileInfo()
            .with(profileId: expectedProfileId)
            .asProfile()

        userProvider.user = StubUserInfo(userId: expectedUserId)
        featureService.stub(value: false, for: ReceiveKitFeatures.nativeRefundPaymentRequestEnabled)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = WebContentViewController(url: URL(string: "https://abc.com")!)

        router.showRefundFlow(paymentId: "some-payment-id", profileId: .build(value: 128))

        let expectedUrl = URL(string: "https://wise.com/flows/request-refund/some-payment-id?next=PAYMENT_LINKS&requestId=some-payment-request-id")
        let receiveArguments = webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReceivedArguments
        XCTAssertEqual(
            receiveArguments?.url,
            expectedUrl
        )
        XCTAssertEqual(
            receiveArguments?.userInfoForAuthentication.userId,
            expectedUserId
        )
        XCTAssertEqual(
            receiveArguments?.userInfoForAuthentication.profileId,
            expectedProfileId
        )
        XCTAssertTrue(
            webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationCalled
        )
    }

    @MainActor
    func test_showRefundFlow_givenFeatureEnabled_thenShowNativeFlow() {
        let expectedProfileId = ProfileId(128)
        let expectedUserId = UserId(64)
        userProvider.activeProfile = FakeBusinessProfileInfo()
            .with(profileId: expectedProfileId)
            .asProfile()
        let flow = MockFlow<Void>()
        refundFlowFactory.makeReturnValue = flow

        userProvider.user = StubUserInfo(userId: expectedUserId)
        featureService.stub(value: true, for: ReceiveKitFeatures.nativeRefundPaymentRequestEnabled)

        router.showRefundFlow(paymentId: "some-payment-id", profileId: .canned)

        XCTAssertTrue(flowDispatcher.lastFlowPresented is MockFlow<Void>)
    }

    func test_showRefundDisabledBottomSheet() {
        router.showRefundDisabledBottomSheet(
            title: LoremIpsum.short,
            illustrationUrn: "urn:wise:illustrations:construction-fence",
            message: LoremIpsum.medium
        )

        XCTAssertEqual(navigationController.presentInvokedCount, 1)
    }

    @MainActor
    func test_navigateToURL_givenReceivePaymentRequestDetailsUrlWithPaymentRequestId_thenInvokeDelegateMethod() {
        let url = URL(string: "https://wise.com/account/payment-links/\(paymentRequestId.value)")!
        router.navigateToURL(
            viewController: WebContentViewController(url: url),
            url: url
        )

        XCTAssertEqual(paymentDetailsRefundFlowDelegate.didRefundFlowCompletedCallsCount, 1)
    }

    @MainActor
    func test_navigateToURL_givenReceiveRandomUrl_thenIgnoreIt() {
        let url = URL(string: "https://wise.com/accounts/some-account-id")!
        router.navigateToURL(
            viewController: WebContentViewController(url: url),
            url: url
        )

        XCTAssertEqual(paymentDetailsRefundFlowDelegate.didRefundFlowCompletedCallsCount, 0)
    }
}
