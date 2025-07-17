import AnalyticsKit
import Foundation

struct PaymentRequestOnboardingAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Request Flow - Onboarding")
}

// MARK: - Actions

extension PaymentRequestOnboardingAnalyticsView {
    struct StartPressed: AnalyticsViewAction {
        typealias View = PaymentRequestOnboardingAnalyticsView
        let name = "Start pressed"
    }

    struct ExitPressed: AnalyticsViewAction {
        typealias View = PaymentRequestOnboardingAnalyticsView
        let name = "Exit pressed"
    }
}
