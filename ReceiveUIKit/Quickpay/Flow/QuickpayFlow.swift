import DeepLinkKit
import DynamicFlow
import LoggingKit
import Neptune
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

final class QuickpayFlow: Flow {
    let cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactory
    var flowHandler: FlowHandler<QuickpayFlowResult> = .empty
    var cameraRollPermissionFlow: (any Flow<CameraRollPermissionFlowResult>)?
    var downloadDismisser: ViewControllerDismisser?

    weak var navigationController: UINavigationController?
    private let pushPresenter: NavigationViewControllerPresenter
    private let bottomSheetPresenter: BottomSheetPresenter
    private let profile: Profile
    private let viewControllerFactory: WisetagViewControllerFactory
    private let qrDownloadViewControllerFactory: QRDownloadViewControllerFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let flowPresenter: FlowPresenter
    private let allDeepLinksUIFactory: AllDeepLinksUIFactory
    private let accountDetailsFlowFactory: SingleAccountDetailsFlowFactory
    private let pasteboard: Pasteboard
    private let userProvider: UserProvider
    private let featureService: FeatureService
    private let feedbackFlowFactory: AutoSubmittingFeedbackFlowFactory
    private let feedbackService: FeedbackService
    private let paymentMethodsDynamicFlowHandler: PaymentMethodsDynamicFlowHandler

    private var dismisser: ViewControllerDismisser?
    private var storyFlow: (any Flow<Void>)?
    private var discoverabilityDismisser: ViewControllerDismisser?
    private var learnMoreDismisser: ViewControllerDismisser?
    private var shareSheetDismisser: ViewControllerDismisser?
    private var manageQuickpayDismisser: ViewControllerDismisser?
    private var accountDetailsFlow: (any Flow<AccountDetailsFlowResult>)?
    private var activeFeedbackFlow: (any Flow<AutoSubmittingFeedbackFlowResult>)?

    private weak var shareableLinkStatusUpdater: QuickpayShareableLinkStatusUpdater?
    private weak var shareableLinkStatusUpdaterForInPerson: QuickpayShareableLinkStatusUpdater?

    init(
        profile: Profile,
        userProvider: UserProvider = GOS[UserProviderKey.self],
        featureService: FeatureService = GOS[FeatureServiceKey.self],
        viewControllerFactory: WisetagViewControllerFactory,
        qrDownloadViewControllerFactory: QRDownloadViewControllerFactory,
        viewControllerPresenterFactory: ViewControllerPresenterFactory,
        feedbackFlowFactory: AutoSubmittingFeedbackFlowFactory,
        paymentMethodsDynamicFlowHandler: PaymentMethodsDynamicFlowHandler,
        feedbackService: FeedbackService,
        accountDetailsFlowFactory: SingleAccountDetailsFlowFactory,
        webViewControllerFactory: WebViewControllerFactory.Type,
        navigationController: UINavigationController,
        allDeepLinksUIFactory: AllDeepLinksUIFactory,
        cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactory,
        pasteboard: Pasteboard = UIPasteboard.general,
        flowPresenter: FlowPresenter = .current
    ) {
        self.profile = profile
        self.userProvider = userProvider
        self.featureService = featureService
        self.viewControllerFactory = viewControllerFactory
        self.feedbackFlowFactory = feedbackFlowFactory
        self.paymentMethodsDynamicFlowHandler = paymentMethodsDynamicFlowHandler
        self.feedbackService = feedbackService
        self.qrDownloadViewControllerFactory = qrDownloadViewControllerFactory
        self.accountDetailsFlowFactory = accountDetailsFlowFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.navigationController = navigationController
        self.allDeepLinksUIFactory = allDeepLinksUIFactory
        self.cameraRollPermissionFlowFactory = cameraRollPermissionFlowFactory
        self.pasteboard = pasteboard
        self.flowPresenter = flowPresenter
        pushPresenter = viewControllerPresenterFactory.makePushPresenter(navigationController: navigationController)
        bottomSheetPresenter = viewControllerPresenterFactory.makeBottomSheetPresenter(parent: navigationController)
    }

