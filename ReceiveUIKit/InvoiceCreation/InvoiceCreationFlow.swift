import AnalyticsKit
import Neptune
import TWFoundation
import TWUI
import UIKit
import UserKit

final class InvoiceCreationFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private let profile: Profile
    private let userProvider: UserProvider
    private let navigationController: UINavigationController
    private let entryPoint: InvoiceCreationFlowEntryPoint
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let presenterFactory: ViewControllerPresenterFactory

    private var invoiceCreationDismisser: ViewControllerDismisser?

    init(
        profile: Profile,
        entryPoint: InvoiceCreationFlowEntryPoint,
        navigationController: UINavigationController,
        webViewControllerFactory: WebViewControllerFactory.Type,
        presenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl(),
        userProvider: UserProvider = GOS[UserProviderKey.self],
    ) {
        self.profile = profile
        self.entryPoint = entryPoint
        self.navigationController = navigationController
        self.webViewControllerFactory = webViewControllerFactory
        self.presenterFactory = presenterFactory
        self.userProvider = userProvider
    }

    func start() {
        flowHandler.flowStarted()
        let url = Branding.current.url.appendingPathComponent(ReceiveWebViewUrlConstants.createInvoiceUrlPath)
        let dismissalHandler: (() -> Void)? = { [weak self] in
            guard let self else { return }
            flowHandler.flowFinished(result: (), dismisser: invoiceCreationDismisser)
        }
        let viewController = webViewControllerFactory.make(
            with: url,
            userInfoForAuthentication: (userProvider.user.userId, profile.id),
            popDismissalHandler: dismissalHandler,
            modalDismissalHandler: dismissalHandler
        )
        viewController.isDownloadSupported = true
        let navVC = viewController.navigationWrapped()
        navVC.modalPresentationStyle = .fullScreen
        let presenter = presenterFactory
            .makeModalPresenter(parent: navigationController)
        invoiceCreationDismisser = presenter.present(viewController: navVC)
    }

    func terminate() {
        flowHandler.flowFinished(result: (), dismisser: invoiceCreationDismisser)
    }
}
