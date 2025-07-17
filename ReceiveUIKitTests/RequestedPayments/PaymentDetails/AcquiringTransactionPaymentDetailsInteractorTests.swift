import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import WiseCore

final class AcquiringTransactionPaymentDetailsInteractorTests: TWTestCase {
    private var interactor: AcquiringTransactionPaymentDetailsInteractor!
    private var useCase: PaymentRequestDetailsUseCaseMock!

    private let profileId = ProfileId(12345678)

    override func setUp() {
        super.setUp()
        useCase = PaymentRequestDetailsUseCaseMock()
        interactor = AcquiringTransactionPaymentDetailsInteractor(
            transactionId: AcquiringTransactionId("some-transaction-id"),
            useCase: useCase
        )
    }

    override func tearDown() {
        interactor = nil
        useCase = nil
        super.tearDown()
    }

    func test_paymentDetails_success() throws {
        let paymentDetails = PaymentDetails.canned
        useCase.paymentDetailsWithTransactionIdReturnValue = .just(paymentDetails)

        let result = try awaitPublisher(
            interactor.paymentDetails(profileId: profileId)
        )

        XCTAssertEqual(result.value, paymentDetails)
        XCTAssertEqual(useCase.paymentDetailsWithTransactionIdCallsCount, 1)
    }

    func test_paymentDetails_failure() throws {
        let error = MockError.dummy
        useCase.paymentDetailsWithTransactionIdReturnValue = .fail(with: error)

        let result = try awaitPublisher(
            interactor.paymentDetails(profileId: profileId)
        )

        XCTAssertEqual(result.error as? MockError, error)
        XCTAssertEqual(useCase.paymentDetailsWithTransactionIdCallsCount, 1)
    }
}
