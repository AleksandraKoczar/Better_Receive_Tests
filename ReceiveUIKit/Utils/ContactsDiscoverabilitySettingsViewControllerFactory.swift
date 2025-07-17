import Foundation
import UIKit
import WiseCore

// sourcery: AutoMockable
public protocol ContactsDiscoverabilitySettingsViewControllerFactoryProtocol: AnyObject {
    func make(
        navigationController: UINavigationController,
        profileId: ProfileId
    ) -> UIViewController
}
