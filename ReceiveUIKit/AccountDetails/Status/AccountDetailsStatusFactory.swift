import ApiKit
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol AccountDetailsStatusFactory {
    func make(
        profileId: ProfileId,
        currencyCode: CurrencyCode,
        routingDelegate: AccountDetailsActionsListDelegate
    ) -> UIViewController
}

public struct AccountDetailsStatusFactoryImpl: AccountDetailsStatusFactory {
    public init() {}

    public func make(
        profileId: ProfileId,
        currencyCode: CurrencyCode,
        routingDelegate: AccountDetailsActionsListDelegate
    ) -> UIViewController {
        let router = AccountDetailsStatusRouterImpl()
        let interactor = AccountDetailsStatusInteractorImpl(
            service: AccountDetailsStatusServiceFactory.make()
        )
        let presenter = AccountDetailsStatusPresenterImpl(
            profileId: profileId,
            currencyCode: currencyCode,
            routingDelegate: routingDelegate,
            router: router,
            interactor: interactor
        )
        let viewController = AccountDetailsStatusViewController(
            presenter: presenter
        )
        router.navigationHost = viewController
        return viewController
    }
}
