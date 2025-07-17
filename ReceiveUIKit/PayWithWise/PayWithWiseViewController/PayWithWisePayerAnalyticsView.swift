import AnalyticsKit
import DeepLinkKit
import Foundation
import ReceiveKit
import TWFoundation
import WiseCore

struct PayWithWisePayerAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(
        name: PayWithWiseFlowAnalytics.identity.name
            + " - "
            + "Payer Screen"
    )
}

// MARK: - Actions

extension PayWithWisePayerAnalyticsView {
    struct Loaded: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView
        let name = "Loaded"
        let properties: [AnalyticsProperty]

        init(
            paymentRequestId: PaymentRequestId,
            requestCurrency: CurrencyCode,
            paymentCurrency: CurrencyCode,
            requestCurrencyBalanceExists: Bool,
            requestCurrencyBalanceHasEnough: Bool
        ) {
            properties = [
                PaymentRequestIdType(value: paymentRequestId.value),
                RequestCurrencyProperty(currencyCode: requestCurrency),
                PaymentCurrencyProperty(currencyCode: paymentCurrency),
                RequestCurrencyBalanceExistsProperty(requestCurrencyBalanceExists),
                RequestCurrencyBalanceHasEnoughProperty(requestCurrencyBalanceHasEnough),
            ]
        }
    }

    final class LoadingFailed: ReceiveErrorAnalyticsViewAction<PayWithWisePayerAnalyticsView> {
        init?(
            error: PayWithWiseV2Error
        ) {
            if case let .paymentFailed(err) = error,
               case .cancelledByUser = err {
                return nil
            }

            let additionalProperties: [AnalyticsProperty] = {
                switch error {
                case let .fetchingPaymentRequestInfoFailed(error):
                    let model = error.makeErrorAnalyticsModel()
                    return Self.makeInnerProperties(
                        model: model
                    )
                case let .fetchingQuoteFailed(error),
                     let .paymentFailed(error):
                    let model = error.makeErrorAnalyticsModel()
                    return Self.makeInnerProperties(
                        model: model
                    )
                case .downloadingAttachmentFailed,
                     .savingAttachmentFailed,
                     .noBalancesAvailable,
                     .payWithWisePaymentMethodNotAvailable:
                    return []
                case let .fetchingPaymentKeyFailed(error),
                     let .fetchingBalancesFailed(error),
                     let .fetchingFundableBalancesFailed(error),
                     let .fetchingSessionFailed(error),
                     let .rejectingPaymentFailed(error):
                    let model = AnyReceiveErrorAnalyticsModel(
                        type: "",
                        message: error.localizedDescription,
                        identifier: error.nonLocalizedDescription
                    )
                    return Self.makeInnerProperties(model: model)
                case .fetchingAcquiringPaymentFailed:
                    return []
                case .payWithWiseNotAvailableOnQuickpay:
                    return []
                case .creatingAcquiringPaymentFailed:
                    return []
                }
            }()

            super.init(
                name: "Loading Failed",
                model: error,
                additionalProperties: additionalProperties
            )
        }
    }

    struct PayTapped: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Pay Tapped"
        let properties: [AnalyticsProperty]

        init(
            requestCurrency: CurrencyCode,
            paymentCurrency: CurrencyCode,
            profileType: WiseCore.ProfileType
        ) {
            properties = [
                RequestCurrencyProperty(currencyCode: requestCurrency),
                PaymentCurrencyProperty(currencyCode: paymentCurrency),
                ProfileType(profileType),
            ]
        }
    }

    struct PaySucceed: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Pay Succeed"
        let properties: [AnalyticsProperty]

        init(
            source: PayWithWiseFlow.PaymentInitializationSource,
            requestCurrency: CurrencyCode,
            paymentCurrency: CurrencyCode
        ) {
            properties = [
                RequestType(source: source),
                RequestCurrencyProperty(currencyCode: requestCurrency),
                PaymentCurrencyProperty(currencyCode: paymentCurrency),
            ]
        }
    }

    struct PaymentFailed: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Pay Failed"
        let properties: [AnalyticsProperty]

        init(
            paymentRequestId: PaymentRequestId,
            errorMessage: String
        ) {
            properties = [
                PaymentRequestIdType(value: paymentRequestId.value),
                AnyAnalyticsProperty("Message", errorMessage),
            ]
        }
    }

    struct DeclineTapped: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Decline Tapped"
        let properties: [AnalyticsProperty]

        init(requestCurrencyBalanceExists: Bool) {
            properties = [
                RequestCurrencyBalanceExistsProperty(requestCurrencyBalanceExists),
            ]
        }
    }

    struct DeclineConfirmed: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Decline Confirmed"
        let properties: [AnalyticsProperty] = []
    }

    struct PayAnotherWayTapped: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Pay Another Way Tapped"
        let properties: [AnalyticsProperty]

        init(
            requestCurrency: CurrencyCode,
            requestCurrencyBalanceExists: Bool,
            requestCurrencyBalanceHasEnough: Bool
        ) {
            properties = [
                RequestCurrencyProperty(currencyCode: requestCurrency),
                RequestCurrencyBalanceExistsProperty(requestCurrencyBalanceExists),
                RequestCurrencyBalanceHasEnoughProperty(requestCurrencyBalanceHasEnough),
            ]
        }
    }

    struct OtherPaymentMethodSelected: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Other Payment Method Selected"
        let properties: [AnalyticsProperty]

        init(
            method: PayerAcquiringPaymentMethod
        ) {
            properties = [
                AnyAnalyticsProperty("Method", method.value),
            ]
        }
    }

    struct ViewDetailsTapped: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "View Details Tapped"
        let properties: [AnalyticsProperty] = []
    }

    struct ViewAttachmentTapped: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "View Attachment Tapped"
        let properties: [AnalyticsProperty] = []
    }

    final class AttachmentLoadingFailed: ReceiveErrorAnalyticsViewAction<PayWithWisePayerAnalyticsView> {
        init(error: PayWithWiseV2Error) {
            super.init(name: "Invoice Loading Failed", model: error)
        }
    }

    struct BalanceSelectorOpened: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Balance Selector Opened"
        let properties: [AnalyticsProperty]

        init(numberOfBalances: Int) {
            properties = [
                AnyAnalyticsProperty("NumberOfBalances", numberOfBalances),
            ]
        }
    }

    struct BalanceSelected: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Balance Selected"
        let properties: [AnalyticsProperty]

        init(
            requestCurrency: CurrencyCode,
            paymentCurrency: CurrencyCode
        ) {
            properties = [
                RequestCurrencyProperty(currencyCode: requestCurrency),
                PaymentCurrencyProperty(currencyCode: paymentCurrency),
            ]
        }
    }

    struct BalanceAutoSelected: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Balance Auto Selected"
        let properties: [AnalyticsProperty]

        init(
            requestCurrency: CurrencyCode,
            paymentCurrency: CurrencyCode,
            requestCurrencyBalanceExists: Bool,
            requestCurrencyBalanceHasEnough: Bool
        ) {
            properties = [
                RequestCurrencyProperty(currencyCode: requestCurrency),
                PaymentCurrencyProperty(currencyCode: paymentCurrency),
                BooleanStringAnalyticsProperty(
                    name: "IsSameCurrency",
                    value: requestCurrency == paymentCurrency
                ),
                RequestCurrencyBalanceExistsProperty(requestCurrencyBalanceExists),
                RequestCurrencyBalanceHasEnoughProperty(requestCurrencyBalanceHasEnough),
            ]
        }
    }

    struct ProfileChanged: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Profile Changed"
        let properties: [AnalyticsProperty]

        init(profileType: WiseCore.ProfileType) {
            properties = [
                ProfileType(profileType),
            ]
        }
    }

    struct Ineligible: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "Ineligible"
        let properties: [AnalyticsProperty] = []
    }

    struct TopUpCompleted: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "TopUp Completed"
        let properties: [AnalyticsProperty] = []
    }

    struct TopUpAbandoned: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "TopUp Abandoned"
        let properties: [AnalyticsProperty] = []
    }

    struct TopUpFlowStarted: AnalyticsViewAction {
        typealias View = PayWithWisePayerAnalyticsView

        let name = "TopUp Started"
        let properties: [AnalyticsProperty]

        init(currencyCode: CurrencyCode?) {
            properties = {
                guard let currencyCode else { return [] }
                return [
                    RequestCurrencyProperty(
                        currencyCode: currencyCode
                    ),
                ]
            }()
        }
    }
}

