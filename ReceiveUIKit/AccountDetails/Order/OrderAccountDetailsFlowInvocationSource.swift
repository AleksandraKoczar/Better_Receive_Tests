import Foundation

public enum OrderAccountDetailsFlowInvocationSource {
    case onboarding
    case accountTab
    case balanceCard
    case directDebit
    case salarySwitch
    case launchpad

    public var name: String {
        switch self {
        case .onboarding:
            "Onboarding"
        case .accountTab:
            "Account tab"
        case .balanceCard:
            "Balance card"
        case .directDebit:
            "Direct Debit"
        case .salarySwitch:
            "Salary switch"
        case .launchpad:
            "Launchpad"
        }
    }
}
