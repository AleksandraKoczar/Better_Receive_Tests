import AnalyticsKit

final class AccountDetailsListScreenItem: AnalyticsScreenItem {
    func screenDescriptors() -> [AnalyticsScreenDescriptor] {
        [
            MixpanelScreen(name: "Bank details list"),
        ]
    }
}

final class AccountDetailsMultipleCurrencyListScreenItem: AnalyticsScreenItem {
    private let currency: String?

    private var properties: [String: Any] {
        currency.flatMap { ["currency": $0] } ?? [:]
    }

    init(currency: String?) {
        self.currency = currency
    }

    func screenDescriptors() -> [AnalyticsScreenDescriptor] {
        [
            MixpanelScreen(name: "Bank details multiple currency list", properties: properties),
        ]
    }
}
