import Foundation
import NeptuneTestingSupport
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWTestingSupportKit
import TWUITestingSupport
import UIKit

final class ReceiveMethodsQRSharingRouterTests: TWTestCase {
    private var router: ReceiveMethodsQRSharingRouterImpl!
    private var viewControllerFactory: ReceiveMethodQRSharingViewControllerFactoryMock!
    private var cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactoryMock!
    private var qrDownloadViewControllerFactory: QRDownloadViewControllerFactoryMock!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var navigationController: MockNavigationController!

    override func setUp() {
        super.setUp()

        navigationController = MockNavigationController()
        viewControllerFactory = ReceiveMethodQRSharingViewControllerFactoryMock()
        cameraRollPermissionFlowFactory = CameraRollPermissionFlowFactoryMock()
        qrDownloadViewControllerFactory = QRDownloadViewControllerFactoryMock()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()

        router = ReceiveMethodsQRSharingRouterImpl(
            navigationController: navigationController,
            viewControllerFactory: viewControllerFactory,
            cameraRollPermissionFlowFactory: cameraRollPermissionFlowFactory,
            qrDownloadViewControllerFactory: qrDownloadViewControllerFactory,
            viewControllerPresenterFactory: viewControllerPresenterFactory
        )
    }

    override func tearDown() {
        router = nil
        viewControllerFactory = nil
        cameraRollPermissionFlowFactory = nil
        qrDownloadViewControllerFactory = nil
        viewControllerPresenterFactory = nil
        navigationController = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension ReceiveMethodsQRSharingRouterTests {
    func testDownload_WhenDownloadCalled_ThenCorrectValuesPassed() {
        let image = UIImage()
        let viewController = UIViewController()
        qrDownloadViewControllerFactory.makeDownloadBottomSheetReturnValue = UIViewController()
        router.showDownload(image: image, viewController: viewController)

        XCTAssertEqual(qrDownloadViewControllerFactory.makeDownloadBottomSheetReceivedArguments?.image, image)
        XCTAssertTrue(viewControllerPresenterFactory.makeBottomSheetPresenterCalled)
    }

    func testDownload_WhenShowCustomisationCalled_ThenCorrectValuesPassed() {
        router.showCustomisation(
            alias: .canned,
            accountDetailsId: .canned,
            profileId: .canned
        )

        XCTAssertTrue(viewControllerPresenterFactory.makePushPresenterCalled)
    }
}
