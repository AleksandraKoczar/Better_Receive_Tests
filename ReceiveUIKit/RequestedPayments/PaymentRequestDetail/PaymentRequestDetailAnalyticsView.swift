import AnalyticsKit
import Foundation

struct PaymentRequestDetailAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Manage Requests")
}

// MARK: - Actions

extension PaymentRequestDetailAnalyticsView {
    struct ViewingDetails: AnalyticsViewAction {
        typealias View = PaymentRequestDetailAnalyticsView
        let name = "Viewing Details"
    }

    struct ViewInvoice: AnalyticsViewAction {
        typealias View = PaymentRequestDetailAnalyticsView
        let name = "View Invoice"
    }

    struct CopyRequestLink: AnalyticsViewAction {
        typealias View = PaymentRequestDetailAnalyticsView
        let name = "Copy Request Link"
    }

    struct StartCancellingRequest: AnalyticsViewAction {
        typealias View = PaymentRequestDetailAnalyticsView
        let name = "Open Cancellation Prompt"
    }

    struct CancelRequest: AnalyticsViewAction {
        typealias View = PaymentRequestDetailAnalyticsView
        let name = "Cancel Request"
    }

    struct ViewAllPressed: AnalyticsViewAction {
        typealias View = PaymentRequestDetailAnalyticsView
        let name = "Urn Pressed"
        let properties: [AnalyticsProperty]

        init(urn: String) {
            properties = [AnyAnalyticsProperty("Urn", urn)]
        }
    }
}
