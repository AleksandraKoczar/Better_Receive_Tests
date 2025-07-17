import Neptune
import UIKit

// sourcery: AutoMockable
protocol CameraRollPermissionSheetFactory {
    func makeCustomAlertBottomSheet(
        title: String,
        message: String,
        primaryAction: Action
    ) -> UIViewController
}

struct CameraRollPermissionSheetFactoryImpl: CameraRollPermissionSheetFactory {
    public func makeCustomAlertBottomSheet(
        title: String,
        message: String,
        primaryAction: Action
    ) -> UIViewController {
        BottomSheetViewController.makeInfoSheet(viewModel: .init(
            title: title,
            info: .text(message),
            primaryAction: .init(primaryAction)
        ))
    }
}
