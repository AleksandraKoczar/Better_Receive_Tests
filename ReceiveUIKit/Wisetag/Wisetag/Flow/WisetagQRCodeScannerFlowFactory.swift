import DeepLinkKit
import TransferResources
import TWFoundation
import UIKit

public enum WisetagQRCodeResultType {
    case route(DeepLinkRoute)
    case userCancelled
    case error
}

// sourcery: AutoMockable
public protocol WisetagQRCodeScannerFlowFactory {
    static func make(host: UINavigationController) -> any Flow<WisetagQRCodeResultType>
}
