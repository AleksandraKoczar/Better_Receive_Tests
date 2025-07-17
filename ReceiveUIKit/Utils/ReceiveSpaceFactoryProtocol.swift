import Foundation
import UIKit

public protocol ReceiveSpaceFactoryProtocol {
    @MainActor
    static func make(
        navigationController: UINavigationController,
        hasBalanceAccount: Bool
    ) -> UIViewController
}
