import Foundation

// sourcery: Buildable
public enum AccountDetailsInfoInvocationSource {
    case balanceHeaderAction
    case orderAccountDetailsFlow
    case directDebits
    case accountDetailsList
    case accountDetailsIntro
    case launchpad

    public var analyticsValue: String {
        switch self {
        case .balanceHeaderAction:
            "Balance Header Action"
        case .orderAccountDetailsFlow:
            "Order Bank Details Flow"
        case .directDebits:
            "Direct Debits"
        case .accountDetailsList:
            "Bank Details List"
        case .accountDetailsIntro:
            "Bank Details Intro"
        case .launchpad:
            "Launchpad"
        }
    }
}
