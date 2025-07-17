import Neptune
import PhotosUI
import TransferResources
import UserKit

// sourcery: AutoMockable
protocol QRDownloadPresenter: AnyObject {
    func start(with view: QRDownloadView)
}

final class QRDownloadPresenterImpl: NSObject {
    private let image: UIImage
    private let router: QRDownloadRouter
    private let cameraPermissionProvider: CameraRollPermissionProvider

    init(
        image: UIImage,
        router: QRDownloadRouter,
        cameraPermissionProvider: CameraRollPermissionProvider
    ) {
        self.image = image
        self.router = router
        self.cameraPermissionProvider = cameraPermissionProvider
    }
}

extension QRDownloadPresenterImpl: QRDownloadPresenter {
    func start(with view: QRDownloadView) {
        let viewModel = makeViewModel()
        view.configure(with: viewModel)
    }
}

extension QRDownloadPresenterImpl: UIDocumentPickerDelegate {}

private extension QRDownloadPresenterImpl {
    func checkAndConfigureCameraPermission() {
        switch cameraPermissionProvider.getCameraRollPermissionState() {
        case .unknown:
            askForCameraPermission()
        case .denied:
            showDeniedAlert()
        case .granted:
            saveImage()
        }
    }

    func saveImage() {
        cameraPermissionProvider.saveImage(image: image) { [weak self] isSuccess in
            guard let self else {
                return
            }
            if isSuccess {
                router.showSnackbar()
            } else {
                router.dismiss()
            }
        }
    }

    func askForCameraPermission() {
        cameraPermissionProvider.requestAccess { [weak self] isPermissionGranted in
            guard let self else { return }
            if isPermissionGranted {
                saveImage()
            } else {
                router.dismiss()
            }
        }
    }

    func showDeniedAlert() {
        router.startCameraPermissionFlow(image: image) { [weak self] result in
            guard let self else { return }
            if result == .grantedAndSuccessful {
                router.showSnackbar()
            } else {
                router.dismiss()
            }
        }
    }

    func saveToFiles() {
        if let imageURL = convertImageToUrl(image: image, filename: "wise_qrCode.jpg") {
            router.showDocumentPicker(fileURLs: [imageURL], delegate: self)
        }
    }

    func convertImageToUrl(image: UIImage, filename: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileURL = documentsDirectory.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return nil
        }
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }

    func makeCameraDownloadOption() -> QRDownloadViewModel.Option {
        QRDownloadViewModel.Option(
            viewModel: OptionViewModel(title: L10n.Wisetag.DownloadQR.camera, avatar: .icon(Icons.image.image)),
            onTap: { [weak self] in
                guard let self else {
                    return
                }
                checkAndConfigureCameraPermission()
            }
        )
    }

    func makeFileDownloadOption() -> QRDownloadViewModel.Option {
        QRDownloadViewModel.Option(
            viewModel: OptionViewModel(title: L10n.Wisetag.DownloadQR.file, avatar: .icon(Icons.document.image)),
            onTap: { [weak self] in
                guard let self else {
                    return
                }
                saveToFiles()
            }
        )
    }

    func makeViewModel() -> QRDownloadViewModel {
        QRDownloadViewModel(
            title: L10n.Wisetag.DownloadQR.title,
            subtitle: L10n.Wisetag.DownloadQR.subtitle,
            cameraDownloadOption: makeCameraDownloadOption(),
            fileDownloadOption: makeFileDownloadOption()
        )
    }
}
