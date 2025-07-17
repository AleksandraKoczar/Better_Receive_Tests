import DeepLinkKit
import LoggingKit
import Neptune
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

final class WisetagFlow: Flow {
    var flowHandler: FlowHandler<WisetagFlowResult> = .empty

    let cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactory
    var downloadDismisser: ViewControllerDismisser?
    var cameraRollPermissionFlow: (any Flow<CameraRollPermissionFlowResult>)?
    weak var navigationController: UINavigationController?

    private let shouldBecomeDiscoverable: Bool
    private let profile: Profile
    private let viewControllerFactory: WisetagViewControllerFactory
    private let qrDownloadViewControllerFactory: QRDownloadViewControllerFactory
    private let scannerFlowFactory: WisetagQRCodeScannerFlowFactory.Type
    private let scannedProfileFlowFactory: WisetagScannedProfileFlowFactory
    private let accountDetailsFlowFactory: SingleAccountDetailsFlowFactory
    private let pushPresenter: NavigationViewControllerPresenter
    private let bottomSheetPresenter: BottomSheetPresenter
    private let flowPresenter: FlowPresenter
    private let allDeepLinksUIFactory: AllDeepLinksUIFactory

    private weak var shareableLinkStatusUpdater: WisetagShareableLinkStatusUpdater?
    private var dismisser: ViewControllerDismisser?
    private var contactOnWiseDismisser: ViewControllerDismisser?
    private var scannerFlow: (any Flow<WisetagQRCodeResultType>)?
    private var scannedProfileFlow: (any Flow<Void>)?
    private var accountDetailsFlow: (any Flow<AccountDetailsFlowResult>)?
    private var storyFlow: (any Flow<Void>)?
    private var learnMoreStoryFlow: (any Flow<Void>)?
    private var flowDismisser: ViewControllerDismisser?
    private var learnMoreDismisser: ViewControllerDismisser?

    init(
        shouldBecomeDiscoverable: Bool,
        profile: Profile,
        viewControllerFactory: WisetagViewControllerFactory,
        qrDownloadViewControllerFactory: QRDownloadViewControllerFactory,
        scannerFlowFactory: WisetagQRCodeScannerFlowFactory.Type,
        allDeepLinksUIFactory: AllDeepLinksUIFactory,
        scannedProfileFlowFactory: WisetagScannedProfileFlowFactory,
        accountDetailsFlowFactory: SingleAccountDetailsFlowFactory,
        viewControllerPresenterFactory: ViewControllerPresenterFactory,
        cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactory,
        navigationController: UINavigationController,
        flowPresenter: FlowPresenter = .current
    ) {
        self.shouldBecomeDiscoverable = shouldBecomeDiscoverable
        self.profile = profile
        self.viewControllerFactory = viewControllerFactory
        self.qrDownloadViewControllerFactory = qrDownloadViewControllerFactory
        self.scannerFlowFactory = scannerFlowFactory
        self.allDeepLinksUIFactory = allDeepLinksUIFactory
        self.scannedProfileFlowFactory = scannedProfileFlowFactory
        self.accountDetailsFlowFactory = accountDetailsFlowFactory
        self.navigationController = navigationController
        self.cameraRollPermissionFlowFactory = cameraRollPermissionFlowFactory
        self.flowPresenter = flowPresenter
        pushPresenter = viewControllerPresenterFactory.makePushPresenter(navigationController: navigationController)
        bottomSheetPresenter = viewControllerPresenterFactory.makeBottomSheetPresenter(parent: navigationController)
    }

    func start() {
        let (viewController, shareableLinkStatusUpdater) = viewControllerFactory.makeWisetag(
            shouldBecomeDiscoverable: shouldBecomeDiscoverable,
            profile: profile,
            router: self
        )
        self.shareableLinkStatusUpdater = shareableLinkStatusUpdater
        dismisser = pushPresenter.present(viewController: viewController)
        flowHandler.flowStarted()
    }

    func terminate() {
        flowHandler.flowFinished(result: .abort, dismisser: dismisser)
    }
}

// MARK: - WisetagRouter

extension WisetagFlow: WisetagRouter {
    private enum Constants {
        static let deepLinkContext = Context(source: "Wisetag")
    }

