import AnalyticsKit
import Foundation

struct CreatePaymentRequestAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Request Flow - Create")
}

// MARK: - Actions

extension CreatePaymentRequestAnalyticsView {
    struct TypeSelectionChanged: AnalyticsViewAction {
        typealias View = CreatePaymentRequestAnalyticsView
        let name = "Type Selection Changed"
        let properties: [AnalyticsProperty]

        init(tab: RequestType) {
            let value =
                switch tab {
                case .singleUse:
                    "SingleUse"
                case .reusable:
                    "Reusable"
                }
            properties = [AnyAnalyticsProperty("Tab", value)]
        }
    }
}
