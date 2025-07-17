import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import TWUI
import UIKit

final class AccountDetailsListItemViewTests: TWSnapshotTestCase {
    @MainActor
    func testLayout() {
        let view = AccountDetailsListItemView()
        view.configure(
            with: AccountDetailsListItemViewModel(
                title: "Our address",
                subtitle: "56 Shoreditch\nHigh Street London\nE1 6JJ\nUnited Kingdom",
                action: Action(
                    image: Icons.documents.image,
                    discoverabilityTitle: "Copy"
                ),
                tooltip: IconButtonView.ViewModel(
                    icon: Icons.questionMarkCircle.image,
                    discoverabilityTitle: "More",
                    handler: {}
                )
            )
        )
        view.layoutForTest()

        TWSnapshotVerifyView(view)
    }
}
