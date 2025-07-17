import TWFoundation
import UserKit

public enum MultipleAccountDetailsIneligibilityRouterAction {
    case proceed(Profile)
}

public protocol MultipleAccountDetailsIneligibilityRouter {
    func route(action: MultipleAccountDetailsIneligibilityRouterAction)
}
