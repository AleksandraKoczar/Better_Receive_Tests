import AnalyticsKit
import Foundation

struct RequestMoneyContactPickerSearchAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(
        name: RequestMoneyContactPickerAnalyticsView.identity.name
            + " - "
            + "Search"
    )
}

// MARK: - Properties

extension RequestMoneyContactPickerSearchAnalyticsView {
    struct SearchFinishedAction: AnalyticsViewAction {
        typealias View = RequestMoneyContactPickerSearchAnalyticsView

        let name: String
        let properties: [AnalyticsProperty] = []

        init(result: ReceiveContactPickerSearchResult) {
            switch result {
            case .selected:
                name = "Contact Selected"
            case .selectedContinueWithLink:
                name = "Create Link Tapped"
            case .finishedWithoutSelection:
                name = "Cancelled"
            }
        }
    }
}
