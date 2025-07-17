import AnalyticsKit
import AnalyticsKitTestingSupport
import Neptune
import NeptuneTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import UIKit
import UserKit
import UserKitTestingSupport

final class GetPaidOptionsFlowTests: TWTestCase {
    private var flow: GetPaidOptionsFlow!
    private var navigationController: MockNavigationController!
    private var webViewControllerFactory: WebViewControllerFactoryMock.Type!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var requestMoneyFlowFactory: RequestMoneyFlowFactoryMock!
    private var userProvider: StubUserProvider!
    private var analyticsTracker: StubAnalyticsTracker!
    private var delegate: GetPaidOptionsRoutingDelegateMock!

    override func setUp() {
        super.setUp()

        analyticsTracker = StubAnalyticsTracker()
        navigationController = MockNavigationController()
        webViewControllerFactory = WebViewControllerFactoryMock.self
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        requestMoneyFlowFactory = RequestMoneyFlowFactoryMock()
        userProvider = StubUserProvider()
        delegate = GetPaidOptionsRoutingDelegateMock()

        flow = GetPaidOptionsFlow(
            profile: FakePersonalProfileInfo().asProfile(),
            navigationController: navigationController,
            requestMoneyFlowFactory: requestMoneyFlowFactory,
            webViewControllerFactory: webViewControllerFactory,
            viewControllerPresenterFactory: viewControllerPresenterFactory,
            userProvider: userProvider,
            analyticsTracker: analyticsTracker
        )
    }

    override func tearDown() {
        requestMoneyFlowFactory = nil
        navigationController = nil
        viewControllerPresenterFactory = nil
        webViewControllerFactory = nil
        analyticsTracker = nil
        flow = nil

        super.tearDown()
    }

    func test_start_thenShowGetPaidViewController() {
        flow.start()

        let bottomSheetPresenter = viewControllerPresenterFactory.bottomSheetPresenter
        XCTAssertTrue(bottomSheetPresenter.presentCalled)
        XCTAssertTrue(bottomSheetPresenter.presentedViewController is GetPaidOptionsBottomSheetViewController)
    }

    func test_start_thenStartRequestMoneyFlow() throws {
        requestMoneyFlowFactory.makeModalForLaunchpadFactoryReturnValue = MockFlow<Void>()

        flow.start()
        flow.didSelectGetPaidOption(.requestMoney)

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Launchpad - Dropdown - Create Payment Link CTA"
        )
        XCTAssertTrue(requestMoneyFlowFactory.makeModalForLaunchpadFactoryCalled)
    }

    func test_start_thenStartInvoiceCreationFlow() {
        let webViewController = WebContentViewController(url: URL(string: "https://abc.com")!)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = webViewController

        flow.start()
        flow.didSelectGetPaidOption(.createInvoice)

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Launchpad - Dropdown - Create Invoice CTA"
        )
        let expectedUrl = URL(string: "https://wise.com/flows/create-invoice")
        let receivedArguments = webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReceivedArguments
        XCTAssertEqual(receivedArguments?.url, expectedUrl)
        XCTAssertTrue(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationCalled)
    }
}
