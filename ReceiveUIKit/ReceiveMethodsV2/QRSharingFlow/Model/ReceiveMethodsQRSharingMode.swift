import Foundation
import ReceiveKit

enum ReceiveMethodsQRSharingMode {
    case all
    case single(SingleSharingModel)

    // sourcery: Buildable
    struct SingleSharingModel {
        let alias: ReceiveMethodAlias
        let amount: Decimal?
        let message: String?
    }
}
