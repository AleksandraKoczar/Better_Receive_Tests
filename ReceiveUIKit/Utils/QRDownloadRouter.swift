import Foundation
import LoggingKit
import MacrosKit
import Neptune
import TransferResources
import TWFoundation
import UIKit

@Mock
protocol QRDownloadRouter: AnyObject {
    var downloadDismisser: ViewControllerDismisser? { get set }
    var navigationController: UINavigationController? { get }
    var cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactory { get }
    var cameraRollPermissionFlow: (any Flow<CameraRollPermissionFlowResult>)? { get set }

    func startCameraPermissionFlow(
        image: UIImage,
        completion: @escaping (CameraRollPermissionFlowResult) -> Void
    )
    func showDocumentPicker(fileURLs: [URL], delegate: UIDocumentPickerDelegate)
    func showSnackbar()
    func dismiss()
}

extension QRDownloadRouter {
    func showSnackbar() {
        downloadDismisser?.dismiss { [weak self] in
            guard let self else { return }
            guard let view = navigationController?.view else {
                softFailure("[REC] Attempt to show wisetag download snackbar with empty view.")
                return
            }
            let configuration = SnackBarConfiguration(
                message: L10n.Wisetag.DownloadQR.Snackbar.Camera.title
            )
            let snackBar = SnackBarView(configuration: configuration)
            snackBar.show(with: SnackBarBottomPosition(superview: view))
        }
    }

    func startCameraPermissionFlow(
        image: UIImage,
        completion: @escaping (CameraRollPermissionFlowResult) -> Void
    ) {
        downloadDismisser?.dismiss { [weak self] in
            guard let self else { return }
            guard let navigationController else {
                softFailure("[REC] Attempt to show scanner flow when the primary navigation controller is empty.")
                return
            }

            let flow = cameraRollPermissionFlowFactory.make(image: image, navigationHost: navigationController)

            flow.onFinish { [weak self] result, dismisser in
                guard let self else { return }
                cameraRollPermissionFlow = nil
                dismisser.dismiss {
                    if result == .grantedAndSuccessful { self.showSnackbar() }
                }
            }
            cameraRollPermissionFlow = flow
            flow.start()
        }
    }

    func dismiss() {
        downloadDismisser?.dismiss()
    }

    func showDocumentPicker(fileURLs: [URL], delegate: UIDocumentPickerDelegate) {
        downloadDismisser?.dismiss { [weak self] in
            guard let self else { return }
            let documentPicker = UIDocumentPickerViewController(forExporting: fileURLs)
            documentPicker.delegate = delegate
            navigationController?.present(documentPicker, animated: UIView.shouldAnimate)
        }
    }
}
