import Foundation
import Neptune

// sourcery: AutoEquatableForTest
struct WisetagHeaderViewModel {
    let avatar: AvatarViewModel
    let title: String
    // sourcery: skipEquality
    let linkType: LinkType
}

extension WisetagHeaderViewModel {
    enum LinkType {
        case active(link: String, touchHandler: () -> Void)
        case inactive(inactiveLink: String)
    }
}
