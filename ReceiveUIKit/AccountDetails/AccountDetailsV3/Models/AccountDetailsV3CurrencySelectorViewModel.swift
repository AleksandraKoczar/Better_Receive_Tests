import Foundation
import WiseCore

struct AccountDetailsV3CurrencySelectorViewModel {
    let title: String
    let subtitle: String
    let currency: CurrencyCode
    let isOnTapEnabled: Bool
    let onTap: (() -> Void)?
}
