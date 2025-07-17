import AnalyticsKit
import BalanceKit
import Foundation

struct BalanceAccountDetailsEvent: AnalyticsEventItem {
    private let currency: String

    init(currency: String) {
        self.currency = currency
    }

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(name: "Balance details action - bank details", properties: [
                "currency": currency,
                "status": "active",
            ]),
        ]
    }
}
