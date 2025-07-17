import TWFoundation
import UIKit
import WiseCore

public struct ReceiveMethodsQRSharingFlowFactoryImpl {
    public init() {}

    public func make(
        balanceId: BalanceId,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        hostController: UIViewController
    ) -> any Flow<Void> {
        ReceiveMethodsQRSharingFlow(
            balanceId: balanceId,
            accountDetailsId: accountDetailsId,
            profileId: profileId,
            hostController: hostController
        )
    }
}
