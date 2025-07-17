import AnalyticsKit
import Foundation

struct PaymentRequestsListAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Manage Requests")
}

// MARK: - Actions

extension PaymentRequestsListAnalyticsView {
    struct TabChange: AnalyticsViewAction {
        typealias View = PaymentRequestsListAnalyticsView
        let name = "Tab Change"
        let properties: [AnalyticsProperty]

        init(tab: String) {
            properties = [AnyAnalyticsProperty("Tab", tab)]
        }
    }

    struct CreateTapped: AnalyticsViewAction {
        enum Target {
            case invoice
            case paymentRequest
        }

        typealias View = PaymentRequestsListAnalyticsView
        let name = "Create"
        let properties: [any AnalyticsProperty]

        init(target: Target) {
            let value =
                switch target {
                case .invoice: "Invoice"
                case .paymentRequest: "Payment Request"
                }
            properties = [AnyAnalyticsProperty("Target", value)]
        }
    }
}