    func showLearnMoreStory(route: DeepLinkStoryRoute) {
        guard let navigationController else {
            softFailure("[REC] Attempt to show story flow when the primary navigation controller is empty.")
            return
        }

        guard let flow = allDeepLinksUIFactory.build(
            for: route,
            hostController: navigationController,
            with: Constants.deepLinkContext
        ) else {
            return
        }

        learnMoreDismisser.dismiss {
            self.learnMoreStoryFlow = flow
            self.flowPresenter.start(flow: flow)
        }
    }

    func showStory(route: DeepLinkStoryRoute) {
        guard let navigationController else {
            softFailure("[REC] Attempt to show story flow when the primary navigation controller is empty.")
            return
        }

        guard let flow = allDeepLinksUIFactory.build(
            for: route,
            hostController: navigationController,
            with: Constants.deepLinkContext
        ) else {
            return
        }

        dismisser?.dismiss(animated: UIView.shouldAnimate)
        storyFlow = flow
        flow.start()
    }

    func startAccountDetailsFlow(host: UIViewController) {
        navigationController?.popViewController(animated: false, completion: { [weak self] in
            guard let self else { return }
            let flow = accountDetailsFlowFactory.make(
                hostViewController: host,
                route: nil,
                invocationContext: .wisetag
            )

            flow.onFinish { [weak self] _, dismisser in
                guard let self else {
                    return
                }
                dismisser?.dismiss()
                accountDetailsFlow = nil
                terminate()
            }
            accountDetailsFlow = flow
            flow.start()
        })
    }

    func showScanQRcode() {
        guard let navigationController else {
            softFailure("[REC] Attempt to show scanner flow when the primary navigation controller is empty.")
            return
        }
        let flow = scannerFlowFactory.make(host: navigationController)
        flow.onFinish { [weak self] result, dismisser in
            dismisser.dismiss {
                self?.handleQRCodeResult(qrCodeScannerResult: result)
            }
            self?.scannerFlow = nil
        }
        scannerFlow = flow
        flow.start()
    }

    func handleQRCodeResult(qrCodeScannerResult: WisetagQRCodeResultType) {
        switch qrCodeScannerResult {
        case let .route(route):
            guard let deepLinkRoute = route as? DeepLinkWisetagScannedProfileRoute else {
                return
            }

            guard let navController = navigationController else {
                softFailure("[REC] Attempt to handle QR code result when the primary navigation controller is empty.")
                return
            }

            let flow = scannedProfileFlowFactory.makeFlow(
                nickname: deepLinkRoute.source,
                profile: profile,
                navigationController: navController
            )

            flow.onFinish { [weak self] _, _ in
                self?.scannedProfileFlow = nil
            }
            scannedProfileFlow = flow
            flow.start()

        case .error:
            softFailure("[REC] Incorrect scanner result")

        case .userCancelled:
            break
        }
    }

    func showWisetagLearnMore(route: DeepLinkStoryRoute) {
        let viewController = viewControllerFactory.makeWisetagLearnMore(router: self, route: route)
        learnMoreDismisser = bottomSheetPresenter.present(viewController: viewController)
    }

    func showContactOnWise(nickname: String?) {
        let viewController = viewControllerFactory.makeContactOnWise(
            nickname: nickname,
            profile: profile,
            router: self
        )
        contactOnWiseDismisser = bottomSheetPresenter.present(viewController: viewController)
    }

    func showDownload(image: UIImage) {
        let viewController = qrDownloadViewControllerFactory.makeDownloadBottomSheet(
            router: self,
            image: image
        )
        downloadDismisser = bottomSheetPresenter.present(viewController: viewController)
    }

    func dismiss(isShareableLinkDiscoverable: Bool) {
        flowHandler.flowFinished(
            result: .completed(isShareableLinkDiscoverable: isShareableLinkDiscoverable),
            dismisser: dismisser
        )
    }
}

// MARK: - WisetagContactOnWiseRouter

extension WisetagFlow: WisetagContactOnWiseRouter {
    func dismissAndUpdateShareableLinkStatus(didChangeDiscoverability: Bool, isDiscoverable: Bool) {
        if !didChangeDiscoverability {
            contactOnWiseDismisser?.dismiss()
            return
        }
        contactOnWiseDismisser?.dismiss { [weak self] in
            self?.shareableLinkStatusUpdater?.updateShareableLinkStatus(isDiscoverable: isDiscoverable)
        }
    }
}

// MARK: - WisetagDownloadRouter

extension WisetagFlow: QRDownloadRouter {}
