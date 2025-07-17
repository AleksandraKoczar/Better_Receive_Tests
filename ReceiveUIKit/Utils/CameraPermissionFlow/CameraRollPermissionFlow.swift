import AnalyticsKit
import LoggingKit
import Neptune
import TransferResources
import TWFoundation
import TWUI

enum CameraRollPermissionFlowResult {
    case denied
    case grantedAndSuccessful
    case grantedAndUnsuccessful
    case userCancelled
}

final class CameraRollPermissionFlow: Flow {
    var flowHandler: FlowHandler<CameraRollPermissionFlowResult> = .empty
    private var dismisser: ViewControllerDismisser?
    private var isBottomSheetProgrammaticallyDismissed = false
    private let navigationHost: UIViewController
    private let urlOpener: UrlOpener
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory
    private let permissionSheetFactory: CameraRollPermissionSheetFactory
    private let image: UIImage

    init(
        image: UIImage,
        navigationHost: UIViewController,
        urlOpener: UrlOpener = UIApplication.shared,
        cameraRollPermissionProvider: CameraRollPermissionProvider = CameraRollPermissionProviderImpl(),
        viewControllerPresenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl(),
        permissionSheetFactory: CameraRollPermissionSheetFactory = CameraRollPermissionSheetFactoryImpl()
    ) {
        self.image = image
        self.navigationHost = navigationHost
        self.urlOpener = urlOpener
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
        self.permissionSheetFactory = permissionSheetFactory
    }

    func start() {
        showDeniedAlert()
        flowHandler.flowStarted()
    }

    func terminate() {
        flowHandler.flowFinished(result: .userCancelled, dismisser: dismisser)
    }
}

private extension CameraRollPermissionFlow {
    func showDeniedAlert() {
        let alert = makeDeniedAlert()
        presentBottomSheet(alert) { [weak self] in
            guard let self else { return }
            flowHandler.flowFinished(result: .userCancelled, dismisser: dismisser)
        }
    }

    func makeDeniedAlert() -> UIViewController {
        permissionSheetFactory.makeCustomAlertBottomSheet(
            title: L10n.Wisetag.DownloadQR.Camera.Denied.title,
            message: L10n.Wisetag.DownloadQR.Camera.Denied.subtitle,
            primaryAction: .init(
                title: L10n.Wisetag.DownloadQR.Camera.Denied.cta,
                handler: { [weak self] in
                    self?.openSettings()
                }
            )
        )
    }

    func presentBottomSheet(_ viewController: UIViewController, onDismiss: @escaping () -> Void) {
        let bottomSheetPresenter = viewControllerPresenterFactory.makeBottomSheetPresenter(
            parent: navigationHost
        )
        var bottomSheetDismisser = bottomSheetPresenter.present(
            viewController: viewController,
            completion: nil
        )
        bottomSheetDismisser.onDismiss = onDismiss
        dismisser = bottomSheetDismisser
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        urlOpener.open(url, options: [:], completionHandler: nil)
    }
}
