import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class CreatePaymentRequestPresenterInfoTests: TWTestCase {
    private let value: Decimal = 0.07
    private let currency = CurrencyCode("GBP")
    private let balanceId = BalanceId(789)
    private let message = "message"
    private let reference = "reference"
    private let productDescription = "product description"
    private let paymentMethods = [PaymentMethodTypeV2.card]

    func test_updateWithPaymentRequest() {
        let paymentRequest = PaymentRequestV2.build(
            amount: .build(currency: currency, value: value),
            balanceId: balanceId,
            message: nil,
            description: productDescription, reference: reference,
            dueAt: nil,
            selectedPaymentMethods: paymentMethods
        )

        var info = CreatePaymentRequestPresenterInfo(
            defaultBalance: .canned,
            eligibleBalances: .canned
        )

        info.update(request: paymentRequest)

        let expected = CreatePaymentRequestPresenterInfo(
            value: value,
            selectedCurrency: currency,
            eligibleBalances: .canned,
            selectedBalanceId: balanceId,
            reference: reference,
            productDescription: productDescription,
            paymentMethods: CreatePaymentRequestPaymentMethodMapper.mapToAcquiringPaymentMethod(types: paymentMethods)
        )

        expectNoDifference(info, expected)
    }
}
