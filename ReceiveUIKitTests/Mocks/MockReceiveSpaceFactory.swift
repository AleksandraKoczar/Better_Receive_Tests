import ReceiveUIKit
import UIKit

public final class MockReceiveSpaceFactory: ReceiveSpaceFactoryProtocol {
    public static let viewTag = 65536
    public static func make(
        navigationController: UINavigationController,
        hasBalanceAccount: Bool
    ) -> UIViewController {
        let vc = UIViewController()
        vc.view.tag = viewTag
        return vc
    }
}
