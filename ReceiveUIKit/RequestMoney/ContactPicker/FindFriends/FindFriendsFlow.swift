import ContactsKit
import LoggingKit
import Neptune
import TransferResources
import TWFoundation
import UIKit
import WiseCore

final class FindFriendsFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private weak var navigationController: UINavigationController?
    private let helpCenterArticleFactory: HelpCenterArticleFactory
    private let discoveryService: ContactSyncDiscoveryService
    private let urlOpener: UrlOpener
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory

    private var articleFlow: (any Flow<Void>)?
    private var dismisser: ViewControllerDismisser?

    init(
        navigationController: UINavigationController,
        helpCenterArticleFactory: HelpCenterArticleFactory,
        discoveryService: ContactSyncDiscoveryService = GOS[ContactSyncDiscoveryServiceKey.self],
        urlOpener: UrlOpener,
        viewControllerPresenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl()
    ) {
        self.navigationController = navigationController
        self.helpCenterArticleFactory = helpCenterArticleFactory
        self.discoveryService = discoveryService
        self.urlOpener = urlOpener
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
    }

    func start() {
        guard let navigationController else {
            softFailure("[REC] Attempt to start find friends flow when the primary navigation controller is empty.")
            return
        }

        flowHandler.flowStarted()

        let vc = FindFriendsViewController(
            modelProvider: FindFriendsModelProvider(),
            actionHandler: self
        )

        let presenter = viewControllerPresenterFactory.makeModalPresenter(
            parent: navigationController
        )
        dismisser = presenter.present(viewController: vc)
    }

    func terminate() {
        flowHandler.flowFinished(result: (), dismisser: dismisser)
    }
}

extension FindFriendsFlow: FindFriendsActionDelegate {
    func enableContactSync() {
        guard let navigationController else {
            softFailure("[REC] Attempt to show contact settings when the primary navigation controller is empty.")
            return
        }

        Task(priority: .userInitiated) { @MainActor in
            do {
                try await discoveryService.updateContactSyncConsent(enabled: true)
            } catch {
                guard case ContactSyncError.noPhoneBookAccess = error else { return }
                let dismiss = UIAlertAction(
                    title: L10n.Settings.Privacy.ContactPermissions.Error.notNow,
                    style: .cancel
                )

                let settings = UIAlertAction(
                    title: L10n.Settings.Privacy.ContactPermissions.Error.settings,
                    style: .default
                ) { [urlOpener] _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString),
                          urlOpener.canOpenURL(url) else { return }
                    urlOpener.open(url)
                }

                let alert = UIAlertController.makeAlert(
                    title: L10n.Settings.Privacy.ContactPermissions.Error.title,
                    message: L10n.Settings.Privacy.ContactPermissions.Error.message,
                    actions: [dismiss, settings]
                )

                navigationController.dismiss(animated: true, completion: { [weak self] in
                    guard let self else { return }
                    self.navigationController?.present(alert, animated: UIView.shouldAnimate)
                })
            }
        }
    }

    func learnMoreButtonTapped() {
        guard let navigationController else { return }

        let flow = helpCenterArticleFactory.makeArticleFlow(
            hostController: navigationController,
            articleId: HelpCenterArticleId(rawValue: "2978055")
        )
        flow.onFinish { [weak self] _, dismisser in
            self?.articleFlow = nil
            dismisser?.dismiss()
            self?.terminate()
        }
        articleFlow = flow
        navigationController.dismiss(animated: false) {
            flow.start()
        }
    }
}
