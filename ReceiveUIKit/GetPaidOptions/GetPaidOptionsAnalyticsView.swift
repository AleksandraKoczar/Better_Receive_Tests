import AnalyticsKit

struct GetPaidOptionsAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Launchpad - Dropdown")
}

extension GetPaidOptionsAnalyticsView {
    struct CreatePaymentLinkCTA: AnalyticsViewAction {
        typealias View = GetPaidOptionsAnalyticsView
        let name = "Create Payment Link CTA"
    }

    struct CreateInvoiceCTA: AnalyticsViewAction {
        typealias View = GetPaidOptionsAnalyticsView
        let name = "Create Invoice CTA"
    }
}
