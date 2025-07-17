import BalanceKit
import BalanceKitTestingSupport
import Combine
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import XCTest

final class AccountDetailsMultipleSelectionInteractorImplTests: TWTestCase {
    private var interactor: AccountDetailsMultipleSelectionInteractorImpl!
    private let useCase = AccountDetailsUseCaseMock()
    private let mockAccountDetailsPublisher: CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never> = .init(nil)
    private var cancellables: Set<AnyCancellable> = []
    private var states: [LoadableDataState<[AccountDetails]>?] = []

    override func setUp() {
        super.setUp()
        interactor = AccountDetailsMultipleSelectionInteractorImpl(accountDetailsUseCase: useCase)
        useCase.accountDetails = mockAccountDetailsPublisher.eraseToAnyPublisher()
    }

    func testRefreshAccountDetails() {
        interactor.refreshAccountDetails()
        XCTAssertTrue(useCase.refreshAccountDetailsCalled)
    }

    func testAccountDetailsLoaded() {
        interactor.accountDetails.sink { state in
            self.states.append(state)
        }
        .store(in: &cancellables)

        mockAccountDetailsPublisher.send(.loading)
        let accountDetails: [AccountDetails] = [
            .canned,
            .canned,
        ]
        mockAccountDetailsPublisher.send(.loaded(accountDetails))

        XCTAssertEqual(states, [nil, .loading, .loaded(accountDetails)])
    }

    func testAccountDetailsFailedToLoad() {
        interactor.accountDetails.sink { state in
            self.states.append(state)
        }
        .store(in: &cancellables)

        mockAccountDetailsPublisher.send(.loading)
        let error = UseCaseError.fetchError(NSError.canned)
        mockAccountDetailsPublisher.send(.recoverableError(error))

        XCTAssertEqual(states, [nil, .loading, .recoverableError(error)])
    }
}
