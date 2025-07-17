import Combine
import ContactsKit
import Neptune
import UIKit

// sourcery: AutoEquatableForTest, Buildable
struct WisetagScannedProfileViewModel {
    let header: WisetagScannedProfileViewModel.HeaderViewModel?
    let footer: WisetagScannedProfileViewModel.FooterViewModel
}

extension WisetagScannedProfileViewModel {
    // sourcery: AutoEquatableForTest, Buildable
    struct HeaderViewModel {
        // sourcery: skipEquality
        let avatar: AnyPublisher<AvatarViewModel, Never>
        let title: String
        let subtitle: String?
        let alert: Alert?

        // sourcery: AutoEquatableForTest
        struct Alert {
            let style: InlineAlertStyle
            let viewModel: InlineAlertViewModel
        }
    }

    // sourcery: AutoEquatableForTest, Buildable
    struct FooterViewModel {
        let buttons: [ButtonViewModel]?
        let isLoading: Bool
    }

    // sourcery: AutoEquatableForTest, Buildable
    struct ButtonViewModel {
        let icon: UIImage
        let title: String
        let enabled: Bool
        // sourcery: skipEquality
        let action: (() -> Void)?
    }
}

public extension AvatarViewModel {
    init(avatar: AvatarModel) {
        switch avatar {
        case let .image(image, badge):
            self = .image(image, badge: badge)
        case let .icon(icon, badge):
            self = .icon(icon, badge: badge)
        case let .initials(initials, badge):
            self = .initials(initials, badge: badge)
        }
    }
}
