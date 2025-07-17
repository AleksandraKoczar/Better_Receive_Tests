import Foundation
import UIKit

struct ReceiveMethodsQRSharingViewModel {
    let title: String
    let subtitle: String
    let keys: [Key]
    let buttons: [ButtonViewModel]

    struct Key: Identifiable {
        let id = UUID()

        let qr: UIImage
        let method: Method
        let type: String
        let value: String

        struct Method {
            let icon: UIImage
            let name: String
        }
    }

    struct ButtonViewModel {
        let icon: UIImage
        let title: String
        let isPrimary: Bool
        let action: () -> Void
    }
}
