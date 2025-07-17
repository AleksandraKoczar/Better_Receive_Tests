import AnalyticsKit
import BalanceKit
import TWFoundation
import WiseCore

typealias SalarySwitchFlowAnalyticsTracker = AnalyticsFlowTrackerImpl<SalarySwitchFlowAnalytics>

struct SalarySwitchFlowAnalytics: AnalyticsFlow {
    static var identity = AnalyticsIdentity(name: "Switch Salary Flow")
}

// MARK: - View analytics

// MARK: Options View

extension SalarySwitchFlowAnalytics {
    struct OptionsView: AnalyticsView {
        static let identity = AnalyticsIdentity(
            name: SalarySwitchFlowAnalytics.identity.name
                + " - "
                + "Sharing Options"
        )

        struct OptionSelected: AnalyticsViewAction {
            typealias View = OptionsView

            let name = "Option Selected"
            let properties: [AnalyticsProperty]

            init(option: SalarySwitchOption, currencyCode: CurrencyCode) {
                properties = [
                    SelectedOptionProperty(option: option),
                    CurrencyProperty(currencyCode: currencyCode),
                ]
            }
        }

        struct AccountDetailsFetched: AnalyticsViewAction {
            typealias View = OptionsView

            let name = "Account Details Fetched"
            let properties: [AnalyticsProperty]

            init(accountDetails: ActiveAccountDetails?) {
                properties = [
                    AnyAnalyticsProperty(
                        "Title",
                        accountDetails?.title ?? "nil"
                    ),
                ]
            }
        }

        struct AccountOwnershipProofDocumentFetched: AnalyticsViewAction {
            typealias View = OptionsView

            let name = "Account Ownership Proof Fetched"
            let properties: [AnalyticsProperty]

            init(url: URL) {
                properties = [
                    AnyAnalyticsProperty(
                        "Document URL",
                        url.absoluteString
                    ),
                ]
            }
        }

        struct ErrorShown: AnalyticsViewAction {
            typealias View = OptionsView

            let name = "Error Shown"
            let properties: [AnalyticsProperty]

            init(message: String) {
                properties = [
                    ErrorMessageProperty(value: message),
                ]
            }
        }
    }
}

// MARK: Upsell View

extension SalarySwitchFlowAnalytics {
    struct UpsellView: AnalyticsView {
        static let identity = AnalyticsIdentity(name: "Salary Switch Upsell View")

        struct ContinuePressed: AnalyticsViewAction {
            typealias View = UpsellView

            let name = "Continue Pressed"
            let properties: [AnalyticsProperty]

            init(
                currencyCode: CurrencyCode,
                requirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus
            ) {
                properties = [
                    CurrencyProperty(currencyCode: currencyCode),
                    RequirementStatusProperty(requirementStatus: requirementStatus),
                ]
            }
        }

        struct ErrorShown: AnalyticsViewAction {
            typealias View = UpsellView

            let name = "Error Shown"
            let properties: [AnalyticsProperty]

            init(message: String) {
                properties = [
                    ErrorMessageProperty(value: message),
                ]
            }
        }
    }
}

// MARK: - Flow steps

extension SalarySwitchFlowAnalytics {
    struct Upsell: AnalyticsFlowStep {
        typealias Flow = SalarySwitchFlowAnalytics
        static let name = "Upsell"
    }

    struct SharingOptions: AnalyticsFlowStep {
        typealias Flow = SalarySwitchFlowAnalytics
        static let name = "Sharing Options"
    }
}

// MARK: - Properties

private struct ErrorMessageProperty: AnalyticsProperty {
    let name = "Error Message"
    let value: AnalyticsPropertyValue
}

private struct RequirementStatusProperty: AnalyticsProperty {
    let name = "Requirement Status"
    let value: AnalyticsPropertyValue

    init(requirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus) {
        value = requirementStatus.analyticsPropertyValue
    }
}

extension SalarySwitchFlowAnalytics {
    struct CurrencyProperty: AnalyticsProperty {
        let name = "Currency"
        let value: AnalyticsPropertyValue

        init(currencyCode: CurrencyCode) {
            value = currencyCode.value
        }
    }

    struct OriginProperty: AnalyticsProperty {
        let name = "Origin"
        let value: AnalyticsPropertyValue

        init(origin: SalarySwitchFlowStartOrigin) {
            value = origin.analyticsPropertyValue
        }
    }

    struct SelectedOptionProperty: AnalyticsProperty {
        let name = "Option"
        let value: AnalyticsPropertyValue

        init(option: SalarySwitchOption) {
            value = option.analyticsPropertyValue
        }
    }

    struct ProfileIdProperty: AnalyticsProperty {
        let name = "Profile Id"
        let value: AnalyticsPropertyValue
    }
}

// MARK: - Mappings

private extension SalarySwitchOption {
    var analyticsPropertyValue: AnalyticsPropertyValue {
        switch self {
        case .shareDetails:
            "SHARE_DETAILS"
        case .accountOwnershipProof:
            "PROOF_OF_ACCOUNT_OWNERSHIP"
        }
    }
}

private extension SalarySwitchFlowStartOrigin {
    var analyticsPropertyValue: AnalyticsPropertyValue {
        switch self {
        case .addMoney:
            "ADD_MONEY"
        case .notification:
            "NOTIFICATION"
        case .accountDetailsIntro:
            "ACCOUNT_DETAILS_INTRO"
        }
    }
}

private extension SalarySwitchFlowAccountDetailsRequirementStatus {
    var analyticsPropertyValue: AnalyticsPropertyValue {
        switch self {
        case .hasActiveAccountDetails:
            "HAS_ACCOUNT_DETAILS"
        case .needsAccountDetailsActivation:
            "NEEDS_ACCOUNT_DETAILS"
        }
    }
}
