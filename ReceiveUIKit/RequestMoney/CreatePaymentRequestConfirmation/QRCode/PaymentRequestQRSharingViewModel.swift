import Foundation
import Neptune
import UIKit

struct PaymentRequestQRSharingViewModel: Equatable {
    struct ListItemViewModel: Equatable {
        let title: String
        let value: String
    }

    let avatar: AvatarViewModel
    let title: String
    let subtitle: String?
    let qrCodeImage: UIImage?
    let requestDetailsHeader: String
    let requestItems: [ListItemViewModel]
}
