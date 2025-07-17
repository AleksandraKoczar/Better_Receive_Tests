import BalanceKit
import UIKit

// sourcery: AutoMockable
protocol AccountDetailsInfoModalDelegate: AnyObject {
    func copyAccountDetails(
        _ copyText: String,
        for fieldName: String,
        analyticsType: String?
    )
    func showInformationModal(title: String?, description: String?, analyticsType: String?)
    func showCopyableModal(accountDetailItem: AccountDetailsDetailItem)
    func shareAccountDetails(shareText: String, sender: UIView?)
}
