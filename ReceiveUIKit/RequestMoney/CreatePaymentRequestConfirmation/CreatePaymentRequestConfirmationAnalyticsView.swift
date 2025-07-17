import AnalyticsKit
import Foundation

struct CreatePaymentRequestConfirmationAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Request Flow - Share")
}

// MARK: - Actions

extension CreatePaymentRequestConfirmationAnalyticsView {
    struct ShareOptionSelected: AnalyticsViewAction {
        typealias View = CreatePaymentRequestConfirmationAnalyticsView
        let name = "Share Option Selected"
        let properties: [AnalyticsProperty]

        init(vendor: String) {
            properties = [AnyAnalyticsProperty("Vendor", vendor)]
        }
    }
}
