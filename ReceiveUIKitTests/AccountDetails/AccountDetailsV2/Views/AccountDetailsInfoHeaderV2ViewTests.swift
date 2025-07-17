@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import TWUI
import UIKit
import WiseCore

final class AccountDetailsInfoHeaderV2ViewTests: TWSnapshotTestCase {
    func testLayout() {
        let view = AccountDetailsInfoHeaderV2View()
        view.configure(
            viewModel: AccountDetailsInfoHeaderV2ViewModel(
                avatarAccessibilityValue: "",
                title: "Receive from a bank in UK",
                shareButton: .init(
                    title: "Share",
                    action: { _ in }
                ),
                avatarImageCreator: { _ in
                    CurrencyCode.GBP.icon
                }
            )
        )
        view.layoutForTest()

        TWSnapshotVerifyView(view)
    }
}
