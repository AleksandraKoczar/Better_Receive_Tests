import Foundation
import ReceiveKit
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentLinkAllPaymentsRouter: AnyObject {
    func showPaymentLinkPaymentDetails(acquiringPaymentId: AcquiringPaymentId)
    func showAcquiringTransactionPaymentDetails(transactionId: AcquiringTransactionId)
    func showTransferPaymentDetails(transferId: ReceiveTransferId)
}

final class PaymentLinkAllPaymentsRouterImpl {
    weak var paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate?

    private weak var navigationController: UINavigationController?
    private let profile: Profile
    private let paymentRequestId: PaymentRequestId
    private let paymentLinkViewControllerFactory: PaymentLinkViewControllerFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let paymentDetailsViewControllerFactory: PaymentDetailsViewControllerFactory.Type

    init(
        navigationController: UINavigationController,
        profile: Profile,
        paymentRequestId: PaymentRequestId,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type,
        paymentLinkViewControllerFactory: PaymentLinkViewControllerFactory = PaymentLinkViewControllerFactoryImpl(),
        paymentDetailsViewControllerFactory: PaymentDetailsViewControllerFactory.Type = PaymentDetailsViewControllerFactoryImpl.self
    ) {
        self.navigationController = navigationController
        self.profile = profile
        self.paymentRequestId = paymentRequestId
        self.paymentDetailsRefundFlowDelegate = paymentDetailsRefundFlowDelegate
        self.paymentLinkViewControllerFactory = paymentLinkViewControllerFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.paymentDetailsViewControllerFactory = paymentDetailsViewControllerFactory
    }
}

extension PaymentLinkAllPaymentsRouterImpl: PaymentLinkAllPaymentsRouter {
    func showPaymentLinkPaymentDetails(acquiringPaymentId: ReceiveKit.AcquiringPaymentId) {
        guard let navigationController,
              let delegate = paymentDetailsRefundFlowDelegate else {
            return
        }
        let viewController = paymentLinkViewControllerFactory.makePaymentDetails(
            paymentRequestId: paymentRequestId,
            acquiringPaymentId: acquiringPaymentId,
            profileId: profile.id,
            paymentDetailsRefundFlowDelegate: delegate,
            navigationController: navigationController,
            webViewControllerFactory: webViewControllerFactory
        )
        navigationController.pushViewController(viewController, animated: UIView.shouldAnimate)
    }

    func showAcquiringTransactionPaymentDetails(transactionId: ReceiveKit.AcquiringTransactionId) {
        guard let navigationController,
              let delegate = paymentDetailsRefundFlowDelegate else {
            return
        }
        let viewController = paymentDetailsViewControllerFactory.make(
            profileId: profile.id,
            paymentRequestId: paymentRequestId,
            transactionId: transactionId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: delegate,
            webViewControllerFactory: webViewControllerFactory
        )
        navigationController.pushViewController(viewController, animated: UIView.shouldAnimate)
    }

    func showTransferPaymentDetails(transferId: ReceiveKit.ReceiveTransferId) {
        guard let navigationController,
              let delegate = paymentDetailsRefundFlowDelegate else {
            return
        }
        let viewController = paymentDetailsViewControllerFactory.make(
            profileId: profile.id,
            paymentRequestId: paymentRequestId,
            transferId: transferId,
            navigationController: navigationController,
            paymentDetailsRefundFlowDelegate: delegate,
            webViewControllerFactory: webViewControllerFactory
        )
        navigationController.pushViewController(viewController, animated: UIView.shouldAnimate)
    }
}
