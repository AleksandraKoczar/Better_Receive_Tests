import Foundation
import ReceiveKit
import UIKit

struct DetailsHeaderViewModel {
    let title: String
    let subtitle: AccountDetailsV3Markup
    let handleSubtitleMarkup: ((AccountDetailsV3Markup) -> Void)?
    let actions: [DetailsHeaderActionViewModel]

    struct DetailsHeaderActionViewModel: Identifiable {
        let id = UUID()
        let title: String
        let handleAction: (() -> Void)?
    }
}
