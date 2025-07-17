import Neptune
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol GetPaidOptionsFlowFactory: AnyObject {
    func makeFlow(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void>
}

public class GetPaidOptionsFlowFactoryImpl: GetPaidOptionsFlowFactory {
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let requestMoneyFlowFactory: RequestMoneyFlowFactory

    public init(
        webViewControllerFactory: WebViewControllerFactory.Type,
        requestMoneyFlowFactory: RequestMoneyFlowFactory
    ) {
        self.webViewControllerFactory = webViewControllerFactory
        self.requestMoneyFlowFactory = requestMoneyFlowFactory
    }

    public func makeFlow(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        GetPaidOptionsFlow(
            profile: profile,
            navigationController: navigationController,
            requestMoneyFlowFactory: requestMoneyFlowFactory,
            webViewControllerFactory: webViewControllerFactory,
            viewControllerPresenterFactory: ViewControllerPresenterFactoryImpl()
        )
    }
}