    func start() {
        let (viewController, shareableLinkStatusUpdater) = viewControllerFactory.makeQuickpay(
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

// MARK: - QRDownloadRouter

extension QuickpayFlow: QRDownloadRouter {}

// MARK: - QuickpayRouter

extension QuickpayFlow: QuickpayRouter {
    func showFeedback(model: FeedbackViewModel, context: FeedbackContext, onSuccess: @escaping () -> Void) {
        guard let navigationController else { return }
        let flow = feedbackFlowFactory.make(
            viewModel: model,
            context: context,
            service: feedbackService,
            hostController: navigationController,
            additionalProperties: nil
        )
        flow.onFinish { [weak self] result, dismisser in
            dismisser?.dismiss()
            if result == .success {
                onSuccess()
            }
            self?.activeFeedbackFlow = nil
        }
        activeFeedbackFlow = flow
        flow.start()
    }

    func showDynamicFormsMethodManagement(
        _ dynamicForms: [PaymentMethodDynamicForm],
        delegate: PaymentMethodsDelegate?
    ) {
        paymentMethodsDynamicFlowHandler.showDynamicForms(dynamicForms, delegate: delegate)
    }

    func startDownload(image: UIImage) {
        let viewController = qrDownloadViewControllerFactory.makeDownloadBottomSheet(
            router: self,
            image: image
        )
        downloadDismisser = bottomSheetPresenter.present(viewController: viewController)
    }

    func startAccountDetailsFlow(host: UIViewController) {
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
    }

    func personaliseTapped(status: ShareableLinkStatus.Discoverability) {
        guard let navigationController else { return }

        if featureService.isOn(ReceiveKitFeatures.quickpayToInPersonExperiment) {
            let (vc, shareableLinkStatusUpdater) = viewControllerFactory.makeQuickpayInPerson(
                profile: profile,
                status: status,
                router: self
            )
            shareableLinkStatusUpdaterForInPerson = shareableLinkStatusUpdater
            dismisser?.dismiss(animated: false, completion: {
                navigationController.pushViewController(
                    vc,
                    animated: false
                )
            })
        } else {
            let vc = viewControllerFactory.makeQuickpayPersonalise(profile: profile, status: status, router: self)
            navigationController.pushViewController(
                vc,
                animated: UIView.shouldAnimate
            )
        }
    }

    func shareLinkTapped(link: String) {
        guard let navigationController,
              let sourceView = navigationController.visibleViewController?.view else {
            return
        }

        let sharingController = UIActivityViewController.universalSharingController(
            forItems: [link],
            sourceView: sourceView
        )
        navigationController.present(sharingController, animated: UIView.shouldAnimate)
    }

    private enum Constants {
        static let deepLinkContext = Context(source: "Quickpay")
        static let methodManagementPath = "/payments/method-management"
    }

    func showHelpArticle(url: String) {
        guard let navigationController else {
            softFailure("[REC] Attempt to show help article when the primary navigation controller is empty.")
            return
        }
        guard let url = URL(string: url) else {
            return
        }
        let webViewController = webViewControllerFactory.make(with: url)
        webViewController.isDownloadSupported = true
        webViewController.modalPresentationStyle = .fullScreen
        navigationController.present(
            webViewController.navigationWrapped(),
            animated: UIView.shouldAnimate
        )
    }

    func showIntroStory(route: DeepLinkStoryRoute) {
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

    func showInPersonStory() {
        let viewController = QuickpayInPersonOnboardingViewController(primaryAction: { [weak self] in
            self?.start()
        })
        navigationController?.pushViewController(
            viewController,
            animated: UIView.shouldAnimate
        )
    }

    func showManageQuickpay(nickname: String?) {
        let viewController = viewControllerFactory.makeManageQuickpay(
            router: self,
            nickname: nickname
        )
        manageQuickpayDismisser = bottomSheetPresenter.present(viewController: viewController)
    }

    func showPaymentMethodsOnWeb() {
        manageQuickpayDismisser?.dismiss(completion: { [weak self] in
            guard let self else { return }
            let url = Branding.current.url.appendingPathComponent(Constants.methodManagementPath)
            let viewController = webViewControllerFactory.make(
                with: url,
                userInfoForAuthentication: (userProvider.user.userId, profile.id)
            )
            navigationController?.present(
                viewController.navigationWrapped(),
                animated: UIView.shouldAnimate
            )
        })
    }

    func showDiscoverability(nickname: String?) {
        if let manageQuickpayDismisser {
            manageQuickpayDismisser.dismiss(completion: { [weak self] in
                guard let self else { return }
                let viewController = viewControllerFactory.makeContactOnWise(
                    nickname: nickname,
                    profile: profile,
                    router: self
                )
                discoverabilityDismisser = bottomSheetPresenter.present(viewController: viewController)
            })
        } else {
            let viewController = viewControllerFactory.makeContactOnWise(
                nickname: nickname,
                profile: profile,
                router: self
            )
            discoverabilityDismisser = bottomSheetPresenter.present(viewController: viewController)
        }
    }

    func dismiss(isShareableLinkDiscoverable: Bool) {
        flowHandler.flowFinished(
            result: .completed(isShareableLinkDiscoverable: isShareableLinkDiscoverable),
            dismisser: dismisser
        )
    }
}

// MARK: - QuickpayContactOnWiseRouter

extension QuickpayFlow: WisetagContactOnWiseRouter {
    func dismissAndUpdateShareableLinkStatus(didChangeDiscoverability: Bool, isDiscoverable: Bool) {
        if !didChangeDiscoverability {
            discoverabilityDismisser?.dismiss()
            return
        }
        discoverabilityDismisser?.dismiss { [weak self] in
            self?.shareableLinkStatusUpdater?.updateShareableLinkStatus(isDiscoverable: isDiscoverable)
            self?.shareableLinkStatusUpdaterForInPerson?.updateShareableLinkStatus(isDiscoverable: isDiscoverable)
        }
    }
}
