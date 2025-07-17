import NeptuneTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport

final class InvoiceCreationFlowTests: TWTestCase {
    private var flow: InvoiceCreationFlow!

    private let profile = FakeBusinessProfileInfo().asProfile()
    private var navigationController: MockNavigationController!
    private var userProvider: StubUserProvider!
    private var webViewControllerFactory: WebViewControllerFactoryMock.Type!

    override func setUp() {
        super.setUp()

        navigationController = MockNavigationController()
        userProvider = StubUserProvider()
        webViewControllerFactory = WebViewControllerFactoryMock.self

        flow = InvoiceCreationFlow(
            profile: profile,
            entryPoint: .launchpad,
            navigationController: navigationController,
            webViewControllerFactory: webViewControllerFactory,
            userProvider: userProvider
        )
    }

    override func tearDown() {
        navigationController = nil
        flow = nil
        userProvider = nil
        webViewControllerFactory = nil

        super.tearDown()
    }
}

// MARK: - Start Invoice Flow

extension InvoiceCreationFlowTests {
    func test_startInvoiceFlow() throws {
        let viewController = WebContentViewController(url: Branding.current.url)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = viewController

        flow.start()

        XCTAssertTrue(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationCalled)
        let arguments = try XCTUnwrap(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReceivedArguments)
        XCTAssertEqual(
            arguments.url,
            Branding.current.url.appendingPathComponent("/flows/create-invoice")
        )
        XCTAssertTrue(viewController.isDownloadSupported)
        XCTAssertEqual(navigationController.presentInvokedCount, 1)
        let presentedViewController = try XCTUnwrap(navigationController.lastPresentedViewController as? TWNavigationController)
        XCTAssertTrue(presentedViewController.topViewController === viewController)
    }
}
