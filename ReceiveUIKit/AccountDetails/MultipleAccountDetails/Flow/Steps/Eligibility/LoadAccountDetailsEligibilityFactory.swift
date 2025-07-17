import BalanceKit
import Foundation
import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
protocol LoadAccountDetailsEligibilityFactory {
    func make(
        router: LoadAccountDetailsEligibilityRouter,
        profile: Profile
    ) -> UIViewController
}

final class LoadAccountDetailsEligibilityFactoryImpl: LoadAccountDetailsEligibilityFactory {
    private let accountDetailsEligibilityService: MultipleAccountDetailsEligibilityService
    private let accountDetailsOrderUseCase: AccountDetailsOrderUseCase

    init(
        accountDetailsEligibilityService: MultipleAccountDetailsEligibilityService,
        accountDetailsOrderUseCase: AccountDetailsOrderUseCase
    ) {
        self.accountDetailsEligibilityService = accountDetailsEligibilityService
        self.accountDetailsOrderUseCase = accountDetailsOrderUseCase
    }

    func make(
        router: LoadAccountDetailsEligibilityRouter,
        profile: Profile
    ) -> UIViewController {
        let interactor = LoadAccountDetailsEligibilityInteractorImpl(
            accountDetailsEligibilityService: accountDetailsEligibilityService,
            accountDetailsOrderUseCase: accountDetailsOrderUseCase
        )
        let presenter = LoadAccountDetailsEligibilityPresenter(
            profile: profile,
            router: router,
            interactor: interactor
        )
        return DataLoadingViewController(
            presenter: presenter
        )
    }
}
