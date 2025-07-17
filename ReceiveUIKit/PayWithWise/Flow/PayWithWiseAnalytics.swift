import AnalyticsKit
import TWFoundation
import WiseCore

struct PayWithWiseFlowAnalytics: AnalyticsFlow {
    static var identity = AnalyticsIdentity(name: "Pay with Wise")
}

extension PayWithWiseFlowAnalytics {
    struct IneligibleAction: AnalyticsFlowAction {
        typealias Flow = PayWithWiseFlowAnalytics

        let name = "Ineligible"
    }
}

extension PayWithWiseFlowAnalytics {
    final class IsSinglePagePayerAnalyticsProperty: BooleanStringAnalyticsProperty {
        init(isSinglePagePayer: Bool) {
            super.init(
                name: "IsSinglePagePayer",
                value: isSinglePagePayer
            )
        }
    }

    struct CurrencyProperty: AnalyticsProperty {
        let name = "Currency"
        let value: AnalyticsPropertyValue

        init(currencyCode: CurrencyCode) {
            value = currencyCode.value
        }
    }
}
