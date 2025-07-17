import LoggingKit
import ReceiveKit
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol ManagePaymentRequestsFlowFactory {
    func makePaymentRequestListWithClosestToExpiryVisible(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void>

    func makePaymentRequestListWithMostRecentlyRequestedVisible(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void>

    func makePaymentRequestListForInvoices(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void>

    func makePaymentRequestDetailsFlow(
        profile: Profile,
        paymentRequestId: PaymentRequestId,
        navigationController: UINavigationController
    ) -> any Flow<Void>
}

public final class ManagePaymentRequestsFlowFactoryImpl: ManagePaymentRequestsFlowFactory {
    private let currencySelectorFactory: ReceiveCurrencySelectorFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let helpCenterArticleFactory: HelpCenterArticleFactory

    public init(
        currencySelectorFactory: ReceiveCurrencySelectorFactory,
        webViewControllerFactory: WebViewControllerFactory.Type,
        helpCenterArticleFactory: HelpCenterArticleFactory
    ) {
        self.currencySelectorFactory = currencySelectorFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.helpCenterArticleFactory = helpCenterArticleFactory
    }

    public func makePaymentRequestListWithClosestToExpiryVisible(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        makePaymentRequestListFlow(
            shouldSupportInvoiceOnly: false,
            shouldShowMostRecentlyRequestedIfApplicable: false,
            profile: profile,
            navigationController: navigationController
        )
    }

    public func makePaymentRequestListWithMostRecentlyRequestedVisible(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        makePaymentRequestListFlow(
            shouldSupportInvoiceOnly: false,
            shouldShowMostRecentlyRequestedIfApplicable: true,
            profile: profile,
            navigationController: navigationController
        )
    }

    public func makePaymentRequestListForInvoices(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        makePaymentRequestListFlow(
            shouldSupportInvoiceOnly: true,
            shouldShowMostRecentlyRequestedIfApplicable: false,
            profile: profile,
            navigationController: navigationController
        )
    }

    public func makePaymentRequestDetailsFlow(
        profile: Profile,
        paymentRequestId: PaymentRequestId,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        ManagePaymentRequestDetailsFlow(
            profile: profile,
            paymentRequestId: paymentRequestId,
            navigationController: navigationController,
            webViewControllerFactory: webViewControllerFactory
        )
    }
}

// MARK: - Helper

private extension ManagePaymentRequestsFlowFactoryImpl {
    func makePaymentRequestListFlow(
        shouldSupportInvoiceOnly: Bool,
        shouldShowMostRecentlyRequestedIfApplicable: Bool,
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        let viewControllerFactory = ManagePaymentRequestViewControllerFactoryImpl(
            currencySelectorFactory: currencySelectorFactory,
            webViewControllerFactory: webViewControllerFactory,
            helpCenterArticleFactory: helpCenterArticleFactory
        )
        return ManagePaymentRequestsFlow(
            shouldSupportInvoiceOnly: shouldSupportInvoiceOnly,
            shouldShowMostRecentlyRequestedIfApplicable: shouldShowMostRecentlyRequestedIfApplicable,
            profile: profile,
            viewControllerFactory: viewControllerFactory,
            navigationController: navigationController
        )
    }
}