// MARK: - Types

extension PayWithWisePayerAnalyticsView {
    struct RequestType: AnalyticsProperty {
        let name = "RequestType"
        let value: AnalyticsPropertyValue

        init(source: PayWithWiseFlow.PaymentInitializationSource) {
            let contactValue = "Contact"
            value =
                switch source {
                case let .paymentKey(source):
                    switch source {
                    case .request:
                        "Link"
                    case .contact:
                        contactValue
                    }
                case .paymentRequestId:
                    contactValue
                case .quickpay:
                    "Quickpay"
                }
        }
    }
}

// MARK: - Private types

private extension PayWithWisePayerAnalyticsView {
    struct RequestCurrencyProperty: AnalyticsProperty {
        let name = "RequestCurrency"
        let value: AnalyticsPropertyValue

        init(currencyCode: CurrencyCode) {
            value = currencyCode.value
        }
    }

    struct PaymentCurrencyProperty: AnalyticsProperty {
        let name = "PaymentCurrency"
        let value: AnalyticsPropertyValue

        init(currencyCode: CurrencyCode) {
            value = currencyCode.value
        }
    }

    struct ProfileType: AnalyticsProperty {
        let name = "ProfileType"
        let value: AnalyticsPropertyValue

        init(_ type: WiseCore.ProfileType) {
            value =
                switch type {
                case .business:
                    "Business"
                case .personal:
                    "Personal"
                }
        }
    }

