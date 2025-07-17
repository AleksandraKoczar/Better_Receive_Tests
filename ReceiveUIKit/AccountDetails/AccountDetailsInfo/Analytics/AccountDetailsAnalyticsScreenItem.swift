import AnalyticsKit
import BalanceKit
import TWFoundation
import WiseCore

struct AccountDetailsAnalyticsScreenItem: AnalyticsScreenItem, Equatable {
    private let properties: [String: String]

    init(
        accountDetailsId: AccountDetailsId?,
        currencyCode: CurrencyCode?,
        invocationSource: AccountDetailsInfoInvocationSource,
        context: AccountDetailsType
    ) {
        var properties = [
            "Context": context.analyticsValue,
            "Invocation Source": invocationSource.analyticsValue,
        ]

        if let currencyCode {
            properties["Currency"] = currencyCode.value
        }
        if let accountDetailsId {
            properties["Details ID"] = String(accountDetailsId.value)
        }
        self.properties = properties
    }

    func screenDescriptors() -> [AnalyticsScreenDescriptor] {
        [MixpanelScreen(name: "Bank Details - Viewed", properties: properties)]
    }
}
