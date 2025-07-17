import DeepLinkKit
import Neptune
import TWFoundation
import UIKit

// sourcery: AutoMockable
public protocol SingleAccountDetailsFlowFactory {
    func make(
        hostViewController: UIViewController,
        route: DeepLinkAccountDetailsRoute?,
        invocationContext: AccountDetailsFlowInvocationContext
    ) -> any Flow<AccountDetailsFlowResult>
}
