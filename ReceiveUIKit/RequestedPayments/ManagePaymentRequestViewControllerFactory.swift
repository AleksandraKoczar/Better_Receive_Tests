import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
protocol ManagePaymentRequestViewControllerFactory {
    func makePaymentRquestList(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        visibleState: PaymentRequestSummaryList.State,
        profile: Profile,
        navigationController: UINavigationController,
        flowDismissed: @escaping () -> Void
    ) -> UIViewController
}

struct ManagePaymentRequestViewControllerFactoryImpl: ManagePaymentRequestViewControllerFactory {
    private let currencySelectorFactory: ReceiveCurrencySelectorFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let helpCenterArticleFactory: HelpCenterArticleFactory

    init(
        currencySelectorFactory: ReceiveCurrencySelectorFactory,
        webViewControllerFactory: WebViewControllerFactory.Type,
        helpCenterArticleFactory: HelpCenterArticleFactory
    ) {
        self.currencySelectorFactory = currencySelectorFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.helpCenterArticleFactory = helpCenterArticleFactory
    }

    func makePaymentRquestList(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        visibleState: PaymentRequestSummaryList.State,
        profile: Profile,
        navigationController: UINavigationController,
        flowDismissed: @escaping () -> Void
    ) -> UIViewController {
        let router = PaymentRequestsListRouterImpl(
            navigationController: navigationController,
            currencySelectorFactory: currencySelectorFactory,
            webViewControllerFactory: webViewControllerFactory,
            helpCenterArticleFactory: helpCenterArticleFactory
        )
        let presenter = PaymentRequestsListPresenterImpl(
            supportedPaymentRequestType: supportedPaymentRequestType,
            visibleState: visibleState,
            profile: profile,
            router: router,
            flowDismissed: flowDismissed
        )
        return PaymentRequestsListViewController(presenter: presenter)
    }
}
