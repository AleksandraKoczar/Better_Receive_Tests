import BalanceKit
import Combine
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWTestingSupportKit
import UserKitTestingSupport
import XCTest

final class LoadAccountDetailsEligibilityInteractorImplTests: TWTestCase {
    private var interactor: LoadAccountDetailsEligibilityInteractorImpl!
    private var accountDetailsEligibilityService: MultipleAccountDetailsEligibilityServiceMock!
    private var accountDetailsOrderUseCase: AccountDetailsOrderUseCaseMock!
    private var cancellables: Set<AnyCancellable> = []
    private var eligibility: MultipleAccountDetailsEligibility?
    private var isFailure = false

    override func setUp() {
        super.setUp()
        accountDetailsEligibilityService = {
            let service = MultipleAccountDetailsEligibilityServiceMock()
            service.eligibilityClosure = { $1(.success(true)) }
            return service
        }()
        accountDetailsOrderUseCase = {
            let useCase = AccountDetailsOrderUseCaseMock()
            useCase.ordersClosure = { $2(.success([])) }
            return useCase
        }()
        interactor = LoadAccountDetailsEligibilityInteractorImpl(
            accountDetailsEligibilityService: accountDetailsEligibilityService,
            accountDetailsOrderUseCase: accountDetailsOrderUseCase
        )
    }

    override func tearDown() {
        accountDetailsEligibilityService = nil
        accountDetailsOrderUseCase = nil
        interactor = nil
        super.tearDown()
    }

    func testEligibility_whenEligible_andOrdersLoadedSuccessfully_thenPublishesEligible() {
        let requirements = [AccountDetailsRequirement.build(type: .verification, status: .pendingUser)]
        sinkEligibility()
        accountDetailsEligibilityService.eligibilityReceivedArguments?.completion(.success(true))
        accountDetailsOrderUseCase.ordersReceivedInvocations.first?.completion(.success([
            .build(requirements: requirements),
        ]))
        XCTAssertEqual(eligibility, .eligible(requirements: requirements))
    }

    func testEligibility_whenNotEligible_thenPublishesIneligible() {
        sinkEligibility()
        accountDetailsEligibilityService.eligibilityReceivedArguments?.completion(.success(false))
        XCTAssertEqual(eligibility, .ineligible)
    }

    func testEligibility_whenEligibilityLoadingFailed_thenPublishesError() {
        sinkEligibility()
        accountDetailsEligibilityService.eligibilityReceivedArguments?.completion(.failure(NSError.canned))
        XCTAssertTrue(isFailure)
    }

    func testEligibility_whenOrdersLoadingFailed_thenPublishesError() {
        sinkEligibility()
        accountDetailsEligibilityService.eligibilityReceivedArguments?.completion(.success(true))
        accountDetailsOrderUseCase.ordersReceivedInvocations.first?.completion(.failure(.fetchError(NSError.canned)))
        XCTAssertTrue(isFailure)
    }

    private func sinkEligibility() {
        interactor.eligibility(for: FakeBusinessProfileInfo().asProfile())
            .sink { result in
                if case .failure = result {
                    self.isFailure = true
                }
            } receiveValue: {
                self.eligibility = $0
            }
            .store(in: &cancellables)
    }
}
