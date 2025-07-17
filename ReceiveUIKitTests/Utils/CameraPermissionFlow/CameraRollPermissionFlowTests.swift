import NeptuneTestingSupport
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import WiseAtomsAssets

@MainActor
final class CameraRollPermissionFlowTests: TWTestCase {
    private var flow: CameraRollPermissionFlow!
    private var navigationHost: UIViewControllerMock!
    private var urlOpener: UrlOpenerMock!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var flowHandlerHelper: FlowHandlerHelper<CameraRollPermissionFlowResult>!
    private var customAlert: CameraRollPermissionSheetFactory!
    private var permissionSheetFactory: CameraRollPermissionSheetFactoryMock!

    override func setUp() {
        super.setUp()
        navigationHost = UIViewControllerMock()
        urlOpener = UrlOpenerMock()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        permissionSheetFactory = CameraRollPermissionSheetFactoryMock()
        flow = CameraRollPermissionFlow(
            image: UIImage(),
            navigationHost: navigationHost,
            urlOpener: urlOpener,
            viewControllerPresenterFactory: viewControllerPresenterFactory,
            permissionSheetFactory: permissionSheetFactory
        )
        flowHandlerHelper = FlowHandlerHelper<CameraRollPermissionFlowResult>()
        flow.flowHandler = flowHandlerHelper.flowHandler
    }

    override func tearDown() {
        flow = nil
        navigationHost = nil
        urlOpener = nil
        viewControllerPresenterFactory = nil
        flowHandlerHelper = nil
        super.tearDown()
    }

    // MARK: - denied permission scenarios

    func test_whenUserTapsOnPrimaryActionOfDeniedAlert_itOpensSettings() throws {
        showDeniedAlert()

        try tapOnPrimaryActionOfDeniedAlert()

        XCTAssertEqual(urlOpener.openCallsCount, 1)
        XCTAssertEqual(urlOpener.openReceivedArguments?.url, URL(string: "app-settings:"))
        XCTAssertEqual(urlOpener.openReceivedArguments?.options.isEmpty, true)
    }

    func test_whenUserCancelsDeniedAlert_itFinishesTheFlow() throws {
        showDeniedAlert()

        viewControllerPresenterFactory.bottomSheetPresenter.dismisser.dismiss()

        XCTAssertEqual(flowHandlerHelper.flowFinishedCallsCount, 1)
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .userCancelled)
    }
}

// MARK: - Helpers

private extension CameraRollPermissionFlowTests {
    func showDeniedAlert(file: StaticString = #file, line: UInt = #line) {
        permissionSheetFactory.makeCustomAlertBottomSheetReturnValue = ViewControllerMock()
        flow.start()
    }

    func tapOnPrimaryActionOfDeniedAlert(file: StaticString = #file, line: UInt = #line) throws {
        let arguments = try XCTUnwrap(
            permissionSheetFactory.makeCustomAlertBottomSheetReceivedArguments
        )

        let primaryAction = try XCTUnwrap(
            arguments.primaryAction
        )
        primaryAction.handler()
    }
}
