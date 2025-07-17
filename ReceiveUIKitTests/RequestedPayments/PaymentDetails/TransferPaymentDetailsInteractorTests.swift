import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import WiseCore

final class TransferPaymentDetailsInteractorTests: TWTestCase {
    private var interactor: TransferPaymentDetailsInteractor!
    private var useCase: PaymentRequestDetailsUseCaseMock!

    private let profileId = ProfileId(12345678)

    override func setUp() {
        super.setUp()
        useCase = PaymentRequestDetailsUseCaseMock()
        interactor = TransferPaymentDetailsInteractor(
            paymentRequestId: PaymentRequestId("ABC"),
            transferId: ReceiveTransferId("some-transfer-id"),
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
        useCase.paymentDetailsWithTransferIdReturnValue = .just(paymentDetails)

        let result = try awaitPublisher(
            interactor.paymentDetails(profileId: profileId)
        )

        XCTAssertEqual(result.value, paymentDetails)
        XCTAssertEqual(useCase.paymentDetailsWithTransferIdCallsCount, 1)
    }

    func test_paymentDetails_failure() throws {
        let error = MockError.dummy
        useCase.paymentDetailsWithTransferIdReturnValue = .fail(with: error)

        let result = try awaitPublisher(
            interactor.paymentDetails(profileId: profileId)
        )

        XCTAssertEqual(result.error as? MockError, error)
        XCTAssertEqual(useCase.paymentDetailsWithTransferIdCallsCount, 1)
    }
}
