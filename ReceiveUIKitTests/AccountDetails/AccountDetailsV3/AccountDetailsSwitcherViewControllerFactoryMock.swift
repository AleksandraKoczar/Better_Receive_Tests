@testable import ReceiveUIKit
import UIKit
import UserKit

final class AccountDetailsV3SwitcherViewControllerFactoryMock: AccountDetailsV3SwitcherViewControllerFactory {
    // MARK: - make

    internal var makeReceivedArguments: (profile: Profile, actionHandler: ReceiveMethodActionHandler)?
    internal var makeReceivedInvocations: [(profile: Profile, actionHandler: ReceiveMethodActionHandler)] = []
    internal var makeReturnValue: UIViewController!
    internal private(set) var makeCallsCount = 0
    internal var makeClosure: ((Profile, ReceiveMethodActionHandler) -> UIViewController)?
    internal var makeCalled: Bool {
        makeCallsCount > 0
    }

    internal func make(profile: Profile, actionHandler: ReceiveMethodActionHandler) -> UIViewController {
        makeCallsCount += 1
        makeReceivedArguments = (profile: profile, actionHandler: actionHandler)
        makeReceivedInvocations.append((profile: profile, actionHandler: actionHandler))
        return makeClosure.map { $0(profile, actionHandler) } ?? makeReturnValue
    }
}
