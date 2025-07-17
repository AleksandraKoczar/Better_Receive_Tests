import BalanceKit
import TWFoundation
import UIKit
import WiseCore

public enum AccountDetailsWishFactory {
    public static func makeViewController(
        country: Country?,
        interactor: AccountDetailsWishListInteractor,
        completion: @escaping () -> Void
    ) -> UIViewController {
        let wishUseCase = BalanceWishUseCaseFactory.make()
        let presenter = AccountDetailsWishListPresenterImpl(
            country: country,
            interactor: interactor,
            wishUseCase: wishUseCase,
            completion: completion
        )
        return AccountDetailsWishViewController(presenter: presenter)
    }
}
