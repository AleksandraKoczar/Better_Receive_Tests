import MacrosKit
import ReceiveKit
import TWUI
import UserKit
import WiseCore

@MainActor
// sourcery: AutoMockable
protocol PaymentLinkSharingRouter: AnyObject {
    func openLinkSharing(for paymentRequest: PaymentRequestV2)
    func openPaymentRequestDetails(for paymentRequestId: PaymentRequestId)
}

@Init
final class PaymentLinkSharingRouterImpl: PaymentLinkSharingRouter {
    private let profile: Profile
    private let paymentRequestDetailsHandler: (PaymentRequestId) -> Void
    private let navigationController: UINavigationController
    @Init(default: ShareMessageFactoryImpl())
    private let shareMessageFactory: ShareMessageFactory

    func openLinkSharing(for paymentRequest: PaymentRequestV2) {
        guard let hostController = navigationController.visibleViewController,
              let sourceView = hostController.view else {
            return
        }

        let message = shareMessageFactory.make(
            profile: profile,
            paymentRequest: paymentRequest
        )
        let sharingController = UIActivityViewController.universalSharingController(
            forItems: [message],
            sourceView: sourceView
        )

        hostController.present(sharingController, animated: UIView.shouldAnimate)
    }

    func openPaymentRequestDetails(for paymentRequestId: PaymentRequestId) {
        paymentRequestDetailsHandler(paymentRequestId)
    }
}
