import Foundation
import TWFoundation
import WiseCore

public enum AccountDetailsMultipleSelectionRouterAction: Equatable {
    case currenciesSelected(_ currencies: [CurrencyCode])
    case learnMore
    case wishList(completion: () -> Void)

    public static func == (lhs: AccountDetailsMultipleSelectionRouterAction, rhs: AccountDetailsMultipleSelectionRouterAction) -> Bool {
        switch (lhs, rhs) {
        case let (.currenciesSelected(lhsCurrencies), .currenciesSelected(rhsCurrencies)):
            lhsCurrencies == rhsCurrencies
        case (.learnMore, .learnMore):
            true
        case (.wishList, .wishList):
            true
        default:
            false
        }
    }
}

public protocol AccountDetailsMultipleSelectionRouter {
    func route(action: AccountDetailsMultipleSelectionRouterAction)
}
