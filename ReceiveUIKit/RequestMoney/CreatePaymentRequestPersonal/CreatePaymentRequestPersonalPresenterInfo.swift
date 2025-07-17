import BalanceKit
import Foundation
import LoggingKit
import ReceiveKit
import TWFoundation
import WiseCore

// sourcery: AutoEquatableForTest
struct CreatePaymentRequestPersonalPresenterInfo {
    let contact: RequestMoneyContact?
    var value: Decimal?
    var selectedCurrency: CurrencyCode
    var eligibleBalances: PaymentRequestEligibleBalances
    var selectedBalanceId: BalanceId
    var message: String?
    var PWWAlert: PWWAlert?
    var paymentMethods: [PaymentMethodTypeV2]
}

extension CreatePaymentRequestPersonalPresenterInfo {
    init(
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances,
        contact: RequestMoneyContact?
    ) {
        self.contact = contact
        self.eligibleBalances = eligibleBalances
        selectedBalanceId = defaultBalance.id
        selectedCurrency = defaultBalance.currency
        paymentMethods = []
        PWWAlert = nil
    }

    mutating func update(request: PaymentRequestV2) {
        value = request.amount.value
        selectedCurrency = request.amount.currency
        message = request.message
        selectedBalanceId = request.balanceId
        paymentMethods = request.selectedPaymentMethods
    }
}
