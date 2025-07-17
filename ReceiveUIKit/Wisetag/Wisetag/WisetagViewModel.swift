import Neptune
import UIKit

// sourcery: AutoEquatableForTest
struct WisetagViewModel {
    let header: WisetagHeaderViewModel
    let qrCode: WisetagQRCodeViewModel
    let shareButtons: [WisetagViewModel.ButtonViewModel]
    let footerAction: Action?
    let navigationBarButtons: [WisetagViewModel.ButtonViewModel]
}

extension WisetagViewModel {
    // sourcery: AutoEquatableForTest
    struct ButtonViewModel {
        let icon: UIImage
        let title: String
        // sourcery: skipEquality
        let action: () -> Void
    }
}
