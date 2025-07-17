import BalanceKit
import Combine
import TWFoundation

protocol AccountDetailsMultipleSelectionInteractor {
    var accountDetails: AnyPublisher<LoadableDataState<[AccountDetails]>?, Never> { get }
    func refreshAccountDetails()
}

struct AccountDetailsMultipleSelectionInteractorImpl: AccountDetailsMultipleSelectionInteractor {
    private let accountDetailsUseCase: AccountDetailsUseCase
    var accountDetails: AnyPublisher<LoadableDataState<[AccountDetails]>?, Never> {
        accountDetailsUseCase.accountDetails
            .eraseToAnyPublisher()
    }

    init(accountDetailsUseCase: AccountDetailsUseCase) {
        self.accountDetailsUseCase = accountDetailsUseCase
    }

    func refreshAccountDetails() {
        accountDetailsUseCase.refreshAccountDetails()
    }
}
