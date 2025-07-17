import Foundation
import Neptune
import UIKit
import WiseCore

struct AccountDetailsV3SplitterScreenViewModel {
    let currency: CurrencyCode
    let items: [ItemViewModel]

    struct ItemViewModel: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String?
        let body: String?
        let avatar: AvatarViewModel
        let onTapAction: (() -> Void)?
        let state: AccountDetailsV3State
    }

    enum AccountDetailsV3State {
        case active
        case available
    }
}
