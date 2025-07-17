import Foundation
import Neptune

struct AccountDetailsV3Modal {
    let title: String
    let body: String
    let button: ModalButton?
    let trackModalButtonTapped: () -> Void

    struct ModalButton {
        let value: String
        let title: String
        let priority: any LargeButtonAppearance
        let type: String
    }
}
