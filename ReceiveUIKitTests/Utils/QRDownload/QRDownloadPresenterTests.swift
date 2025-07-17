import Neptune
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport

final class QRDownloadPresenterTests: TWTestCase {
    private let profile = FakePersonalProfileInfo().asProfile()
    private let image = Icons.barChart.image
    private var presenter: QRDownloadPresenter!
    private var router: QRDownloadRouterMock!
    private var view: QRDownloadViewMock!
    private var permissionProvider: CameraRollPermissionProviderMock!

    override func setUp() {
        super.setUp()
        router = QRDownloadRouterMock()
        view = QRDownloadViewMock()
        permissionProvider = CameraRollPermissionProviderMock()
        presenter = QRDownloadPresenterImpl(
            image: image,
            router: router,
            cameraPermissionProvider: permissionProvider
        )
    }

    override func tearDown() {
        presenter = nil
        view = nil
        router = nil
        permissionProvider = nil
        super.tearDown()
    }

    func test_start() throws {
        presenter.start(with: view)
        XCTAssertEqual(view.configureCallsCount, 1)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        let expected = makeViewModel()
        expectNoDifference(viewModel, expected)
    }

    // MARK: - granted permission scenarios

    func test_saveToCameraRollTapped_thenSuccessfullySavedImage() throws {
        permissionProvider.getCameraRollPermissionStateReturnValue = .granted
        permissionProvider.saveImageClosure = { _, completion in
            completion(true)
        }
        presenter.start(with: view)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.cameraDownloadOption.onTap()
        XCTAssertEqual(permissionProvider.saveImageCallsCount, 1)
        XCTAssertEqual(router.showSnackbarCallsCount, 1)
    }

    // MARK: - denied permission scenarios

    func test_permissionIsDenied_startCameraFlow() throws {
        permissionProvider.getCameraRollPermissionStateReturnValue = .denied
        presenter.start(with: view)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.cameraDownloadOption.onTap()
        XCTAssertEqual(router.startCameraPermissionFlowCallsCount, 1)
    }

    // MARK: - unknown permission scenarios

    func test_permissionIsUnknown_UserDenies_thenDismiss() throws {
        permissionProvider.getCameraRollPermissionStateReturnValue = .unknown
        permissionProvider.requestAccessClosure = { completion in
            completion(false)
        }
        presenter.start(with: view)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.cameraDownloadOption.onTap()
        XCTAssertEqual(router.dismissCallsCount, 1)
    }

    func test_permissionIsUnknown_UserAllows_thenSavesImage() throws {
        permissionProvider.getCameraRollPermissionStateReturnValue = .unknown
        permissionProvider.requestAccessClosure = { completion in
            completion(true)
        }
        permissionProvider.saveImageClosure = { _, completion in
            completion(true)
        }
        presenter.start(with: view)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.cameraDownloadOption.onTap()

        XCTAssertEqual(permissionProvider.getCameraRollPermissionStateCallsCount, 1)
        XCTAssertEqual(permissionProvider.requestAccessCallsCount, 1)
        XCTAssertEqual(permissionProvider.saveImageCallsCount, 1)
        XCTAssertEqual(router.showSnackbarCallsCount, 1)
    }

    // MARK: - Save to Files

    func test_saveToFiledTapped_thenOpenDocumentSelection() throws {
        presenter.start(with: view)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.fileDownloadOption.onTap()
        XCTAssertEqual(router.showDocumentPickerCallsCount, 1)
    }
}

// MARK: - Helpers

private extension QRDownloadPresenterTests {
    func makeViewModel() -> QRDownloadViewModel {
        QRDownloadViewModel(
            title: "Download QR code",
            subtitle: "Share or print your Wise QR code to get paid.",
            cameraDownloadOption: makeCameraOption(),
            fileDownloadOption: makeFileOption()
        )
    }

    func makeCameraOption() -> QRDownloadViewModel.Option {
        QRDownloadViewModel.Option(
            viewModel: OptionViewModel(
                title: "Save to Photos",
                avatar: .icon(Icons.image.image)
            ),
            onTap: {}
        )
    }

    func makeFileOption() -> QRDownloadViewModel.Option {
        QRDownloadViewModel.Option(
            viewModel: OptionViewModel(
                title: "Save to Files",
                avatar: .icon(Icons.document.image)
            ),
            onTap: {}
        )
    }
}
