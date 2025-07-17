// MARK: - AccountDetailsReceiveOptionReceiveType

internal extension AccountDetailsReceiveOptionReceiveType {
    var caseNameId: String {
        switch self {
        case .local:
            "local"
        case .international:
            "international"
        }
    }
}

// MARK: - PayWithWiseV2Error

internal extension PayWithWiseV2Error {
    var caseNameId: String {
        switch self {
        case .fetchingPaymentKeyFailed:
            "fetchingPaymentKeyFailed"
        case .fetchingPaymentRequestInfoFailed:
            "fetchingPaymentRequestInfoFailed"
        case .fetchingAcquiringPaymentFailed:
            "fetchingAcquiringPaymentFailed"
        case .creatingAcquiringPaymentFailed:
            "creatingAcquiringPaymentFailed"
        case .downloadingAttachmentFailed:
            "downloadingAttachmentFailed"
        case .savingAttachmentFailed:
            "savingAttachmentFailed"
        case .fetchingBalancesFailed:
            "fetchingBalancesFailed"
        case .fetchingFundableBalancesFailed:
            "fetchingFundableBalancesFailed"
        case .noBalancesAvailable:
            "noBalancesAvailable"
        case .fetchingSessionFailed:
            "fetchingSessionFailed"
        case .fetchingQuoteFailed:
            "fetchingQuoteFailed"
        case .rejectingPaymentFailed:
            "rejectingPaymentFailed"
        case .paymentFailed:
            "paymentFailed"
        case .payWithWisePaymentMethodNotAvailable:
            "payWithWisePaymentMethodNotAvailable"
        case .payWithWiseNotAvailableOnQuickpay:
            "payWithWiseNotAvailableOnQuickpay"
        }
    }
}

// MARK: - WisetagError

internal extension WisetagError {
    var caseNameId: String {
        switch self {
        case .ineligible:
            "ineligible"
        case .loadingError:
            "loadingError"
        case .updateSharableLinkError:
            "updateSharableLinkError"
        case .downloadWisetagImageError:
            "downloadWisetagImageError"
        }
    }
}
