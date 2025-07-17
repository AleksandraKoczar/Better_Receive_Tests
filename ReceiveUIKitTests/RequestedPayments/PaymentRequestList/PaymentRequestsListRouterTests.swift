import AnalyticsKitTestingSupport
import DeepLinkKit
import DeepLinkKitTestingSupport
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

final class PaymentRequestsListRouterTests: TWTestCase {
    private var router: PaymentRequestsListRouterImpl!
    private var navigationController: MockNavigationController!
    private var listUdpateDelegate: PaymentRequestListUpdaterMock!
    private var allDeepLinksUIFactory: AllDeepLinksUIFactoryMock!
    private var webViewControllerFactory: WebViewControllerFactoryMock.Type!

    override func setUp() {
        super.setUp()
        navigationController = MockNavigationController()
        listUdpateDelegate = PaymentRequestListUpdaterMock()
        allDeepLinksUIFactory = AllDeepLinksUIFactoryMock()
        webViewControllerFactory = WebViewControllerFactoryMock.self
        router = PaymentRequestsListRouterImpl(
            navigationController: navigationController,
            currencySelectorFactory: ReceiveCurrencySelectorFactoryMock(),
            webViewControllerFactory: webViewControllerFactory,
            helpCenterArticleFactory: HelpCenterArticleFactoryMock(),
            userProvider: StubUserProvider(),
            allDeepLinksUIFactory: allDeepLinksUIFactory
        )
    }

    override func tearDown() {
        router = nil
        navigationController = nil
        listUdpateDelegate = nil
        allDeepLinksUIFactory = nil
        webViewControllerFactory = nil
        super.tearDown()
    }

    func test_showNewRequestFlow() throws {
        let mockFlow = MockFlow<Void>()
        allDeepLinksUIFactory.buildReturnValue = mockFlow

        router.showNewRequestFlow(
            profile: FakePersonalProfileInfo().asProfile(),
            listUpdateDelegate: PaymentRequestListUpdaterMock()
        )

        XCTAssertEqual(allDeepLinksUIFactory.buildCallsCount, 1)
        let arguments = try XCTUnwrap(allDeepLinksUIFactory.buildReceivedArguments)
        let route = try XCTUnwrap(arguments.route as? DeepLinkRequestMoneyRoute)
        XCTAssertNil(route.balanceId)
        XCTAssertFalse(route.isUrn)
        XCTAssertEqual(
            arguments.context.source,
            DeepLinkRequestMoneyRouteImpl.TargetRoute.paymentRequestList.rawValue
        )
        XCTAssertTrue(mockFlow.startCalled)
    }

    func test_showNewRequest_givenRequestMoneyFlowFinished_thenUpdateList() {
        let mockFlow = MockFlow<Void>()
        allDeepLinksUIFactory.buildReturnValue = mockFlow
        let delegate = PaymentRequestListUpdaterMock()
        router.showNewRequestFlow(
            profile: FakePersonalProfileInfo().asProfile(),
            listUpdateDelegate: delegate
        )

        let dismisser = FakeViewControllerDismisser()
        mockFlow.flowHandler.flowFinished(result: (), dismisser: dismisser)

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(delegate.requestStatusUpdatedCallsCount, 1)
    }

    func test_showCreateInvoiceOnWeb() throws {
        let viewController = WebContentViewController(url: Branding.current.url)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = viewController

        let profileId = ProfileId(1234)

        XCTAssertFalse(viewController.isDownloadSupported)
        router.showCreateInvoiceOnWeb(
            profileId: profileId,
            listUpdateDelegate: listUdpateDelegate
        )

        XCTAssertTrue(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationCalled)
        let arguments = try XCTUnwrap(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReceivedArguments)
        XCTAssertEqual(
            arguments.url,
            Branding.current.url.appendingPathComponent("/flows/create-invoice")
        )
        XCTAssertTrue(viewController.isDownloadSupported)
        XCTAssertEqual(arguments.userInfoForAuthentication.profileId, profileId)
        XCTAssertEqual(navigationController.presentInvokedCount, 1)
        let presentedViewController = try XCTUnwrap(navigationController.lastPresentedViewController as? TWNavigationController)
        XCTAssertTrue(presentedViewController.topViewController === viewController)
    }

    func test_showMethodManagementOnWeb() throws {
        let viewController = WebContentViewController(url: Branding.current.url)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = viewController
        let profileId = ProfileId(1234)

        router.showMethodManagementOnWeb(profileId: profileId)
        XCTAssertTrue(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationCalled)
        let arguments = try XCTUnwrap(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReceivedArguments)
        XCTAssertEqual(
            arguments.url,
            Branding.current.url.appendingPathComponent("/payments/method-management")
        )
        XCTAssertEqual(arguments.userInfoForAuthentication.profileId, profileId)
        XCTAssertEqual(navigationController.presentInvokedCount, 1)
        let presentedViewController = try XCTUnwrap(navigationController.lastPresentedViewController as? TWNavigationController)
        XCTAssertTrue(presentedViewController.topViewController === viewController)
    }

    @MainActor
    func test_navigateToURL_givenReceiveAccountInvoicesUrl_thenInvokeDidInvoiceRequestCreationCompleted() {
        let url = URL(string: "https://wise.com/account/invoices/some-payment-request-id")!
        let viewController = WebContentViewController(url: url)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = viewController
        router.showCreateInvoiceOnWeb(
            profileId: ProfileId(1234),
            listUpdateDelegate: listUdpateDelegate
        )

        router.navigateToURL(
            viewController: viewController,
            url: url
        )

        XCTAssertEqual(listUdpateDelegate.invoiceRequestCreatedCallsCount, 1)
    }

    @MainActor
    func test_navigateToURL_givenReceiveRandomUrl_thenNotInvokeDidInvoiceRequestCreationCompleted() {
        let url = URL(string: "https://wise.com/account/some-account-id")!
        let viewController = WebContentViewController(url: url)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = viewController
        router.showCreateInvoiceOnWeb(
            profileId: ProfileId(1234),
            listUpdateDelegate: listUdpateDelegate
        )

        router.navigateToURL(
            viewController: viewController,
            url: url
        )

        XCTAssertEqual(listUdpateDelegate.invoiceRequestCreatedCallsCount, 0)
    }
}
