import Combine
import ContactsKit
import Neptune

// sourcery: AutoEquatable, Buildable
struct ContactPickerRecentContact: Identifiable {
    let id: String // unique id to make SwiftUI happy
    let contactId: Contact.Id
    let title: String
    let subtitle: String
    let isLoading: Bool
    let contact: Contact
    // sourcery: skipEquality
    let avatarPublisher: AnyPublisher<AvatarViewModel, Never>
}

extension ContactPickerRecentContact {
    init(contact: Contact) {
        self.init(
            id: contact.id.stringValue,
            contactId: contact.id,
            title: contact.title,
            subtitle: contact.subtitle,
            isLoading: false,
            contact: contact,
            avatarPublisher: contact.avatarPublisher.avatarPublisher
                .map {
                    AvatarViewModel(avatar: $0)
                }
                .shareReplay()
                .eraseToAnyPublisher()
        )
    }
}
