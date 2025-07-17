import WiseCore

// sourcery: AutoMockable
@MainActor
public protocol PaymentLinkSharingDelegate: AnyObject {
    func showPaymentRequestDetails(for paymentRequestId: PaymentRequestId)
}
