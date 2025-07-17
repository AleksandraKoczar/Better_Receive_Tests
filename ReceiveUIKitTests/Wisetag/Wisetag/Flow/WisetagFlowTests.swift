import DeepLinkKitTestingSupport
import NeptuneTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TravelHubKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport

final class WisetagFlowTests: TWTestCase {
    private let email = "abcd.xyz@transferwise.com"
    private let profile = FakePersonalProfileInfo().asProfile()
    private var flowStarted = false
    private var flowResult: WisetagFlowResult!

    private var flowDispatcher: TestFlowDispatcher!
    private var flow: WisetagFlow!
    private var viewControllerFactory: WisetagViewControllerFactoryMock!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var navigationController: MockNavigationController!
    private var scannedProfileFlowFactory: WisetagScannedProfileFlowFactoryMock!
    private var cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactoryMock!
    private var qrDownloadViewControllerFactory: QRDownloadViewControllerFactoryMock!
    private var scannerFlowFactory: WisetagQRCodeScannerFlowFactoryMock.Type!
    private var accountDetailsFlowFactory: SingleAccountDetailsFlowFactoryMock!
    private var dismisser: FakeViewControllerDismisser!
    private var allDeepLinksUIFactory: AllDeepLinksUIFactoryMock!

    override func setUp() {
        super.setUp()
        viewControllerFactory = WisetagViewControllerFactoryMock()
        qrDownloadViewControllerFactory = QRDownloadViewControllerFactoryMock()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        navigationController = MockNavigationController()
        scannedProfileFlowFactory = WisetagScannedProfileFlowFactoryMock()
        accountDetailsFlowFactory = SingleAccountDetailsFlowFactoryMock()
        cameraRollPermissionFlowFactory = CameraRollPermissionFlowFactoryMock()
        scannerFlowFactory = WisetagQRCodeScannerFlowFactoryMock.self
        dismisser = FakeViewControllerDismisser()
        allDeepLinksUIFactory = AllDeepLinksUIFactoryMock()
        flowDispatcher = TestFlowDispatcher()

        flow = WisetagFlow(
            shouldBecomeDiscoverable: false,
            profile: profile,
            viewControllerFactory: viewControllerFactory,
            qrDownloadViewControllerFactory: qrDownloadViewControllerFactory,
            scannerFlowFactory: scannerFlowFactory,
            allDeepLinksUIFactory: allDeepLinksUIFactory,
            scannedProfileFlowFactory: scannedProfileFlowFactory,
            accountDetailsFlowFactory: accountDetailsFlowFactory,
            viewControllerPresenterFactory: viewControllerPresenterFactory,
            cameraRollPermissionFlowFactory: cameraRollPermissionFlowFactory,
            navigationController: navigationController,
            flowPresenter: .test(with: flowDispatcher)
        )
        flow.onStart { self.flowStarted = true }
        flow.onFinish { result, _ in self.flowResult = result }
    }

    override func tearDown() {
        flowStarted = false
        flowResult = nil
        flow = nil
        flowDispatcher = nil
        viewControllerFactory = nil
        allDeepLinksUIFactory = nil
        viewControllerPresenterFactory = nil
        navigationController = nil
        scannedProfileFlowFactory = nil
        scannerFlowFactory = nil
        qrDownloadViewControllerFactory = nil

        super.tearDown()
    }

    func test_start_givenEligibleForWisetag() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makeWisetagReturnValue = (viewController, WisetagShareableLinkStatusUpdaterMock())

        flow.start()

