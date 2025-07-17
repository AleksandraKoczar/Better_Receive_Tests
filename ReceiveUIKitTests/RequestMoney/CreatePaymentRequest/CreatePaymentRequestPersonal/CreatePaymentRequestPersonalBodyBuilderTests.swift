import ContactsKit
import ContactsKitTestingSupport
import ReceiveKit
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class CreatePaymentRequestPersonalBodyBuilderTests: TWTestCase {
    private let amount: Decimal = 0.07
    private let currency = CurrencyCode.GBP
    private let balanceId = BalanceId(123)
    private let message = LoremIpsum.long
    private let paymentRequestId = PaymentRequestId("WXYZ-ABCD-1234-5678")
    private let expectedContactId = "CID"
    private let payerId = "beefblob-beef-blob-beef-blobbeefblob"

    func test_make_forCreating() throws {
        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            contact: RequestMoneyContact.build(
                id: expectedContactId,
                hasRequestCapability: true
            ),
            value: amount,
            selectedCurrency: currency,
            eligibleBalances: .build(
                balances: [
                    .build(currency: currency),
                    .build(currency: .EUR),
                ]
            ),
            selectedBalanceId: balanceId,
            message: message,
            paymentMethods: [.card]
        )

        let requestBody = try CreatePaymentRequestPersonalBodyBuilder.make(
            paymentRequestInfo: paymentRequestInfo
        )

        let expected = PaymentRequestSingleUseBody(
            balanceId: balanceId.value,
            selectedPaymentMethods: [.card],
            amountValue: amount,
            description: nil,
            message: message,
            payer: PaymentRequestSingleUseBody.Payer(contactId: expectedContactId, name: "", address: nil)
        )

        expectNoDifference(requestBody, expected)
    }

    func test_make_forCreating_givenEmptyAmount_thenThrowsCorrectError() {
        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            contact: RequestMoneyContact.build(
                id: expectedContactId,
                hasRequestCapability: true
            ),
            value: nil,
            selectedCurrency: currency,
            eligibleBalances: .build(
                balances: [
                    .build(currency: currency),
                    .build(currency: .EUR),
                ]
            ),
            selectedBalanceId: balanceId,
            message: message,
            paymentMethods: [.card]
        )

        XCTAssertThrowsError(
            try CreatePaymentRequestPersonalBodyBuilder.make(
                paymentRequestInfo: paymentRequestInfo
            )
        ) { error in
            XCTAssertEqual(
                error as? CreatePaymentRequestPersonalBodyBuilderError,
                .invalidAmount(reason: "Please enter an amount to request")
            )
        }
    }

    func test_make_forCreating_givenNegativeAmount_thenThrowsCorrectError() {
        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            contact: RequestMoneyContact.build(
                id: expectedContactId,
                hasRequestCapability: true
            ),
            value: -10,
            selectedCurrency: currency,
            eligibleBalances: .build(
                balances: [
                    .build(currency: currency),
                    .build(currency: .EUR),
                ]
            ),
            selectedBalanceId: balanceId,
            message: message,
            paymentMethods: [.card]
        )

        XCTAssertThrowsError(
            try CreatePaymentRequestPersonalBodyBuilder.make(
                paymentRequestInfo: paymentRequestInfo
            )
        ) { error in
            XCTAssertEqual(
                error as? CreatePaymentRequestPersonalBodyBuilderError,
                .invalidAmount(reason: "Please enter an amount greater than 0")
            )
        }
    }
}
