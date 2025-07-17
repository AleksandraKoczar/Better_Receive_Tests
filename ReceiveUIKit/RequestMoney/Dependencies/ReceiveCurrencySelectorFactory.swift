import Foundation
import TWUI
import UIKit
import WiseCore

// sourcery: AutoMockable
public protocol ReceiveCurrencySelectorFactory {
    func makeSelector(
        currencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        itemSelectedHandler: @escaping (CurrencyCode) -> Void
    ) -> UIViewController

    func makeSectionedSelector(
        openCurrencies: [CurrencyCode],
        inactiveCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        itemSelectedHandler: @escaping (CurrencyCode) -> Void
    ) -> UIViewController
}
