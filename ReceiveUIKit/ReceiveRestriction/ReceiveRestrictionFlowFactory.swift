import DeepLinkKit
import Foundation
import ReceiveKit
import TWFoundation
import TWUI
import UIKit
import WiseCore

public final class ReceiveRestrictionFlowFactory {
    private let allDeepLinksUIFactory: AllDeepLinksUIFactory
    private let deeplinkRouteFactory: DeepLinkRouteFactory

    public init(
        allDeepLinksUIFactory: AllDeepLinksUIFactory = GOS[AllDeepLinksUIFactoryKey.self],
        deeplinkRouteFactory: DeepLinkRouteFactory
    ) {
        self.allDeepLinksUIFactory = allDeepLinksUIFactory
        self.deeplinkRouteFactory = deeplinkRouteFactory
    }

    public func make(
        context: ReceiveRestrictionContext,
        profileId: ProfileId,
        navigationHost: UIViewController
    ) -> any Flow<Void> {
        if let navigationController = navigationHost as? UINavigationController {
            return makeFlow(
                context: context,
                profileId: profileId,
                navigationController: navigationController
            )
        } else {
            let navigationController = TWNavigationController()
            navigationController.modalPresentationStyle = .fullScreen

            let flow = makeFlow(
                context: context,
                profileId: profileId,
                navigationController: navigationController
            )

            return ModalPresentationFlow(
                flow: flow,
                rootViewController: navigationHost,
                flowController: navigationController
            )
        }
    }
}

private extension ReceiveRestrictionFlowFactory {
    private func makeFlow(
        context: ReceiveRestrictionContext,
        profileId: ProfileId,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        ReceiveRestrictionFlow(
            context: context,
            profileId: profileId,
            navigationController: navigationController,
            viewControllerFactory: ReceiveRestrictionViewControllerFactoryImpl(),
            allDeepLinksUIFactory: allDeepLinksUIFactory,
            deeplinkRouteFactory: deeplinkRouteFactory,
            urlOpener: UIApplication.shared
        )
    }
}
