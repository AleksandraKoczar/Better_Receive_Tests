import AnalyticsKit
import LoggingKit
import Prism
import WiseCore

// sourcery: AutoEquatableForTest
enum PayWithWiseAnalyticsEvent {
    case balanceSelected(
        requestCurrency: String,
        paymentCurrency: String,
        isSameCurrency: Bool,
        requestCurrencyBalanceExists: Bool,
        requestCurrencyBalanceHasEnough: Bool
    )
    case balanceSelectorOpened(noOfBalances: Int64)
    case declineConfirmed
    case declineTapped(requestCurrencyBalanceExists: Bool)
    case loaded(
        requestCurrency: String,
        paymentCurrency: String,
        isSameCurrency: Bool,
        requestCurrencyBalanceExists: Bool,
        requestCurrencyBalanceHasEnough: Bool,
        errorCode: String?,
        errorMessage: String?
    )
    case loadedWithError(errorCode: String?, errorKey: PayWithWiseErrorKey)
    case payAnotherWayTapped(requestCurrency: String, requestCurrencyBalanceExists: Bool, requestCurrencyBalanceHasEnough: Bool)
    case payFailed(paymentRequestId: String, message: String)
    case payTapped(requestCurrency: String, paymentCurrency: String, profileType: PayWithWiseProfileType)
    case profileChanged(profileType: PayWithWiseProfileType)
    case quoteCreated(success: Bool, requestCurrency: String, paymentCurrency: String, amount: Double)
    case paySucceed(requestType: PayWithWiseRequestType, requestCurrency: String, paymentCurrency: String)
    case topUpCompleted(success: Bool)
    case topUpTapped
    case attachmentLoadingFailed(message: String)
    case viewAttachmentTapped
    case viewDetailsTapped
}

// sourcery: AutoEquatableForTest
enum PayerScreenAnalyticsEvent {
    case startedLoggedIn
    case started(
        context: PayerScreenPayerScreenContext,
        paymentRequestType: PayerScreenPaymentRequestType,
        currency: CurrencyCode?
    )
    case paymentMethodSelected(method: PayerScreenPayerScreenMethod)
}

// sourcery: AutoMockable
protocol PayWithWiseAnalyticsTracker {
    func trackEvent(_ event: PayWithWiseAnalyticsEvent)
    func trackPayerScreenEvent(_ event: PayerScreenAnalyticsEvent)
}

struct PayWithWiseAnalyticsTrackerImpl: PayWithWiseAnalyticsTracker {
    private let prismTracker: MixpanelPrismTracker
    private let payWithWiseTracker: PayWithWiseTracking
    private let payerScreenTracker: PayerScreenTracking

    init() {
        prismTracker = MixpanelPrismTracker()
        payWithWiseTracker = PayWithWiseTrackingFactory().make(onTrack: prismTracker.trackEvent(name:properties:))
        payerScreenTracker = PayerScreenTrackingFactory().make(onTrack: prismTracker.trackEvent(name:properties:))
    }

    func trackEvent(_ event: PayWithWiseAnalyticsEvent) {
        mapEvent(event)
    }

    func trackPayerScreenEvent(_ event: PayerScreenAnalyticsEvent) {
        mapPayerScreenEvent(event)
    }
}

private extension PayWithWiseAnalyticsTrackerImpl {
    func mapPayerScreenEvent(_ event: PayerScreenAnalyticsEvent) {
        switch event {
        case let .paymentMethodSelected(method):
            payerScreenTracker.onPaymentMethodSelected(method: method)
        case .startedLoggedIn:
            payerScreenTracker.onStartedAndLoggedIn()
        case let .started(context, paymentRequestType, currency):
            payerScreenTracker.onStarted(context: context, currency: currency?.value, paymentRequestType: paymentRequestType)
        }
    }

