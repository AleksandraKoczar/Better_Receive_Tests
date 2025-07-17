import Neptune
import TWFoundation
import UIKit
import UserKit

// sourcery: AutoMockable
public protocol MultipleAccountDetailsOrderFlowFactory {
    func make(
        navigationController: UINavigationController,
        profile: Profile
    ) -> any Flow<MultipleAccountDetailsOrderFlowResult>
}

// sourcery: AutoMockable
public protocol MultipleAccountDetailsOrderFlowWithUpsellConfigurationFactory {
    func make(
        navigationController: UINavigationController,
        profile: Profile,
        showUpsell: Bool
    ) -> any Flow<MultipleAccountDetailsOrderFlowResult>
}
