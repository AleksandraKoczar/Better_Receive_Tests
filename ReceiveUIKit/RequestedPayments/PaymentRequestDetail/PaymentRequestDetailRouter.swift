import Neptune
import ReceiveKit
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentRequestDetailFlowDelegate: AnyObject {
    func dismiss()
}

// sourcery: AutoMockable
protocol PaymentRequestDetailRouter: AnyObject {
    func showPaymentLinkPaymentDetails(acquiringPaymentId: AcquiringPaymentId)
    func showAcquiringTransactionPaymentDetails(transactionId: AcquiringTransactionId)
    func showTransferPaymentDetails(transferId: ReceiveTransferId)
    func showDocumentPreview(url: URL, delegate: UIDocumentInteractionControllerDelegate)
    func showActionConfirmation(viewModel: InfoSheetViewModel)
    func showQRCode(paymentRequest: PaymentRequestV2)
    func showShareSheet(paymentRequest: PaymentRequestV2)
    func goBackToPaymentRequestDetail()
    func goToViewAllPayments()
    func goBackToAllPayments()
    func dismiss()
}

final class PaymentRequestDetailRouterImpl {
    weak var paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate?
    weak var paymentRequestDetailViewController: UIViewController?

    // This delegate property is only used for `ManagePaymentRequestDetailsFlow` entry point
    private weak var flowDelegate: PaymentRequestDetailFlowDelegate?
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
        webViewControllerFactory: WebViewControllerFactory.Type,
        flowDelegate: PaymentRequestDetailFlowDelegate? = nil,
        paymentLinkViewControllerFactory: PaymentLinkViewControllerFactory = PaymentLinkViewControllerFactoryImpl(),
        paymentDetailsViewControllerFactory: PaymentDetailsViewControllerFactory.Type = PaymentDetailsViewControllerFactoryImpl.self
    ) {
        self.flowDelegate = flowDelegate
        self.navigationController = navigationController
        self.profile = profile
        self.paymentRequestId = paymentRequestId
        self.paymentLinkViewControllerFactory = paymentLinkViewControllerFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.paymentDetailsViewControllerFactory = paymentDetailsViewControllerFactory
    }
}

// MARK: - PaymentRequestDetailRouter

extension PaymentRequestDetailRouterImpl: PaymentRequestDetailRouter {
    func showPaymentLinkPaymentDetails(acquiringPaymentId: AcquiringPaymentId) {
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

    func showAcquiringTransactionPaymentDetails(transactionId: AcquiringTransactionId) {
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

    func showTransferPaymentDetails(transferId: ReceiveTransferId) {
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

    func showDocumentPreview(
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate
    ) {
        let documentPreviewer = UIDocumentInteractionController(url: url)
        documentPreviewer.name = ""
        documentPreviewer.delegate = delegate
        documentPreviewer.presentPreview(animated: UIView.shouldAnimate)
    }

    func showActionConfirmation(viewModel: InfoSheetViewModel) {
        navigationController?.presentInfoSheet(viewModel: viewModel)
    }

    func showQRCode(paymentRequest: PaymentRequestV2) {
        let qrCodeViewController = PaymentRequestQRSharingViewControllerFactory.make(
            profile: profile,
            paymentRequest: paymentRequest
        )
        navigationController?.presentBottomSheet(qrCodeViewController)
    }

    func showShareSheet(paymentRequest: PaymentRequestV2) {
        guard let navigationController,
              let sourceView = navigationController.visibleViewController?.view else {
            return
        }
        let message = ShareMessageFactoryImpl().make(
            profile: profile,
            paymentRequest: paymentRequest
        )
        let sharingController = UIActivityViewController.universalSharingController(
            forItems: [message],
            sourceView: sourceView
        )
        navigationController.present(sharingController, animated: UIView.shouldAnimate)
    }

    func goBackToPaymentRequestDetail() {
        guard let viewController = paymentRequestDetailViewController else {
            return
        }
        navigationController?.popToViewController(viewController, animated: UIView.shouldAnimate)
    }

    func goToViewAllPayments() {
        guard let navigationController,
              let delegate = paymentDetailsRefundFlowDelegate else {
            return
        }

        let router = PaymentLinkAllPaymentsRouterImpl(
            navigationController: navigationController,
            profile: profile,
            paymentRequestId: paymentRequestId,
            paymentDetailsRefundFlowDelegate: delegate,
            webViewControllerFactory: webViewControllerFactory
        )

        let presenter = PaymentLinkAllPaymentsPresenterImpl(
            router: router,
            paymentRequestId: paymentRequestId,
            profile: profile
        )

        let viewController = PaymentLinkAllPaymentsViewController(presenter: presenter)
        navigationController.pushViewController(viewController, animated: UIView.shouldAnimate)
    }

    func goBackToAllPayments() {
        let paymentListViewController = navigationController?.viewControllers.first { $0 is PaymentRequestsListViewController }
        guard let paymentListViewController else { return }
        navigationController?.popToViewController(paymentListViewController, animated: UIView.shouldAnimate)
    }

    func dismiss() {
        flowDelegate?.dismiss()
    }
}
