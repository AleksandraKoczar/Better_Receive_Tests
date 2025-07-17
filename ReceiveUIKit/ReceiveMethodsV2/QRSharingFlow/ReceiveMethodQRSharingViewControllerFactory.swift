import LoggingKit
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol ReceiveMethodQRSharingViewControllerFactory {
    func make(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        mode: ReceiveMethodsQRSharingMode,
        navigationController: UINavigationController
    ) -> UIViewController
}

struct ReceiveMethodQRSharingViewControllerFactoryImpl: ReceiveMethodQRSharingViewControllerFactory {
    func make(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        mode: ReceiveMethodsQRSharingMode,
        navigationController: UINavigationController
    ) -> UIViewController {
        let router = ReceiveMethodsQRSharingRouterImpl(
            navigationController: navigationController
        )
        guard let profile = GOS[UserProviderKey.self].activeProfile,
              profileId == profile.id else {
            hardFailure("Impossible state as we are passing priofile ID")
        }
        let useCase = PixQRUseCaseFactoryImpl().make()
        let aliasUseCase = ReceiveMethodsAliasUseCaseFactoryImpl()
            .make()
        let presenter = ReceiveMethodsQRSharingPresenterImpl(
            accountDetailsId: accountDetailsId,
            profile: profile,
            mode: mode,
            useCase: useCase,
            aliasUseCase: aliasUseCase,
            router: router
        )
        return ReceiveMethodsQRSharingViewController(presenter: presenter)
    }
}
