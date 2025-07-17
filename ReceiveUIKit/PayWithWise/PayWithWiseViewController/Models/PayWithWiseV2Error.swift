import Foundation
import ReceiveKit

// sourcery: CaseNameAnalyticsIdentifyable
enum PayWithWiseV2Error: LocalizedError {
    case fetchingPaymentKeyFailed(error: Error)
    case fetchingPaymentRequestInfoFailed(error: PayWithWisePaymentRequestInfoError)
    case fetchingAcquiringPaymentFailed
    case creatingAcquiringPaymentFailed(error: QuickpayError)
    case downloadingAttachmentFailed
    case savingAttachmentFailed
    case fetchingBalancesFailed(error: Error)
    case fetchingFundableBalancesFailed(error: Error)
    case noBalancesAvailable
    case fetchingSessionFailed(error: Error)
    case fetchingQuoteFailed(error: PayWithWisePaymentError)
    case rejectingPaymentFailed(error: Error)
    case paymentFailed(error: PayWithWisePaymentError)
    case payWithWisePaymentMethodNotAvailable(paymentRequestLookup: PaymentRequestLookup)
    case payWithWiseNotAvailableOnQuickpay
}
