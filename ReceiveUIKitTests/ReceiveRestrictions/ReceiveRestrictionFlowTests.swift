import DeepLinkKit
import DeepLinkKitTestingSupport
import Neptune
import NeptuneTestingSupport
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import UIKit
import WiseCore

final class ReceiveRestrictionFlowTests: TWTestCase {
    private var flow: ReceiveRestrictionFlow!
    private var urlOpener: UrlOpenerMock!
    private var navigationController: MockNavigationController!
    private var allDeepLinksUIFactory: AllDeepLinksUIFactoryMock!
    private var deeplinkRouteFactory: DeepLinkRouteFactoryMock!
    private var flowDispatcher: TestFlowDispatcher!
    private var viewControllerFactory: ReceiveRestrictionViewControllerFactoryMock!

    override func setUp() {
        super.setUp()

        navigationController = MockNavigationController()
        allDeepLinksUIFactory = AllDeepLinksUIFactoryMock()
        deeplinkRouteFactory = DeepLinkRouteFactoryMock()
        urlOpener = UrlOpenerMock()
        flowDispatcher = TestFlowDispatcher()
        viewControllerFactory = ReceiveRestrictionViewControllerFactoryMock()

        flow = ReceiveRestrictionFlow(
            context: .restricted,
            profileId: ProfileId(123),
            navigationController: navigationController,
            viewControllerFactory: viewControllerFactory,
            viewControllerPresenterFactory: FakeViewControllerPresenterFactory(),
            allDeepLinksUIFactory: allDeepLinksUIFactory,
            deeplinkRouteFactory: deeplinkRouteFactory,
            urlOpener: urlOpener,
            flowPresenter: .test(with: flowDispatcher)
        )
    }

    override func tearDown() {
        flow = nil
        flowDispatcher = nil
        urlOpener = nil
        navigationController = nil
        allDeepLinksUIFactory = nil
        deeplinkRouteFactory = nil
        flowDispatcher = nil
        viewControllerFactory = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension ReceiveRestrictionFlowTests {
    func testURIHandling_GivenURL_ThenItWasTriedToOpen() throws {
        let url = try XCTUnwrap(URL(string: "https://asdasdsa.com"))
        let uri = URI.url(url)

        flow.handleURI(uri)

        XCTAssertEqual(
            deeplinkRouteFactory.makeRouteReceivedUri,
            uri
        )
        XCTAssertEqual(
            urlOpener.openReceivedArguments?.url,
            url
        )
    }

    func testURIHandling_GivenURN_ThenItWasTriedToBeHandled() throws {
        let urn = try XCTUnwrap(URN("urn:wise:do:sth"))
        let uri = URI.urn(urn)
        let route = DeepLinkRouteMock()
        let mockFlow = MockFlow<Void>()

        allDeepLinksUIFactory.buildReturnValue = mockFlow
        deeplinkRouteFactory.makeRouteReturnValue = route
        flow.handleURI(uri)

        XCTAssertEqual(
            deeplinkRouteFactory.makeRouteReceivedUri,
            uri
        )
        XCTAssertFalse(urlOpener.openCalled)
        XCTAssertTrue(allDeepLinksUIFactory.buildReceivedArguments?.route is DeepLinkRouteMock)
        XCTAssertTrue(flowDispatcher.lastFlowPresented is MockFlow<Void>)
    }

    func testDismiss_WhenDismissCalled_ThenFlowFinished() {
        viewControllerFactory.makeReturnValue = UIViewController()

        var dismissResult: Void?
        flow.onFinish { result, _ in
            dismissResult = result
        }

        flow.start()
        flow.dismiss()

        XCTAssertNotNil(dismissResult)
    }
}
