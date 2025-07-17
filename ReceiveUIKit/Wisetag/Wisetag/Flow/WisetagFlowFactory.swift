import DeepLinkKit
import Neptune
import TWFoundation
import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
public protocol WisetagFlowFactory {
    func makeFlow(
        shouldBecomeDiscoverable: Bool,
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<WisetagFlowResult>
}

public class WisetagFlowFactoryImpl: WisetagFlowFactory {
    private let scannedProfileFlowFactory: WisetagScannedProfileFlowFactory
    private let scannerFlowFactory: WisetagQRCodeScannerFlowFactory.Type
    private let accountDetailsFlowFactory: SingleAccountDetailsFlowFactory
    private let allDeepLinksUIFactory: AllDeepLinksUIFactory

    public init(
        scannedProfileFlowFactory: WisetagScannedProfileFlowFactory,
        scannerFlowFactory: WisetagQRCodeScannerFlowFactory.Type,
        accountDetailsFlowFactory: SingleAccountDetailsFlowFactory,
        allDeepLinksUIFactory: AllDeepLinksUIFactory
    ) {
        self.scannedProfileFlowFactory = scannedProfileFlowFactory
        self.scannerFlowFactory = scannerFlowFactory
        self.accountDetailsFlowFactory = accountDetailsFlowFactory
        self.allDeepLinksUIFactory = allDeepLinksUIFactory
    }

    public func makeFlow(
        shouldBecomeDiscoverable: Bool,
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<WisetagFlowResult> {
        WisetagFlow(
            shouldBecomeDiscoverable: shouldBecomeDiscoverable,
            profile: profile,
            viewControllerFactory: WisetagViewControllerFactoryImpl(),
            qrDownloadViewControllerFactory: QRDownloadViewControllerFactoryImpl(),
            scannerFlowFactory: scannerFlowFactory,
            allDeepLinksUIFactory: allDeepLinksUIFactory,
            scannedProfileFlowFactory: scannedProfileFlowFactory,
            accountDetailsFlowFactory: accountDetailsFlowFactory,
            viewControllerPresenterFactory: ViewControllerPresenterFactoryImpl(),
            cameraRollPermissionFlowFactory: CameraPermissionFlowFactoryImpl(),
            navigationController: navigationController
        )
    }
}
