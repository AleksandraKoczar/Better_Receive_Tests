import BalanceKit
import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
protocol LoadAccountDetailsStatusFactory {
    func make(
        router: LoadAccountDetailsStatusRouter,
        profile: Profile
    ) -> UIViewController
}

final class LoadAccountDetailsStatusFactoryImpl: LoadAccountDetailsStatusFactory {
    private let useCase: AccountDetailsUseCase

    init(
        useCase: AccountDetailsUseCase
    ) {
        self.useCase = useCase
    }

    func make(
        router: LoadAccountDetailsStatusRouter,
        profile: Profile
    ) -> UIViewController {
        let interactor = LoadAccountDetailsStatusInteractorImpl(
            useCase: useCase
        )
        let presenter = LoadAccountDetailsStatusPresenter(
            profile: profile,
            router: router,
            interactor: interactor
        )
        return DataLoadingViewController(
            presenter: presenter
        )
    }
}
