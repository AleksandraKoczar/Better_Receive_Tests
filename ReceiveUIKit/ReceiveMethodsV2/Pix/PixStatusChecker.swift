import BalanceKit
import Foundation
import ReceiveKit
import WiseCore

public struct PixStatusChecker {
    private init() {}

    public static func isPixAvailableAccountDetails(
        accountDetails: ActiveAccountDetails
    ) -> Bool {
        accountDetails.currency == .BRL
            && !accountDetails.isDeprecated
    }

    static func hasPixAliasRegistered(
        aliases: [ReceiveMethodAlias]
    ) -> Bool {
        aliases.contains { alias in
            alias.aliasScheme.uppercased() == "PIX"
                && (
                    alias.state == .registered
                        || alias.state == .pendingRegistration
                )
        }
    }
}