    func mapEvent(_ event: PayWithWiseAnalyticsEvent) {
        switch event {
        case let .balanceSelected(
            requestCurrency,
            paymentCurrency,
            isSameCurrency,
            requestCurrencyBalanceExists,
            requestCurrencyBalanceHasEnough
        ):
            payWithWiseTracker
                .onBalanceSelected(
                    requestCurrency: requestCurrency,
                    paymentCurrency: paymentCurrency,
                    isSameCurrency: isSameCurrency,
                    requestCurrencyBalanceExists: requestCurrencyBalanceExists,
                    requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough
                )
        case let .balanceSelectorOpened(noOfBalances: noOfBalances):
            payWithWiseTracker.onBalanceSelectorOpened(numberOfBalances: noOfBalances)
        case .declineConfirmed:
            payWithWiseTracker.onDeclineConfirmed()
        case let .declineTapped(requestCurrencyBalanceExists: requestCurrencyBalanceExists):
            payWithWiseTracker.onDeclineTapped(requestCurrencyBalanceExists: requestCurrencyBalanceExists)
        case let .loaded(
            requestCurrency: requestCurrency,
            paymentCurrency: paymentCurrency,
            isSameCurrency: isSameCurrency,
            requestCurrencyBalanceExists: requestCurrencyBalanceExists,
            requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough,
            errorCode: errorCode,
            errorMessage: errorMessage
        ):
            payWithWiseTracker
                .onLoaded(
                    requestCurrency: requestCurrency,
                    paymentCurrency: paymentCurrency,
                    requestCurrencyBalanceExists: requestCurrencyBalanceExists,
                    requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough,
                    isSameCurrency: isSameCurrency,
                    errorCode: errorCode,
                    errorMessage: errorMessage
                )
        case let .loadedWithError(errorCode: errorCode, errorKey: errorKey):
            payWithWiseTracker.onLoadedWithError(errorCode: errorCode, errorKey: errorKey)
        case let .payAnotherWayTapped(
            requestCurrency: requestCurrency,
            requestCurrencyBalanceExists: requestCurrencyBalanceExists,
            requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough
        ):
            payWithWiseTracker.onPayAnotherWayTapped(
                requestCurrency: requestCurrency,
                requestCurrencyBalanceExists: requestCurrencyBalanceExists,
                requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough
            )
        case let .payFailed(paymentRequestId: paymentRequestId, message: message):
            payWithWiseTracker.onPayFailed(paymentRequestId: paymentRequestId, message: message)
        case let .payTapped(requestCurrency: requestCurrency, paymentCurrency: paymentCurrency, profileType: profileType):
            payWithWiseTracker.onPayTapped(
                requestCurrency: requestCurrency,
                paymentCurrency: paymentCurrency,
                profileType: profileType
            )
        case let .profileChanged(profileType: profileType):
            payWithWiseTracker.onProfileChanged(profileType: profileType)
        case let .quoteCreated(
            success: success,
            requestCurrency: requestCurrency,
            paymentCurrency: paymentCurrency,
            amount: amount
        ):
            payWithWiseTracker.onQuoteCreated(
                success: success,
                requestCurrency: requestCurrency,
                paymentCurrency: paymentCurrency,
                amount: amount
            )
        case let .paySucceed(requestType: requestType, requestCurrency: requestCurrency, paymentCurrency: paymentCurrency):
            payWithWiseTracker.onSuccess(
                requestType: requestType,
                requestCurrency: requestCurrency,
                paymentCurrency: paymentCurrency
            )
        case let .topUpCompleted(success: success):
            payWithWiseTracker.onTopUpCompleted(success: success)
        case .topUpTapped:
            payWithWiseTracker.onTopUpTapped()
        case let .attachmentLoadingFailed(message: message):
            payWithWiseTracker.onViewAttachmentFailed(message: message)
        case .viewAttachmentTapped:
            payWithWiseTracker.onViewAttachmentTapped()
        case .viewDetailsTapped:
            payWithWiseTracker.onViewDetailsButton()
        }
    }
}
