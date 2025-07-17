import BalanceKit
import Combine
import Foundation
import UserKit

// sourcery: AutoMockable
protocol LoadAccountDetailsStatusInteractor {
    var accountDetails: AnyPublisher<[AccountDetails], Error> { get }
}

final class LoadAccountDetailsStatusInteractorImpl: LoadAccountDetailsStatusInteractor {
    private struct GenericError: Error {}

    private let useCase: AccountDetailsUseCase

    init(useCase: AccountDetailsUseCase) {
        self.useCase = useCase
    }

    var accountDetails: AnyPublisher<[AccountDetails], Error> {
        useCase
            .accountDetails
            .handleEvents(
                receiveOutput: { [useCase] state in
                    if state == nil {
                        useCase.refreshAccountDetails()
                    }
                }
            )
            .tryCompactMap { state in
                guard let state else {
                    return nil
                }
                switch state {
                case .loading:
                    return nil
                case let .loaded(details):
                    return details
                case .recoverableError:
                    throw GenericError()
                }
            }
            .eraseToAnyPublisher()
    }
}
