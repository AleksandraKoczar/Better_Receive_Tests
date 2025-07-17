import BalanceKit
import Combine
import UserKit
import WiseCore

enum MultipleAccountDetailsEligibility: Equatable {
    case eligible(requirements: [AccountDetailsRequirement])
    case ineligible
}

// sourcery: AutoMockable
protocol LoadAccountDetailsEligibilityInteractor {
    func eligibility(for profile: Profile) -> AnyPublisher<MultipleAccountDetailsEligibility, Error>
}

final class LoadAccountDetailsEligibilityInteractorImpl {
    private struct GenericError: Error {}

    private let accountDetailsOrderUseCase: AccountDetailsOrderUseCase
    private let accountDetailsEligibilityService: MultipleAccountDetailsEligibilityService
    private var cancellable: AnyCancellable?

    init(
        accountDetailsEligibilityService: MultipleAccountDetailsEligibilityService,
        accountDetailsOrderUseCase: AccountDetailsOrderUseCase
    ) {
        self.accountDetailsEligibilityService = accountDetailsEligibilityService
        self.accountDetailsOrderUseCase = accountDetailsOrderUseCase
    }
}

extension LoadAccountDetailsEligibilityInteractorImpl: LoadAccountDetailsEligibilityInteractor {
    func eligibility(for profile: Profile) -> AnyPublisher<MultipleAccountDetailsEligibility, Error> {
        let publisher = PassthroughSubject<MultipleAccountDetailsEligibility, Error>()
        accountDetailsEligibilityService.eligibility(for: profile) { [weak self] result in
            switch result {
            case let .success(eligible):
                if eligible {
                    self?.fetchRequirements(
                        for: profile.id,
                        publisher: publisher
                    )
                } else {
                    publisher.send(.ineligible)
                }
            case .failure:
                publisher.send(completion: .failure(GenericError()))
            }
        }
        return publisher.eraseToAnyPublisher()
    }
}

private extension LoadAccountDetailsEligibilityInteractorImpl {
    func fetchRequirements(
        for profileId: ProfileId,
        publisher: PassthroughSubject<MultipleAccountDetailsEligibility, Error>
    ) {
        accountDetailsOrderUseCase.orders(
            profileId: profileId,
            status: []
        ) {
            switch $0 {
            case let .success(orders):
                publisher.send(.eligible(requirements: orders.flatMap { $0.requirements }))
            case .failure:
                publisher.send(completion: .failure(GenericError()))
            }
        }
    }
}
