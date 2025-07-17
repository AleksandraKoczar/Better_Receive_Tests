import Foundation
import Neptune
@testable import ReceiveUIKit

extension InlineAlertViewModel {
    static var canned: InlineAlertViewModel {
        .init(message: .canned)
    }
}

extension InlineAlertStyle {
    static var canned: InlineAlertStyle {
        .neutral
    }
}

extension SectionHeaderViewModel {
    static var canned: SectionHeaderViewModel {
        .init(title: .canned)
    }
}

extension AccountDetailsInfoHeaderV2ViewModel {
    internal static func build(
        avatarAccessibilityValue: String = .canned,
        title: String = .canned,
        shareButton: AccountDetailsInfoHeaderV2ViewModel.ShareButton? = .canned
    ) -> AccountDetailsInfoHeaderV2ViewModel {
        AccountDetailsInfoHeaderV2ViewModel(
            avatarAccessibilityValue: avatarAccessibilityValue,
            title: title,
            shareButton: shareButton,
            avatarImageCreator: { _ in Icons.globe.image }
        )
    }

    internal static var canned: AccountDetailsInfoHeaderV2ViewModel {
        AccountDetailsInfoHeaderV2ViewModel.build()
    }
}
