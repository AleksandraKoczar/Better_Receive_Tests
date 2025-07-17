import Foundation
import Neptune
import ReceiveKit
import UIKit

struct AccountDetailsV3MethodViewModel {
    let items: [ItemViewModel]
    let footer: FooterViewModel?

    struct ItemViewModel {
        let title: String
        let body: String
        let information: AccountDetailsV3Markup?
        let action: DetailsActionViewModel?
        let handleMarkup: ((AccountDetailsV3Markup) -> Void)?

        struct DetailsActionViewModel {
            let icon: UIImage
            let accessibilityLabel: String
            let type: DetailsActionType
            let copyText: String
            let feedbackText: String
            let handleAction: ((DetailsActionType) -> Void)?

            enum DetailsActionType {
                case copy
            }
        }
    }

    enum FooterViewModel {
        case button(FooterButtonViewModel)

        struct FooterButtonViewModel {
            let title: String
            let style: any LargeButtonAppearance
            let action: () -> Void
        }
    }
}
