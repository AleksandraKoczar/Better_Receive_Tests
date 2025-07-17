import LoggingKit
import ReceiveKit
import TWUI
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentLinkPaymentDetailsRouter: AnyObject {
    func showAcquiringTransactionPaymentDetails(transactionId: AcquiringTransactionId)
    func showTransferPaymentDetails(transferId: ReceiveTransferId)
}

final class PaymentLinkPaymentDetailsRouterImpl {
    private weak var paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate?
    private weak var navigationController: UINavigationController?

    private let paymentRequestId: PaymentRequestId
    private let profileId: ProfileId
    private let paymentDetailsViewControllerFactory: PaymentDetailsViewControllerFactory.Type
    private let webViewControllerFactory: WebViewControllerFactory.Type

    init(
        paymentRequestId: PaymentRequestId,
        profileId: ProfileId,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        navigationController: UINavigationController,
        webViewControllerFactory: WebViewControllerFactory.Type,
        paymentDetailsViewControllerFactory: PaymentDetailsViewControllerFactory.Type = PaymentDetailsViewControllerFactoryImpl.self
    ) {
        self.paymentDetailsRefundFlowDelegate = paymentDetailsRefundFlowDelegate
        self.navigationController = navigationController
        self.paymentRequestId = paymentRequestId
        self.profileId = profileId
        self.paymentDetailsViewControllerFactory = paymentDetailsViewControllerFactory
        self.webViewControllerFactory = webViewControllerFactory
    }
}

// MARK: - PaymentLinkPaymentDetailsRouter

extension PaymentLinkPaymentDetailsRouterImpl: PaymentLinkPaymentDetailsRouter {
    func showAcquiringTransactionPaymentDetails(transactionId: AcquiringTransactionId) {
        guard let navigationController,
              let delegate = paymentDetailsRefundFlowDelegate else {
            softFailure("[REC] Attempt to show payment details with transaction id \(transactionId) without navigation controller or refund flow delegate.")
            return
        }
        let viewController = paymentDetailsViewControllerFactory.make(
            profileId: profileId,
            paymentRequestId: paymentRequestId,
            transactionId: transactionId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: delegate,
            webViewControllerFactory: webViewControllerFactory
        )
        navigationController.pushViewController(viewController, animated: UIView.shouldAnimate)
    }

    func showTransferPaymentDetails(transferId: ReceiveTransferId) {
        guard let navigationController,
              let delegate = paymentDetailsRefundFlowDelegate else {
            softFailure("[REC] Attempt to show payment details with transfer id \(transferId) without navigation controller or refund flow delegate.")
            return
        }
        let viewController = paymentDetailsViewControllerFactory.make(
            profileId: profileId,
            paymentRequestId: paymentRequestId,
            transferId: transferId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: delegate,
            webViewControllerFactory: webViewControllerFactory
        )
        navigationController.pushViewController(viewController, animated: UIView.shouldAnimate)
    }
}
