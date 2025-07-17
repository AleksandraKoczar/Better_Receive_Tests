import ReceiveKit
import TWUI
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentLinkViewControllerFactory {
    func makePaymentDetails(
        paymentRequestId: PaymentRequestId,
        acquiringPaymentId: AcquiringPaymentId,
        profileId: ProfileId,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        navigationController: UINavigationController,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) -> UIViewController
}

struct PaymentLinkViewControllerFactoryImpl: PaymentLinkViewControllerFactory {
    func makePaymentDetails(
        paymentRequestId: PaymentRequestId,
        acquiringPaymentId: AcquiringPaymentId,
        profileId: ProfileId,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        navigationController: UINavigationController,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) -> UIViewController {
        let router = PaymentLinkPaymentDetailsRouterImpl(
            paymentRequestId: paymentRequestId,
            profileId: profileId,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            navigationController: navigationController,
            webViewControllerFactory: webViewControllerFactory
        )
        let presenter = PaymentLinkPaymentDetailsPresenterImpl(
            paymentRequestId: paymentRequestId,
            acquiringPaymentId: acquiringPaymentId,
            profileId: profileId,
            router: router
        )
        return PaymentLinkPaymentDetailsViewController(presenter: presenter)
    }
}
