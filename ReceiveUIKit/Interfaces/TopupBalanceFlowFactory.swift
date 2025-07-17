import Foundation
import TWFoundation
import UIKit
import UserKit
import WiseCore

public enum TopUpBalanceFlowResult {
    case completed
    case aborted
}

// sourcery: AutoMockable
public protocol TopUpBalanceFlowFactory {
    func makeModalFlow(
        profile: Profile,
        targetCurrencies: [CurrencyCode],
        targetAmount: Decimal?,
        minimumAmounts: [Money],
        rootViewController: UIViewController
    ) -> any Flow<TopUpBalanceFlowResult>
}
