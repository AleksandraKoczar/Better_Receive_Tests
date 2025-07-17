import BalanceKit
import BalanceKitTestingSupport
import Combine
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWTestingSupportKit
import XCTest

final class LoadAccountDetailsStatusInteractorImplTests: TWTestCase {
    private var interactor: LoadAccountDetailsStatusInteractorImpl!
    private var useCase: AccountDetailsUseCaseMock!
    private var accountDetailsPublisher: CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>!
    private var cancellables: Set<AnyCancellable> = []
    private var accountDetails: [AccountDetails] = []
    private var isFailure = false

    override func setUp() {
        super.setUp()
        accountDetailsPublisher = .init(nil)
        useCase = AccountDetailsUseCaseMock()
        useCase.accountDetails = accountDetailsPublisher.eraseToAnyPublisher()
        interactor = LoadAccountDetailsStatusInteractorImpl(
            useCase: useCase
        )
    }

    override func tearDown() {
        accountDetails.removeAll()
        cancellables.removeAll()
        accountDetailsPublisher = nil
        useCase = nil
        interactor = nil
        super.tearDown()
    }

    func testAccountDetails_whenLoadedSuccessfully_thenPublishesAccountDetails() {
        let details = [AccountDetails.active(.build(title: "test"))]
        sinkAccountDetails()

        accountDetailsPublisher.send(nil)
        accountDetailsPublisher.send(.loading)
        accountDetailsPublisher.send(.loaded(details))

        XCTAssertTrue(useCase.refreshAccountDetailsCalled)
        XCTAssertEqual(details, accountDetails)
    }

    func testAccountDetails_whenLoadingFailed_thenPublishesError() {
        sinkAccountDetails()

        accountDetailsPublisher.send(nil)
        accountDetailsPublisher.send(.loading)
        accountDetailsPublisher.send(.recoverableError(NSError.canned))

        XCTAssertTrue(useCase.refreshAccountDetailsCalled)
        XCTAssertTrue(isFailure)
    }

    private func sinkAccountDetails() {
        interactor.accountDetails.sink(
            receiveCompletion: { result in
                if case .failure = result {
                    self.isFailure = true
                }
            },
            receiveValue: {
                self.accountDetails.append(contentsOf: $0)
            }
        )
        .store(in: &cancellables)
    }
}
