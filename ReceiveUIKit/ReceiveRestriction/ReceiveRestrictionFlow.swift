import DeepLinkKit
import Foundation
import LoggingKit
import Neptune
import ReceiveKit
import TWFoundation
import UIKit
import WiseCore

final class ReceiveRestrictionFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private let context: ReceiveRestrictionContext
    private let profileId: ProfileId
    private let navigationController: UINavigationController
    private let viewControllerFactory: ReceiveRestrictionViewControllerFactory
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory
    private let allDeepLinksUIFactory: AllDeepLinksUIFactory
    private let deeplinkRouteFactory: DeepLinkRouteFactory
    private let urlOpener: UrlOpener
    private let flowPresenter: FlowPresenter

    private var dismisser: ViewControllerDismisser?
    private var deepLinkFlow: (any Flow<Void>)?

    init(
        context: ReceiveRestrictionContext,
        profileId: ProfileId,
        navigationController: UINavigationController,
        viewControllerFactory: ReceiveRestrictionViewControllerFactory,
        viewControllerPresenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl(),
        allDeepLinksUIFactory: AllDeepLinksUIFactory,
        deeplinkRouteFactory: DeepLinkRouteFactory,
        urlOpener: UrlOpener,
        flowPresenter: FlowPresenter = .current
    ) {
        self.context = context
        self.profileId = profileId
        self.navigationController = navigationController
        self.viewControllerFactory = viewControllerFactory
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
        self.allDeepLinksUIFactory = allDeepLinksUIFactory
        self.deeplinkRouteFactory = deeplinkRouteFactory
        self.urlOpener = urlOpener
        self.flowPresenter = flowPresenter
    }

    func start() {
        flowHandler.flowStarted()
        let presenter = viewControllerPresenterFactory.makePushPresenter(
            navigationController: navigationController
        )
        let viewController = viewControllerFactory.make(
            context: context,
            profileId: profileId,
            routingDelegate: self,
            navigationController: navigationController
        )
        dismisser = presenter.present(viewController: viewController)
    }

    func terminate() {
        dismisser?.dismiss()
        flowHandler.flowFinished(
            result: (),
            dismisser: dismisser
        )
    }
}

extension ReceiveRestrictionFlow: ReceiveRestrictionRoutingDelegate {
    func handleURI(_ uri: URI) {
        if let route = deeplinkRouteFactory.makeRoute(uri: uri) {
            handleDeepLink(route: route)
        } else if case let URI.url(url) = uri {
            urlOpener.open(url)
        } else {
            softFailure(
                "[REC]: Unknown URI received \(uri)"
            )
        }
    }

    func dismiss() {
        terminate()
    }
}

// MARK: - Helpers

private extension ReceiveRestrictionFlow {
    func handleDeepLink(route: DeepLinkRoute) {
        guard let flow = allDeepLinksUIFactory.build(
            for: route,
            hostController: navigationController,
            with: Context(source: "Receive Restriction")
        ) else {
            return
        }

        flow.onFinish { [weak self] _, dismisser in
            dismisser?.dismiss()
            self?.deepLinkFlow = nil
        }

        deepLinkFlow = flow
        flowPresenter.start(flow: flow)
    }
}
