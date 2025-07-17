import DeepLinkKit
import Foundation
import ReceiveKit
import TWFoundation
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol ReceiveRestrictionViewControllerFactory {
    func make(
        context: ReceiveRestrictionContext,
        profileId: ProfileId,
        routingDelegate: ReceiveRestrictionRoutingDelegate,
        navigationController: UINavigationController
    ) -> UIViewController
}

struct ReceiveRestrictionViewControllerFactoryImpl: ReceiveRestrictionViewControllerFactory {
    func make(
        context: ReceiveRestrictionContext,
        profileId: ProfileId,
        routingDelegate: ReceiveRestrictionRoutingDelegate,
        navigationController: UINavigationController
    ) -> UIViewController {
        let useCase = ReceiveRestrictionUseCaseFactory.make()
        let presenter = ReceiveRestrictionPresenterImpl(
            context: context,
            profileId: profileId,
            useCase: useCase,
            routingDelegate: routingDelegate
        )
        return ReceiveRestrictionViewController(
            presenter: presenter
        )
    }
}
