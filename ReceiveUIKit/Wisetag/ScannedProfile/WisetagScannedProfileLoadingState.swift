import ContactsKit

enum WisetagScannedProfileLoadingState: Equatable {
    case findingUser
    case userFound(scannedProfile: Contact)
    case inContacts(scannedProfile: Contact, contactId: String)
    case recipientAdded(scannedProfile: Contact, contactId: String)
    case isSelf(scannedProfile: Contact)
}
