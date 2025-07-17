import Foundation
import WiseCore

public enum SalarySwitchFlowAccountDetailsRequirementStatus: Equatable {
    case hasActiveAccountDetails(balanceId: BalanceId)
    case needsAccountDetailsActivation
}
