import ApiKit
import BalanceKit
import PersistenceKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

public enum AccountDetailsMultipleSelectionFactory {
    public static func make(
        feeRequirement: AccountDetailsRequirement?,
        preselectedCurrencies: [CurrencyCode],
        apiClient: TWAPIClient,
        userProvider: UserProvider,
        dataAccessor: CoreDataAccessor,
        router: AccountDetailsMultipleSelectionRouter
    ) -> UIViewController {
        let useCase = AccountDetailsUseCaseFactory.makeUseCase()
        let interactor = AccountDetailsMultipleSelectionInteractorImpl(accountDetailsUseCase: useCase)
        let presenter = AccountDetailsMultipleSelectionPresenterImpl(
            feeRequirement: feeRequirement,
            preselectedCurrencies: preselectedCurrencies,
            interactor: interactor,
            router: router
        )
        return AccountDetailsMultipleSelectionViewController(presenter: presenter)
    }
}
