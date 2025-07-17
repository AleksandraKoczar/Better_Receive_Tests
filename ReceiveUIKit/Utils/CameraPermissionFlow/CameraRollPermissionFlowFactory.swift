import TWFoundation
import UIKit

// sourcery: AutoMockable
protocol CameraRollPermissionFlowFactory {
    func make(
        image: UIImage,
        navigationHost: UIViewController
    ) -> any Flow<CameraRollPermissionFlowResult>
}

struct CameraPermissionFlowFactoryImpl: CameraRollPermissionFlowFactory {
    func make(
        image: UIImage,
        navigationHost: UIViewController
    ) -> any Flow<CameraRollPermissionFlowResult> {
        CameraRollPermissionFlow(
            image: image,
            navigationHost: navigationHost
        )
    }
}
