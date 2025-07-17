import ReceiveKit
import WiseCore

// sourcery: AutoEquatableForTest, Buildable
enum PaymentLinkSharingViewAction {
    case shareLink(PaymentRequestV2)
    case viewPaymentRequest(PaymentRequestId)
}
