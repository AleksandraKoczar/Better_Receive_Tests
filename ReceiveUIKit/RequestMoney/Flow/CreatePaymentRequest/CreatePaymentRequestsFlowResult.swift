import ReceiveKit
import WiseCore

// sourcery: AutoEquatableForTest
enum CreatePaymentRequestFlowResult {
    case success(
        paymentRequestId: PaymentRequestId,
        context: CreatePaymentRequestFlowResult.Context
    )
    case aborted
}

extension CreatePaymentRequestFlowResult {
    enum Context {
        case completed
        case linkCreation
        case requestFromContact
    }
}
