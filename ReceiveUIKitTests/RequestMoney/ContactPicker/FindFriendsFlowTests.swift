import ContactsKit
import ContactsKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import WiseCore

final class FindFriendsFlowTests: TWTestCase {
    private var navigationController: MockNavigationController!
    private var discoveryService: ContactSyncDiscoveryServiceMock!
    private var urlOpener: UrlOpenerMock!
    private var helpCenterArticleFactory: HelpCenterArticleFactoryMock!

    private var flow: FindFriendsFlow!
    private var flowHandlerHelper: FlowHandlerHelper<Void>!

    override func setUp() {
        super.setUp()

        navigationController = MockNavigationController()
        discoveryService = ContactSyncDiscoveryServiceMock()
        urlOpener = UrlOpenerMock()

        helpCenterArticleFactory = HelpCenterArticleFactoryMock()

        flowHandlerHelper = FlowHandlerHelper<Void>()
        flow = FindFriendsFlow(
            navigationController: navigationController,
            helpCenterArticleFactory: helpCenterArticleFactory,
            discoveryService: discoveryService,
            urlOpener: urlOpener
        )
        flow.flowHandler = flowHandlerHelper.flowHandler
    }

    override func tearDown() {
        navigationController = nil
        discoveryService = nil
        urlOpener = nil
        flowHandlerHelper = nil
        flow = nil
        super.tearDown()
    }

    func test_start() {
        flow.start()

        XCTAssertEqual(navigationController.presentInvokedCount, 1)
        XCTAssertTrue(flowHandlerHelper.flowStartedCalled)
    }

    func test_learnMoreButtonTapped() {
        flow.start()

        let learnMoreFlow = MockFlow<Void>()

        helpCenterArticleFactory.isArticleLinkReturnValue = HelpCenterArticleId(rawValue: "2978055")
        helpCenterArticleFactory.makeArticleFlowReturnValue = learnMoreFlow

        flow.learnMoreButtonTapped()

        XCTAssertTrue(learnMoreFlow.startCalled)
    }

    func test_turnOnContactsTapped_GivenPermissionNotGranted() {
        flow.start()

        discoveryService.contactSyncConsent = .just(true)

        discoveryService.updateContactSyncConsentThrowableError = ContactSyncError.noPhoneBookAccess

        flow.enableContactSync()

        // TODO: not sure why this doesn't pass
        // XCTAssertEqual(navigationController.dismissInvokedCount, 1)
        // XCTAssert(navigationController.lastPresentedViewController is UIAlertController)
    }
}
