import UIKit
import UserKit

// sourcery: AutoMockable
public protocol MultipleAccountDetailsIneligibilityFactory {
    func makeView(
        router: MultipleAccountDetailsIneligibilityRouter,
        profile: Profile
    ) -> UIViewController
}
