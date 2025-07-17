import AnalyticsKit
import ReceiveKit

typealias RequestMoneyCardOnboardingFlowAnalyticsTracker = AnalyticsFlowTrackerImpl<RequestMoneyCardOnboardingFlowAnalytics>

struct RequestMoneyCardOnboardingFlowAnalytics: AnalyticsFlow {
    static let identity = AnalyticsIdentity(name: "Request Setup Flow")

    // MARK: - Properties

    struct StateProperty: AnalyticsProperty {
        let name = "State"
        let value: AnalyticsPropertyValue

        init(availability: RequestMoneyCardAvailability) {
            switch availability {
            case .ineligible:
                value = "NOT_ELIGIBLE"
            case .available:
                value = "AVAILABILE"
            case .eligible:
                value = "ELIGIBLE"
            }
        }
    }

    struct OnboardingResultProperty: AnalyticsProperty {
        let name = "isSuccess"
        let value: AnalyticsPropertyValue

        init(value: Bool) {
            self.value = value
        }
    }

    // MARK: - Actions

    struct LoadedAction: AnalyticsFlowAction {
        typealias Flow = RequestMoneyCardOnboardingFlowAnalytics

        let name = "Loaded"
        let properties: [AnalyticsProperty]

        init(state: StateProperty) {
            properties = [state]
        }
    }
}
