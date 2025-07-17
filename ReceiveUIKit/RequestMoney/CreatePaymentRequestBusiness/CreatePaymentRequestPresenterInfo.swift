import BalanceKit
import Foundation
import LoggingKit
import ReceiveKit
import TWFoundation
import WiseCore

// sourcery: AutoEquatableForTest
struct CreatePaymentRequestPresenterInfo {
    var value: Decimal?
    var selectedCurrency: CurrencyCode
    var eligibleBalances: PaymentRequestEligibleBalances
    var selectedBalanceId: BalanceId
    var reference: String?
    var productDescription: String?
    var paymentMethods: [AcquiringPaymentMethodType]
}

extension CreatePaymentRequestPresenterInfo {
    init(
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances
    ) {
        self.eligibleBalances = eligibleBalances
        selectedBalanceId = defaultBalance.id
        selectedCurrency = defaultBalance.currency
        paymentMethods = []
    }

    func fetchPaymentMethods() -> [PaymentRequestV2PaymentMethods] {
        paymentMethods.compactMap { method in
            switch method {
            case .applePay:
                .applePay
            case .bankTransfer:
                .bankTransfer
            case .card:
                .card
            case .payWithWise:
                .payWithWise
            case .payNow:
                .payNow
            case .pisp:
                .pisp
            }
        }
    }

    mutating func updatePaymentMethods(methods: [PaymentRequestV2PaymentMethods]) {
        paymentMethods = methods.compactMap { method in
            switch method {
            case .applePay:
                .applePay
            case .card:
                .card
            case .payWithWise:
                .payWithWise
            case .pisp:
                .pisp
            case .bankTransfer:
                .bankTransfer
            case .payNow:
                .payNow
            case .unknown:
                nil
            }
        }
    }

    mutating func update(request: PaymentRequestV2) {
        value = request.amount.value
        selectedCurrency = request.amount.currency
        reference = request.reference
        selectedBalanceId = request.balanceId
        productDescription = request.description
        paymentMethods = CreatePaymentRequestPaymentMethodMapper.mapToAcquiringPaymentMethod(types: request.selectedPaymentMethods)
    }
}
