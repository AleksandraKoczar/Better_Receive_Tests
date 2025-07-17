import MacrosKit
import TWFoundation
import UIKit

@MainActor @preconcurrency
@Mock
public protocol ReceiveInviteFlowFactory {
    func make(navigationHost: UINavigationController) -> any Flow<Void>
}
