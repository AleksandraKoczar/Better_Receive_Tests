import ContactsKit
import ContactsKitTestingSupport
import ReceiveKit
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class CreatePaymentRequestBodyBuilderTests: TWTestCase {
    private let amount: Decimal = 0.07
    private let currency = CurrencyCode.GBP
    private let balanceId = BalanceId(123)
    private let reference = "123456789"
    private let productDescription = LoremIpsum.medium
    private let paymentRequestId = PaymentRequestId("WXYZ-ABCD-1234-5678")

    func test_make_forCreating_SingleRequestType() throws {
        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            value: amount,
            selectedCurrency: currency,
            eligibleBalances: .build(
                balances: [
                    .build(currency: currency),
                    .build(currency: .EUR),
                ]
            ),
            selectedBalanceId: balanceId,
            reference: reference,
            productDescription: productDescription,
            paymentMethods: []
        )

        let requestBody = try CreatePaymentRequestBodyBuilder.make(
            requestType: .singleUse,
            paymentRequestInfo: paymentRequestInfo
        )

        let body = PaymentRequestSingleUseBody(
            balanceId: balanceId.value,
            selectedPaymentMethods: [],
            amountValue: amount,
            description: productDescription,
            message: nil,
            payer: nil
        )

        let expected = PaymentRequestBodyV2.singleUse(body)

        expectNoDifference(requestBody, expected)
    }

    func test_make_forCreating_ReusableRequestType() throws {
        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            value: amount,
            selectedCurrency: currency,
            eligibleBalances: .build(
                balances: [
                    .build(currency: currency),
                    .build(currency: .EUR),
                ]
            ),
            selectedBalanceId: balanceId,
            reference: reference,
            productDescription: productDescription,
            paymentMethods: []
        )

        let requestBody = try CreatePaymentRequestBodyBuilder.make(
            requestType: .reusable,
            paymentRequestInfo: paymentRequestInfo
        )

        let body = PaymentRequestReusableBody(
            balanceId: balanceId.value,
            selectedPaymentMethods: [],
            amountValue: amount,
            description: productDescription
        )

        let expected = PaymentRequestBodyV2.reusable(body)

        expectNoDifference(requestBody, expected)
    }

    func test_make_forCreating_givenEmptyAmount_thenThrowsCorrectError() {
        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            value: nil,
            selectedCurrency: currency,
            eligibleBalances: .build(balances: [
                .build(currency: currency),
                .build(currency: .EUR),
            ]
            ),
            selectedBalanceId: balanceId,
            reference: reference,
            productDescription: productDescription,
            paymentMethods: [.card]
        )

        XCTAssertThrowsError(
            try CreatePaymentRequestBodyBuilder.make(
                requestType: .singleUse,
                paymentRequestInfo: paymentRequestInfo
            )
        ) { error in
            XCTAssertEqual(
                error as? CreatePaymentRequestBodyBuilderError,
                .invalidAmount(reason: "Please enter an amount to request")
            )
        }
    }

    func test_make_forCreating_givenNegativeAmount_thenThrowsCorrectError() {
        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            value: -10,
            selectedCurrency: currency,
            eligibleBalances: .build(
                balances: [
                    .build(currency: currency),
                    .build(currency: .EUR),
                ]
            ),
            selectedBalanceId: balanceId,
            reference: reference,
            productDescription: productDescription,
            paymentMethods: [.card]
        )

        XCTAssertThrowsError(
            try CreatePaymentRequestBodyBuilder.make(
                requestType: .singleUse,
                paymentRequestInfo: paymentRequestInfo
            )
        ) { error in
            XCTAssertEqual(
                error as? CreatePaymentRequestBodyBuilderError,
                .invalidAmount(reason: "Please enter an amount greater than 0")
            )
        }
    }
}
