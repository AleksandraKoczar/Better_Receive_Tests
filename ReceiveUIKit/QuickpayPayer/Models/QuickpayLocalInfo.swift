import Foundation
import WiseCore

struct QuickpayLocalInfo {
    let eligibleBalances: [CurrencyCode]
    private(set) var selectedCurrency: CurrencyCode
    private(set) var amount: Decimal?

    init(
        eligibleBalances: [CurrencyCode],
        selectedCurrency: CurrencyCode
    ) {
        self.eligibleBalances = eligibleBalances
        self.selectedCurrency = selectedCurrency
        amount = nil
    }

    mutating func updateAmount(amount: Decimal?) {
        self.amount = amount
    }

    mutating func updateSelectedCurrency(currency: CurrencyCode) {
        selectedCurrency = currency
    }
}
