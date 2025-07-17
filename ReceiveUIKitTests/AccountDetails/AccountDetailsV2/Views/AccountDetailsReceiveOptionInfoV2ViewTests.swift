@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import TWUI
import UIKit
import WiseCore

final class AccountDetailsReceiveOptionInfoV2ViewTests: TWSnapshotTestCase {
    func testLayout() {
        let copyAction = Action(
            image: Icons.documents.image,
            discoverabilityTitle: "Copy",
            handler: {}
        )

        let view = AccountDetailsReceiveOptionInfoV2View()
        view.configure(
            with: AccountDetailsReceiveOptionInfoV2ViewModel(
                header: AccountDetailsInfoHeaderV2ViewModel(
                    avatarAccessibilityValue: "",
                    title: LoremIpsum.medium,
                    shareButton: AccountDetailsInfoHeaderV2ViewModel.ShareButton(
                        title: "Share",
                        action: { _ in }
                    ),
                    avatarImageCreator: { _ in
                        CurrencyCode.GBP.icon
                    }
                ),
                rows: [
                    AccountDetailsInfoRowV2ViewModel(
                        title: "Accoaunt holdser",
                        information: "CoWork Ltd",
                        isObfuscated: false,
                        action: copyAction,
                        tooltip: IconButtonView.ViewModel(
                            icon: Icons.questionMarkCircle.image,
                            discoverabilityTitle: "Question",
                            handler: {}
                        )
                    ),
                    AccountDetailsInfoRowV2ViewModel(
                        title: "Sorrt code",
                        information: "1232421421",
                        isObfuscated: true,
                        action: Action(
                            title: "Reveal",
                            discoverabilityTitle: "",
                            handler: {}
                        ),
                        tooltip: IconButtonView.ViewModel(
                            icon: Icons.questionMarkCircle.image,
                            discoverabilityTitle: "Question",
                            handler: {}
                        )
                    ),
                    AccountDetailsInfoRowV2ViewModel(
                        title: "Arrdess",
                        information: LoremIpsum.medium,
                        isObfuscated: false,
                        action: copyAction,
                        tooltip: nil
                    ),
                ]
            )
        )
        view.layoutForTest()

        TWSnapshotVerifyView(view)
    }
}
