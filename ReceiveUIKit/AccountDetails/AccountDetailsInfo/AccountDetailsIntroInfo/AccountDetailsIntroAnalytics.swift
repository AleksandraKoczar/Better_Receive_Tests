import AnalyticsKit
import TWFoundation
import WiseCore

typealias AccountDetailsIntroFlowAnalyticsTracker = AnalyticsFlowTrackerImpl<SalarySwitchFlowAnalytics>

struct AccountDetailsIntroFlowAnalytics: AnalyticsFlow {
    static var identity = AnalyticsIdentity(name: "Account Details Intro Flow")
}

struct AccountDetailsIntroAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Account Details Intro")
}

// MARK: - Actions

extension AccountDetailsIntroAnalyticsView {
    struct AccountDetailsExpanded: AnalyticsViewAction {
        typealias View = AccountDetailsIntroAnalyticsView

        let name = "Account Details Expanded"
        let properties: [AnalyticsProperty] = []
    }

    struct ThingsYouCanDoOptionSelected: AnalyticsViewAction {
        typealias View = AccountDetailsIntroAnalyticsView

        enum Option {
            case receiveSalary
            case receiveMoney

            var analyticsPropertyValue: String {
                switch self {
                case .receiveSalary:
                    "Receive Salary"
                case .receiveMoney:
                    "Receive Money"
                }
            }
        }

        let name = "Things You Can Do Option Selected"
        let properties: [AnalyticsProperty]

        init(option: Option) {
            properties = [
                AnyAnalyticsProperty("Option", option.analyticsPropertyValue),
            ]
        }
    }

    struct ErrorShown: AnalyticsViewAction {
        enum Error {
            case noActiveAccountDetailsForCurrency(currency: CurrencyCode)
            case fetchError(message: String)

            var typeDescription: String {
                switch self {
                case .noActiveAccountDetailsForCurrency:
                    "No Active Account Details For Currency"
                case .fetchError:
                    "Fetch Error"
                }
            }
        }

        private enum Keys {
            static let type = "Type"
            static let currency = "Currency"
            static let message = "Message"
        }

        typealias View = AccountDetailsIntroAnalyticsView

        let name = "Error Shown"
        let properties: [AnalyticsProperty]

        init(error: Error) {
            properties = {
                var properties = [AnyAnalyticsProperty(Keys.type, error.typeDescription)]
                switch error {
                case let .noActiveAccountDetailsForCurrency(currency):
                    properties.append(AnyAnalyticsProperty(Keys.currency, currency.value))
                case let .fetchError(message):
                    properties.append(AnyAnalyticsProperty(Keys.message, message))
                }
                return properties
            }()
        }
    }
}

// MARK: - Properties

extension AccountDetailsIntroFlowAnalytics {
    struct StartOriginProperty: AnalyticsProperty {
        let name = "Origin"
        let value: AnalyticsPropertyValue

        init(origin: AccountDetailsIntroFlowStartOrigin) {
            value = origin.analyticsPropertyValue
        }
    }
}

private extension AccountDetailsIntroAnalyticsView {
    struct ErrorMessageProperty: AnalyticsProperty {
        let name = "Error Message"
        let value: AnalyticsPropertyValue
    }
}

// MARK: - Mappings

private extension AccountDetailsIntroFlowStartOrigin {
    var analyticsPropertyValue: String {
        switch self {
        case .debug:
            "Debug"
        case .notification:
            "NOTIFICATION"
        case .accountDetails:
            "ACCOUNT_DETAILS"
        }
    }
}
