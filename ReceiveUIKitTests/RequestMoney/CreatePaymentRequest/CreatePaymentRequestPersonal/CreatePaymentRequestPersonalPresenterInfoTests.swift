import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class CreatePaymentRequestPersonalPresenterInfoTests: TWTestCase {
    private let value: Decimal = 0.07
    private let currency = CurrencyCode("GBP")
    private let balanceId = BalanceId(789)
    private let message = "message"
    private let paymentMethods = [AcquiringPaymentMethodType.card]

    func test_updateWithPaymentRequest() {
        let paymentRequest = PaymentRequestV2.build(
            id: PaymentRequestId.canned,
            amount: .build(currency: currency, value: value),
            profileId: ProfileId.canned,
            balanceId: balanceId,
            creator: .canned,
            message: message,
            description: .canned,
            status: .canned,
            reference: .canned,
            link: .canned,
            createdAt: .canned,
            publishedAt: .canned,
            dueAt: .canned,
            expirationAt: .canned,
            invalidatedAt: .canned,
            updatedAt: .canned,
            attachments: .canned,
            selectedPaymentMethods: mapPaymentMethods(types: paymentMethods),
            completedAt: .canned,
            payerSummary: .canned,
            invoice: nil
        )

        var info = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: .canned,
            eligibleBalances: .canned,
            contact: nil
        )

        info.update(request: paymentRequest)

        let expected = CreatePaymentRequestPersonalPresenterInfo(
            contact: nil,
            value: value,
            selectedCurrency: currency,
            eligibleBalances: .canned,
            selectedBalanceId: balanceId,
            message: message,
            paymentMethods: mapPaymentMethods(types: paymentMethods)
        )

        expectNoDifference(info, expected)
    }

    private func mapPaymentMethods(types: [AcquiringPaymentMethodType]) -> [PaymentMethodTypeV2] {
        types.map { method in
            switch method {
            case .applePay:
                PaymentMethodTypeV2.applePay
            case .bankTransfer:
                PaymentMethodTypeV2.bankTransfer
            case .card:
                PaymentMethodTypeV2.card
            case .payWithWise:
                PaymentMethodTypeV2.payWithWise
            case .payNow:
                PaymentMethodTypeV2.payNow
            case .pisp:
                PaymentMethodTypeV2.pisp
            }
        }
    }
}
