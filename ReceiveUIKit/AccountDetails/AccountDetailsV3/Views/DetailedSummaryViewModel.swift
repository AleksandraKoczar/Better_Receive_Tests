import Foundation
import UIKit
import WiseCore

struct DetailedSummaryViewModel {
    let title: String
    let subtitle: String
    let groups: [DetailedSummaryGroupViewModel]
    let actions: [DetailedSummaryActionViewModel]

    struct DetailedSummaryGroupViewModel {
        let id = UUID()
        let title: String
        let icon: UIImage?
        let items: [DetailedSummaryGroupItemViewModel]

        struct DetailedSummaryGroupItemViewModel {
            let id = UUID()
            let title: String
            let body: String
            let handleURLMarkup: ((URL) -> Void)?
        }
    }

    struct DetailedSummaryActionViewModel {
        let id = UUID()
        let title: String
        let uri: URI
        let handleAction: ((URI) -> Void)?
    }
}
