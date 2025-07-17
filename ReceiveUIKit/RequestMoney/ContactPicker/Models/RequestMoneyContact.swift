import ContactsKit
import Foundation
import Neptune

// sourcery: AutoEquatableForTest, Buildable
public struct RequestMoneyContact {
    // It shouldn't be used explicitly in this context
    private let id: ContactId
    let title: String
    let subtitle: String
    let hasRequestCapability: Bool
    let avatarPublisher: AvatarPublisher

    public init(
        id: ContactId,
        title: String,
        subtitle: String,
        hasRequestCapability: Bool,
        avatarPublisher: AvatarPublisher
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.hasRequestCapability = hasRequestCapability
        self.avatarPublisher = avatarPublisher
    }
}

extension RequestMoneyContact {
    var requestCapableContactId: ContactId? {
        guard hasRequestCapability else {
            return nil
        }
        return id
    }
}
