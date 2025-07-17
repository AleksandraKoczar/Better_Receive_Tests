import ReceiveKit
import TWUI
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentDetailsViewControllerFactory {
    // sourcery: mockName = "makeWithTransactionId"
    static func make(
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transactionId: AcquiringTransactionId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) -> UIViewController
    // sourcery: mockName = "makeWithTransferId"
    static func make(
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transferId: ReceiveTransferId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) -> UIViewController
}

enum PaymentDetailsViewControllerFactoryImpl: PaymentDetailsViewControllerFactory {
    static func make(
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transactionId: AcquiringTransactionId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) -> UIViewController {
        let router = PaymentDetailsRouterImpl(
            paymentRequestId: paymentRequestId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            webViewControllerFactory: webViewControllerFactory
        )
        let interactor = AcquiringTransactionPaymentDetailsInteractor(transactionId: transactionId)
        let presenter = PaymentDetailsPresenterImpl(
            profileId: profileId,
            router: router,
            interactor: interactor
        )
        return PaymentDetailsViewController(presenter: presenter)
    }

    static func make(
        profileId: ProfileId,
        paymentRequestId: PaymentRequestId,
        transferId: ReceiveTransferId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) -> UIViewController {
        let router = PaymentDetailsRouterImpl(
            paymentRequestId: paymentRequestId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            webViewControllerFactory: webViewControllerFactory
        )
        let interactor = TransferPaymentDetailsInteractor(
            paymentRequestId: paymentRequestId,
            transferId: transferId
        )
        let presenter = PaymentDetailsPresenterImpl(
            profileId: profileId,
            router: router,
            interactor: interactor
        )
        return PaymentDetailsViewController(presenter: presenter)
    }
}
