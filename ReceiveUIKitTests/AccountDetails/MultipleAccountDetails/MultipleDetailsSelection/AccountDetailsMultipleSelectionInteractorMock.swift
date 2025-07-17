import BalanceKit
import Combine
@testable import ReceiveUIKit
import TWFoundation

final class AccountDetailsMultipleSelectionInteractorMock: AccountDetailsMultipleSelectionInteractor {
    var refreshAccountDetailsCalled = false
    var accountDetailsSubject: CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never> = .init(nil)
    var accountDetails: AnyPublisher<LoadableDataState<[AccountDetails]>?, Never> {
        accountDetailsSubject.eraseToAnyPublisher()
    }

    func refreshAccountDetails() {
        refreshAccountDetailsCalled = true
    }
}