    struct PaymentRequestIdType: AnalyticsProperty {
        let name = "PaymentRequestId"
        let value: AnalyticsPropertyValue
    }

    final class RequestCurrencyBalanceExistsProperty: BooleanStringAnalyticsProperty {
        init(_ value: Bool) {
            super.init(name: "RequestCurrencyBalanceExists", value: value)
        }
    }

    final class RequestCurrencyBalanceHasEnoughProperty: BooleanStringAnalyticsProperty {
        init(_ value: Bool) {
            super.init(name: "RequestCurrencyBalanceHasEnough", value: value)
        }
    }
}

// MARK: - PayWithWiseV2Error

extension PayWithWiseV2Error: ReceiveErrorAnalyticsModel {
    var type: String {
        switch self {
        case .fetchingPaymentKeyFailed:
            "Fetching Payment Key Failed"
        case .fetchingPaymentRequestInfoFailed:
            "Fetching Payment Request Info Failed"
        case .downloadingAttachmentFailed:
            "Downloading Attachment Failed"
        case .savingAttachmentFailed:
            "Saving Attachment Failed"
        case .fetchingBalancesFailed:
            "Fetching Balances Failed"
        case .fetchingFundableBalancesFailed:
            "Fetching Fundable Balances Failed"
        case .noBalancesAvailable:
            "No Balances Available"
        case .fetchingSessionFailed:
            "Fetching Session Failed"
        case .fetchingQuoteFailed:
            "Fetching Quote Failed"
        case .rejectingPaymentFailed:
            "Rejecting Payment Failed"
        case .paymentFailed:
            "Payment Failed"
        case .payWithWisePaymentMethodNotAvailable:
            "Pay with Wise Payment Method Not Available"
        case .fetchingAcquiringPaymentFailed:
            "Fetching Acquiring Payment Failed"
        case .payWithWiseNotAvailableOnQuickpay:
            "Pay with Wise Not Available On Quickpay"
        case .creatingAcquiringPaymentFailed:
            "Creating Acquiring Payment Failed"
        }
    }

    var message: String {
        switch self {
        case let .fetchingPaymentKeyFailed(error),
             let .fetchingBalancesFailed(error),
             let .fetchingFundableBalancesFailed(error),
             let .fetchingSessionFailed(error),
             let .rejectingPaymentFailed(error):
            error.localizedDescription
        case let .fetchingPaymentRequestInfoFailed(error):
            error.localizedDescription
        case .downloadingAttachmentFailed,
             .savingAttachmentFailed,
             .noBalancesAvailable,
             .payWithWisePaymentMethodNotAvailable:
            localizedDescription
        case let .fetchingQuoteFailed(error):
            error.localizedDescription
        case let .paymentFailed(error):
            error.localizedDescription
        case .fetchingAcquiringPaymentFailed:
            localizedDescription
        case .payWithWiseNotAvailableOnQuickpay:
            localizedDescription
        case .creatingAcquiringPaymentFailed:
            localizedDescription
        }
    }

    var identifier: String {
        caseNameId
    }
}

// MARK: - PayWithWisePaymentError

private extension PayWithWisePaymentError {
    func makeErrorAnalyticsModel() -> ReceiveErrorAnalyticsModel {
        let message: String =
            switch self {
            case let .alreadyPaid(msg),
                 let .targetIsSelf(msg),
                 let .sourceUnavailable(msg):
                msg ?? ""
            case let .customError(_, msg):
                msg ?? ""
            case .cancelledByUser:
                ""
            case let .other(error):
                error.localizedDescription
            }
        return AnyReceiveErrorAnalyticsModel(
            // We don't need type for an inner error
            type: "",
            message: message,
            identifier: caseNameId
        )
    }
}

// MARK: - PayWithWisePaymentRequestInfoError

private extension PayWithWisePaymentRequestInfoError {
    func makeErrorAnalyticsModel() -> ReceiveErrorAnalyticsModel {
        let message =
            switch self {
            case let .alreadyPaid(msg),
                 let .expired(msg),
                 let .invalidated(msg),
                 let .unknown(msg),
                 let .notFound(msg):
                msg ?? ""
            case let .fetchingPaymentKeyFailed(error),
                 let .rejectingPaymentRequestFailed(error),
                 let .other(error):
                error.localizedDescription
            }
        return AnyReceiveErrorAnalyticsModel(
            // We don't need type for an inner error
            type: "",
            message: message,
            identifier: caseNameId
        )
    }
}
