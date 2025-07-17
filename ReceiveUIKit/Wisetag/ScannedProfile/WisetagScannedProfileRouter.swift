import ContactsKit
import Foundation
import UserKit

// sourcery: AutoMockable
protocol WisetagScannedProfileRouter: AnyObject {
    func sendMoney(_ contact: RecipientResolved, contactId: String?)
    func requestMoney(_ contact: Contact)
    func dismiss()
}
