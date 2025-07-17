import Foundation
import ReceiveKit
import WiseCore

// sourcery: AutoMockable
protocol QuickpayPayerRouter: AnyObject {
    func showCurrencySelector(
        activeCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: @escaping (CurrencyCode) -> Void
    )
    func navigateToPayWithWise(payerData: QuickpayPayerData)
    func dismiss()
}
