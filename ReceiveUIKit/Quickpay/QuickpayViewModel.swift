import Neptune
import UIKit

// sourcery: AutoEquatableForTest
struct QuickpayViewModel {
    let avatar: AvatarViewModel
    let title: String
    let subtitle: String
    // sourcery: skipEquality
    let linkType: LinkType
    let footerAction: Action?
    let nudge: NudgeViewModel?
    let qrCode: WisetagQRCodeViewModel
    let navigationBarButtons: [QuickpayViewModel.ButtonViewModel]
    let circularButtons: [QuickpayViewModel.ButtonViewModel]
    let cardItems: [QuickpayCardViewModel]
    // sourcery: skipEquality
    let onCardTap: (QuickpayCardViewModel) -> Void
}

extension QuickpayViewModel {
    // sourcery: AutoEquatableForTest
    struct ButtonViewModel {
        let icon: UIImage
        let title: String
        // sourcery: skipEquality
        let action: () -> Void
    }
}

extension QuickpayViewModel {
    enum LinkType {
        case active(link: String, touchHandler: () -> Void)
        case inactive(inactiveLink: String)
    }
}