        let pushPresenter = viewControllerPresenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertTrue(pushPresenter.presentedViewController === viewController)
        XCTAssertTrue(flowStarted)
        let arguments = try XCTUnwrap(viewControllerFactory.makeWisetagReceivedArguments)
        XCTAssertFalse(arguments.shouldBecomeDiscoverable)
    }

    func test_start_givenIneligibleForWisetag_thenStartADFlow() throws {
        let accountDetailsFlow = MockFlow<AccountDetailsFlowResult>()
        accountDetailsFlowFactory.makeReturnValue = accountDetailsFlow
        flow.startAccountDetailsFlow(host: UIViewControllerMock())

        XCTAssertEqual(accountDetailsFlowFactory.makeCallsCount, 1)
        XCTAssertTrue(accountDetailsFlow.startCalled)

        accountDetailsFlow.flowHandler.flowFinished(
            result: .interrupted,
            dismisser: dismisser
        )

        XCTAssertTrue(dismisser.dismissCalled)
    }

    func test_terminate() {
        flow.terminate()
        XCTAssertEqual(flowResult, .abort)
    }

    func test_showWisetagLearnMore() {
        let viewController = ViewControllerMock()
        viewControllerFactory.makeWisetagLearnMoreReturnValue = viewController

        let route = DeepLinkStoryRouteMock()
        flow.showWisetagLearnMore(route: route)

        let bottomSheetPresenter = viewControllerPresenterFactory.bottomSheetPresenter
        XCTAssertTrue(bottomSheetPresenter.presentCalled)
        XCTAssertTrue(bottomSheetPresenter.presentedViewController === viewController)
    }

    func test_showStory_givenValidDeeplink() {
        allDeepLinksUIFactory.buildReturnValue = MockFlow<Void>()
        let route = DeepLinkStoryRouteMock()
        flow.showStory(route: route)
        XCTAssertTrue(
            allDeepLinksUIFactory.buildCalled
        )
    }

    func test_showContactOnWise() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makeContactOnWiseReturnValue = viewController

        let nickname = LoremIpsum.veryShort
        flow.showContactOnWise(nickname: nickname)

        let bottomSheetPresenter = viewControllerPresenterFactory.bottomSheetPresenter
        XCTAssertTrue(bottomSheetPresenter.presentCalled)
        XCTAssertTrue(bottomSheetPresenter.presentedViewController === viewController)
        let arguments = try XCTUnwrap(viewControllerFactory.makeContactOnWiseReceivedArguments)
        XCTAssertEqual(arguments.nickname, nickname)
    }

    func test_dismiss_givenShareableLinkIsDiscoverable_thenFlowFinish() throws {
        flow.dismiss(isShareableLinkDiscoverable: true)

        XCTAssertEqual(flowResult, .completed(isShareableLinkDiscoverable: true))
    }

    func test_dismiss_givenShareableLinkIsNotDiscoverable_thenFlowFinish() throws {
        flow.dismiss(isShareableLinkDiscoverable: false)

        XCTAssertEqual(flowResult, .completed(isShareableLinkDiscoverable: false))
    }

    func test_showScanner_thenDismissScanner_AndReturnRoute() throws {
        viewControllerFactory.makeWisetagReturnValue = (
            ViewControllerMock(),
            WisetagShareableLinkStatusUpdaterMock()
        )
        flow.start()

        let mockFlow = MockFlow<WisetagQRCodeResultType>()
        scannerFlowFactory.makeReturnValue = mockFlow

        flow.showScanQRcode()

        let mockDismisser = FakeViewControllerDismisser()

        mockFlow.flowHandler.flowFinished(result: .route(DeepLinkRouteMock()), dismisser: mockDismisser)

        XCTAssertEqual(scannerFlowFactory.makeCallsCount, 1)
        XCTAssertTrue(mockFlow.startCalled)
        XCTAssertTrue(mockDismisser.dismissCalled)
    }

    func test_showScanner_thenDismissScanner_ReturnRoute_AndShowScannedProfile() throws {
        let mockFlow = MockFlow<WisetagQRCodeResultType>()
        scannerFlowFactory.makeReturnValue = mockFlow

        let anotherMockFlow = MockFlow<Void>()
        scannedProfileFlowFactory.makeFlowReturnValue = anotherMockFlow

        flow.showScanQRcode()

        let mockDismisser = FakeViewControllerDismisser()

        let deepLink = DeepLinkWisetagScannedProfileRouteMock()
        deepLink.source = "pay/me/aleksandraa"
        let result = WisetagQRCodeResultType.route(deepLink)

        mockFlow.flowHandler.flowFinished(result: result, dismisser: mockDismisser)

        XCTAssertEqual(scannerFlowFactory.makeCallsCount, 3)
        XCTAssertTrue(mockFlow.startCalled)
        XCTAssertTrue(mockDismisser.dismissCalled)

        XCTAssertEqual(scannedProfileFlowFactory.makeFlowCallsCount, 1)
        XCTAssertTrue(anotherMockFlow.startCalled)
    }

    func test_showScanner_thenDismissScanner_ReturnIncorrectRoute_AndStop() throws {
        let mockFlow = MockFlow<WisetagQRCodeResultType>()
        scannerFlowFactory.makeReturnValue = mockFlow

        let anotherMockFlow = MockFlow<Void>()
        scannedProfileFlowFactory.makeFlowReturnValue = anotherMockFlow

        flow.showScanQRcode()

        let mockDismisser = FakeViewControllerDismisser()

        let deepLink = DeepLinkRouteMock()
        let result = WisetagQRCodeResultType.route(deepLink)

        mockFlow.flowHandler.flowFinished(result: result, dismisser: mockDismisser)

        XCTAssertEqual(scannerFlowFactory.makeCallsCount, 2)
        XCTAssertTrue(mockFlow.startCalled)
        XCTAssertTrue(mockDismisser.dismissCalled)

        XCTAssertEqual(scannedProfileFlowFactory.makeFlowCallsCount, 0)
        XCTAssertFalse(anotherMockFlow.startCalled)
    }

    func test_dismissAndUpdateShareableLinkStatus_givenIsDiscoverable_thenDismiss() {
        viewControllerFactory.makeWisetagReturnValue = (
            ViewControllerMock(),
            WisetagShareableLinkStatusUpdaterMock()
        )
        flow.start()
        viewControllerFactory.makeContactOnWiseReturnValue = ViewControllerMock()
        flow.showContactOnWise(nickname: LoremIpsum.veryShort)

        flow.dismissAndUpdateShareableLinkStatus(didChangeDiscoverability: true, isDiscoverable: true)

        let bottomSheetDismisser = viewControllerPresenterFactory.bottomSheetPresenter.dismisser
        XCTAssertTrue(bottomSheetDismisser.dismissCalled)
    }

    func test_dismissAndUpdateShareableLinkStatus_givenIsNotDiscoverable_thenDismissAndUpdateStatus() throws {
        let updater = WisetagShareableLinkStatusUpdaterMock()
        viewControllerFactory.makeWisetagReturnValue = (ViewControllerMock(), updater)
        flow.start()
        viewControllerFactory.makeContactOnWiseReturnValue = ViewControllerMock()
        flow.showContactOnWise(nickname: LoremIpsum.veryShort)

        flow.dismissAndUpdateShareableLinkStatus(didChangeDiscoverability: true, isDiscoverable: false)

        let bottomSheetDismisser = viewControllerPresenterFactory.bottomSheetPresenter.dismisser
        XCTAssertTrue(bottomSheetDismisser.dismissCalled)
        let isDiscoverable = try XCTUnwrap(updater.updateShareableLinkStatusReceivedIsDiscoverable)
        XCTAssertFalse(isDiscoverable)
        XCTAssertEqual(updater.updateShareableLinkStatusCallsCount, 1)
    }

    func test_dismissDownload_thenStartCameraPermissionFlow() throws {
        // TODO: how?
    }
}
