import Foundation
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol ReceiveMethodsQRSharingRouter: AnyObject {
    func showDownload(
        image: UIImage,
        viewController: UIViewController
    )
    func showCustomisation(
        alias: ReceiveMethodAlias,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId
    )
}

final class ReceiveMethodsQRSharingRouterImpl {
    var navigationController: UINavigationController? {
        _navigationController
    }

    let cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactory

    var downloadDismisser: ViewControllerDismisser?
    var cameraRollPermissionFlow: (any Flow<CameraRollPermissionFlowResult>)?

    private let _navigationController: UINavigationController
    private let viewControllerFactory: ReceiveMethodQRSharingViewControllerFactory
    private let qrDownloadViewControllerFactory: QRDownloadViewControllerFactory
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory

    private var customisationDismisser: ViewControllerDismisser?
    private var pushPresenter: NavigationViewControllerPresenter?

    init(
        navigationController: UINavigationController,
        viewControllerFactory: ReceiveMethodQRSharingViewControllerFactory = ReceiveMethodQRSharingViewControllerFactoryImpl(),
        cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactory = CameraPermissionFlowFactoryImpl(),
        qrDownloadViewControllerFactory: QRDownloadViewControllerFactory = QRDownloadViewControllerFactoryImpl(),
        viewControllerPresenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl()
    ) {
        _navigationController = navigationController
        self.viewControllerFactory = viewControllerFactory
        self.cameraRollPermissionFlowFactory = cameraRollPermissionFlowFactory
        self.qrDownloadViewControllerFactory = qrDownloadViewControllerFactory
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
    }
}

extension ReceiveMethodsQRSharingRouterImpl: ReceiveMethodsQRSharingRouter {
    func showDownload(
        image: UIImage,
        viewController: UIViewController
    ) {
        let downloadViewController = qrDownloadViewControllerFactory.makeDownloadBottomSheet(
            router: self,
            image: image
        )
        let bottomSheetPresenter = viewControllerPresenterFactory.makeBottomSheetPresenter(
            parent: viewController
        )
        downloadDismisser = bottomSheetPresenter.present(
            viewController: downloadViewController
        )
    }

    func showCustomisation(
        alias: ReceiveMethodAlias,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId
    ) {
        let viewModel = ReceiveMethodsQRSharingCustomizationViewModel(
            alias: alias,
            accountDetailsId: accountDetailsId,
            profileId: profileId,
            delegate: self
        )
        pushPresenter = viewControllerPresenterFactory
            .makePushPresenter(navigationController: _navigationController)
        customisationDismisser = pushPresenter?
            .present(
                view: {
                    ReceiveMethodsQRSharingCustomizationView(viewModel: viewModel)
                }
            )
    }
}

extension ReceiveMethodsQRSharingRouterImpl: QRDownloadRouter {}

extension ReceiveMethodsQRSharingRouterImpl: ReceiveMethodsQRSharingCustomizationDelegate {
    func customize(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        result: ReceiveMethodsQRSharingCustomizationResult
    ) {
        switch result {
        case .cancelled:
            customisationDismisser?.dismiss()
        case let .customized(model):
            let viewController = viewControllerFactory.make(
                accountDetailsId: accountDetailsId,
                profileId: profileId,
                mode: .single(model),
                navigationController: _navigationController
            )
            pushPresenter?.keepOnlyLastViewControllerOnStack = true
            pushPresenter?.present(viewController: viewController)
        }
    }
}
