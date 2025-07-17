import Foundation
import ReceiveKit
import WiseCore

// sourcery: AutoEquatableForTest
enum ReceiveMethodNavigationAction {
    case order(
        currency: CurrencyCode?,
        balanceId: BalanceId?,
        methodType: ReceiveMethodNavigationViewType
    )
    case query(
        context: ReceiveMethodNavigationViewContext,
        currency: CurrencyCode?,
        groupId: GroupId?,
        balanceId: BalanceId?,
        methodTypes: [ReceiveMethodNavigationViewType]?
    )
    case view(
        id: AccountDetailsId,
        methodType: ReceiveMethodNavigationViewType
    )
}
