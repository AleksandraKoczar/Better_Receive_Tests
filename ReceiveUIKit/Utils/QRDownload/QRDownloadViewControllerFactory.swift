import Foundation
import UIKit

// sourcery: AutoMockable
protocol QRDownloadViewControllerFactory {
    func makeDownloadBottomSheet(
        router: QRDownloadRouter,
        image: UIImage
    ) -> UIViewController
}

struct QRDownloadViewControllerFactoryImpl: QRDownloadViewControllerFactory {
    func makeDownloadBottomSheet(
        router: QRDownloadRouter,
        image: UIImage
    ) -> UIViewController {
        let presenter = QRDownloadPresenterImpl(
            image: image,
            router: router,
            cameraPermissionProvider: CameraRollPermissionProviderImpl()
        )
        return QRDownloadBottomSheetViewController(presenter: presenter)
    }
}
