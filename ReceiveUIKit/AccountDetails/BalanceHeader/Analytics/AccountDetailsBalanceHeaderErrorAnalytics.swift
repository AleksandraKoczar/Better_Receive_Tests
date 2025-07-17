import AnalyticsKit
import BalanceKit
import TWFoundation

struct AccountDetailsBalanceHeaderFlowErrorAnalyticsEvent: AnalyticsEventItem {
    private enum Keys {
        static let type = "Type"
        static let message = "Message"
        static let currency = "Currency"
        static let identifier = "Identifier"
    }

    private let context: AccountDetailsBalanceHeaderFlowErrorContext

    init(context: AccountDetailsBalanceHeaderFlowErrorContext) {
        self.context = context
    }

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(
                name: "Account Details Balance Header Flow - Error",
                properties: properties()
            ),
        ]
    }

    private func properties() -> [String: String] {
        switch context {
        case let .fetchingOrders(error):
            [
                Keys.type: "FetchingOrders",
                Keys.identifier: error.analyticsIdentifier,
                Keys.message: error.localizedDescription,
            ]
        case let .fetchingAccountDetails(error):
            [
                Keys.type: "FetchingAccountDetails",
                Keys.identifier: error.analyticsIdentifier,
                Keys.message: error.localizedDescription,
            ]
        case let .noAccountDetailsForCurrency(currency):
            [
                Keys.type: "NoAccountDetailsForCurrency",
                Keys.currency: currency.value,
            ]
        case let .fetchingRequirements(error):
            [
                Keys.type: "FetchingRequirements",
                Keys.identifier: error.nonLocalizedDescription,
                Keys.message: error.localizedDescription,
            ]
        }
    }
}
