import BalanceKit

// sourcery: CaseNameAnalyticsIdentifyable
enum AccountDetailsReceiveOptionReceiveType {
    case local
    case international
}

// MARK: - AccountDetailsReceiveOption.ReceiveType

extension AccountDetailsReceiveOptionReceiveType {
    init(type: AccountDetailsReceiveOption.ReceiveType) {
        switch type {
        case .local:
            self = .local
        case .international:
            self = .international
        }
    }
}
