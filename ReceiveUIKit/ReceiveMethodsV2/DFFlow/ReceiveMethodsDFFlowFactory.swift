import TWFoundation
import UIKit
import WiseCore

public enum ReceiveMethodsDFFlowMode {
    case manage
    case register
}

// sourcery: AutoMockable
public protocol ReceiveMethodsDFFlowFactory {
    func make(
        mode: ReceiveMethodsDFFlowMode,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        hostViewController: UIViewController
    ) -> any Flow<ReceiveMethodsDFFlowResult>
}

public struct ReceiveMethodsDFFlowFactoryImpl: ReceiveMethodsDFFlowFactory {
    public init() {}

    public func make(
        mode: ReceiveMethodsDFFlowMode,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        hostViewController: UIViewController
    ) -> any Flow<ReceiveMethodsDFFlowResult> {
        ReceiveMethodsDFFlow(
            mode: mode,
            accountDetailsId: accountDetailsId,
            profileId: profileId,
            hostViewController: hostViewController
        )
    }
}
