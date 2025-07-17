@testable import ReceiveUIKit
import TWTestingSupportKit

final class CreatePaymentRequestPersonalValidatorTests: TWTestCase {
    func test_validPayerName_payerNameIsValid() {
        let payerName = String(repeating: "a", count: 20)
        let result = CreatePaymentRequestPersonalValidator.validPayerName(payerName)
        XCTAssertEqual(result, .valid)
    }

    func test_validPayerName_payerNameIsTooLong() {
        let payerName = String(repeating: "a", count: 200)
        let result = CreatePaymentRequestPersonalValidator.validPayerName(payerName)
        let expectedReason = CreatePaymentRequestPersonalValidator.InvalidReason(description: "Enter a payer name that’s under 151 characters.")
        XCTAssertEqual(result, .invalid(reason: expectedReason))
    }

    func test_validPersonalMessage_messageIsValid() {
        let message = String(repeating: "a", count: 40)
        let result = CreatePaymentRequestPersonalValidator.validPersonalMessage(message)
        XCTAssertEqual(result, .valid)
    }

    func test_validPersonalMessage_messageIsTooLong() {
        let message = String(repeating: "a", count: 100)
        let result = CreatePaymentRequestPersonalValidator.validPersonalMessage(message)
        let expectedReason = CreatePaymentRequestPersonalValidator.InvalidReason(description: "Enter a note that’s under 41 characters.")
        XCTAssertEqual(result, .invalid(reason: expectedReason))
    }
}
