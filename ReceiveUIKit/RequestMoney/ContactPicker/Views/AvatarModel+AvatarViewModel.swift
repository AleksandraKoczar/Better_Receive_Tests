import ContactsKit
import Neptune

extension AvatarModel {
    func asAvatarViewModel() -> AvatarViewModel {
        switch self {
        case let .image(image, badge):
            AvatarViewModel.image(image, badge: badge)
        case let .icon(image, badge):
            AvatarViewModel.icon(image, badge: badge)
        case let .initials(initials, badge):
            AvatarViewModel.initials(initials, badge: badge)
        }
    }
}
