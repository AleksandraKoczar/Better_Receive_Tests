import Neptune
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

public enum InvoiceCreationFlowEntryPoint {
    case launchpad
    case paymentsTab
    case deepLink
}

// sourcery: AutoMockable
public protocol InvoiceCreationFlowFactory: AnyObject {
    func makeModalFlow(
        profile: Profile,
        rootViewController: UIViewController,
        entryPoint: InvoiceCreationFlowEntryPoint
    ) -> any Flow<Void>
}

public class InvoiceCreationFlowFactoryImpl: InvoiceCreationFlowFactory {
    private let webViewControllerFactory: WebViewControllerFactory.Type

    public init(
        webViewControllerFactory: WebViewControllerFactory.Type
    ) {
        self.webViewControllerFactory = webViewControllerFactory
    }

    public func makeModalFlow(
        profile: Profile,
        rootViewController: UIViewController,
        entryPoint: InvoiceCreationFlowEntryPoint
    ) -> any Flow<Void> {
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        let flow = InvoiceCreationFlow(
            profile: profile,
            entryPoint: entryPoint,
            navigationController: navigationController,
            webViewControllerFactory: webViewControllerFactory
        )
        return ModalPresentationFlow(
            flow: flow,
            rootViewController: rootViewController,
            flowController: navigationController
        )
    }
}
