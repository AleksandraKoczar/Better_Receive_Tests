import AnalyticsKit
import Foundation
import TWFoundation
import UserKit
import WiseCore

typealias CreatePaymentRequestFlowAnalyticsTracker = AnalyticsFlowTrackerImpl<CreatePaymentRequestFlowAnalytics>

struct CreatePaymentRequestFlowAnalytics: AnalyticsFlow {
    static let identity = AnalyticsIdentity(name: "Request Flow")
}

// MARK: - Properties

extension CreatePaymentRequestFlowAnalytics {
    enum PropertyNames {
        static let currency = "Currency"
        static let flowVariant = "FlowVariant"
        static let state = "State"
        static let onboardingPageRequest = "Onboarding Page Request"
        static let initiatedWithContact = "Initiated With Contact"
        static let isContactRequestEligible = "Is Contact Request Eligible"
    }

    struct CurrencyProperty: AnalyticsProperty {
        let name = PropertyNames.currency
        let value: AnalyticsPropertyValue

        init(values: [CurrencyCode]) {
            value = values.map { $0.value }.joined(separator: ",")
        }

        init(value: CurrencyCode) {
            self.value = value.value
        }
    }

    struct EntryPoint: AnalyticsProperty {
        let name = "Entry Point"
        let value: AnalyticsPropertyValue

        init(entryPoint: CreatePaymentRequestFlow.EntryPoint) {
            value = entryPoint.analyticsValue
        }
    }

    struct FlowVariantProperty: AnalyticsProperty {
        let name = PropertyNames.flowVariant
        let value: AnalyticsPropertyValue
        init(value: ProfileType) {
            switch value {
            case .business:
                self.value = "Business"
            case .personal:
                self.value = "Personal"
            }
        }
    }

    struct RequestFlowResult: AnalyticsProperty {
        let name = PropertyNames.state
        let value: AnalyticsPropertyValue

        init(value: String) {
            self.value = value
        }
    }

    final class InitiatedWithContact: BooleanStringAnalyticsProperty {
        init(value: Bool) {
            super.init(
                name: "Initiated With Contact",
                value: value
            )
        }
    }

    final class IsContactRequestEligible: BooleanStringAnalyticsProperty {
        init(value: Bool) {
            super.init(
                name: "Is Contact Request Eligible",
                value: value
            )
        }
    }

    struct InitiatedWithCurrency: AnalyticsProperty {
        let name = "Initiated With Currency"
        let value: AnalyticsPropertyValue

        init?(currencyCode: CurrencyCode?) {
            guard let currencyCode else { return nil }
            value = currencyCode.value
        }
    }
}

// MARK: - Steps

extension CreatePaymentRequestFlowAnalytics {
    struct Onboarding: AnalyticsFlowStep {
        typealias Flow = CreatePaymentRequestFlowAnalytics
        static let name = "Onboarding"
    }

    struct CreateRequestDetails: AnalyticsFlowStep {
        typealias Flow = CreatePaymentRequestFlowAnalytics
        static let name = "Create"
        let properties: [AnalyticsProperty]

        init(profileType: ProfileType) {
            properties = [FlowVariantProperty(value: profileType)]
        }
    }

    struct SelectPaymentMethods: AnalyticsFlowStep {
        typealias Flow = CreatePaymentRequestFlowAnalytics
        static let name = "PaymentMethods"
        let properties: [AnalyticsProperty]

        init(profileType: ProfileType) {
            properties = [FlowVariantProperty(value: profileType)]
        }
    }

    struct ShareRequestDetails: AnalyticsFlowStep {
        typealias Flow = CreatePaymentRequestFlowAnalytics
        static let name = "Share"
        let properties: [AnalyticsProperty]

        init(profileType: ProfileType) {
            properties = [FlowVariantProperty(value: profileType)]
        }
    }
}

// MARK: - Actions

extension CreatePaymentRequestFlowAnalytics {
    struct RequestPublished: AnalyticsFlowAction {
        typealias Flow = CreatePaymentRequestFlowAnalytics
        let name = "Request Published"
        let properties: [AnalyticsProperty]

        init(flowVariant: FlowVariantProperty) {
            properties = [flowVariant]
        }
    }
}

// MARK: - Value Provider Extensions

private extension CreatePaymentRequestFlow.EntryPoint {
    var analyticsValue: String {
        switch self {
        case .deeplink:
            "Deeplink"
        case .balance:
            "Balance"
        case .cardOnboardingDeeplink:
            "Card Onboarding Deeplink"
        case .paymentRequestList:
            "Payment Request List"
        case .launchpad:
            "Launchpad"
        case .recipients:
            "Recipients"
        case .contactList:
            "Contact List"
        case .recentContact:
            "Recent Contact"
        case .payWithWiseSuccess:
            "Pay with Wise Success"
        }
    }
}
