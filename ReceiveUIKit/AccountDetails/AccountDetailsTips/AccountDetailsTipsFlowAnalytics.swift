import AnalyticsKit
import TWFoundation
import WiseCore

struct AccountDetailsTipsFlowAnalytics: AnalyticsFlow {
    static let identity = AnalyticsIdentity(name: "Account Details Page")
}

extension AccountDetailsTipsFlowAnalytics {
    // MARK: - Properties

    struct CurrencyProperty: AnalyticsProperty {
        let name = "Currency"
        let value: AnalyticsPropertyValue

        init(currencyCode: CurrencyCode) {
            value = currencyCode.value
        }
    }

    // MARK: - Steps

    struct Tips: AnalyticsFlowStep {
        typealias Flow = AccountDetailsTipsFlowAnalytics
        static let name = "Tips"
    }

    // MARK: - Actions

    struct Opened: AnalyticsFlowStepAction {
        typealias Step = Tips
        let name = "Opened"
    }

    struct HelpLinkClicked: AnalyticsFlowStepAction {
        typealias Step = Tips
        let name = "Help Link Clicked"
    }
}
