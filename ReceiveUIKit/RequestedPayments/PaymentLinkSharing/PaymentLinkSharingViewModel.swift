import Neptune
import UIKit

// sourcery: AutoEquatableForTest
struct PaymentLinkSharingViewModel {
    let qrCodeImage: UIImage?
    let title: String
    let amount: String
    let navigationOptions: [NavigationOption]

    // sourcery: AutoEquatableForTest
    struct NavigationOption {
        let viewModel: OptionViewModel
        // sourcery: skipEquality
        let onTap: () -> Void
    }
}
