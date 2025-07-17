import ContactsKit
import Foundation

// sourcery: AutoMockable
protocol RequestMoneyContactPickerRouter: AnyObject {
    func createPaymentRequest(
        contact: Contact?
    )
    func startSearch()
    func inviteFriendsNudgeTapped()
    func findFriendsNudgeTapped()
    func dismiss()
}
