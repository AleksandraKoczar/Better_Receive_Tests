import Neptune
import TWFoundation
import UIKit
import UserKit

// sourcery: AutoMockable
public protocol MultipleAccountDetailsProfileCreationFlowFactory {
    func make(
        navigationController: UINavigationController,
        clearNavigation: Bool
    ) -> any Flow<MultipleAccountDetailsProfileCreationFlowResult>
}
