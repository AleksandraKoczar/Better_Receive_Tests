import TWFoundation
import UIKit

public enum ProfileSwitcherFlowResult {
    case completed
}

// sourcery: AutoMockable
public protocol ProfileSwitcherFlowFactory: AnyObject {
    func makeFlow(rootViewController: UIViewController) -> any Flow<ProfileSwitcherFlowResult>
}
