import ContactsKit
import UIKit

// sourcery: AutoMockable
public protocol WisetagScannedProfileTransferFlowFactory {
    func start(
        with resolvedRecipient: RecipientResolved,
        contactId: String?,
        onHost host: UIViewController
    )
}
