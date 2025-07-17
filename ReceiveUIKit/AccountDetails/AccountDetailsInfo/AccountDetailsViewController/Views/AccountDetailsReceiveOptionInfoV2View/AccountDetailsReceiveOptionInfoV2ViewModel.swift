import Neptune
import UIKit

// sourcery: AutoEquatableForTest
struct AccountDetailsInfoHeaderV2ViewModel {
    // sourcery: AutoEquatableForTest, Buildable
    struct ShareButton {
        let title: String
        // sourcery: skipEquality
        let action: (UIView) -> Void
    }

    let avatarAccessibilityValue: String
    let title: String
    let shareButton: ShareButton?
    // sourcery: skipEquality
    let avatarImageCreator: (SemanticContext) -> UIImage
}

// sourcery: AutoEquatableForTest, Buildable
struct AccountDetailsInfoRowV2ViewModel {
    let title: String
    let information: String
    let isObfuscated: Bool
    // sourcery: skipEquality
    let action: Action
    let tooltip: IconButtonView.ViewModel?
}

// sourcery: AutoEquatableForTest, Buildable
struct AccountDetailsReceiveOptionInfoV2ViewModel {
    let header: AccountDetailsInfoHeaderV2ViewModel
    let rows: [AccountDetailsInfoRowV2ViewModel]
}
