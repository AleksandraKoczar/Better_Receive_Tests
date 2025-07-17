@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import TWUI
import UIKit
import WiseCore

final class AccountDetailsReceiveOptionV2PageViewTests: TWSnapshotTestCase {
    func testLayout() {
        let view = AccountDetailsReceiveOptionV2PageView(
            viewModel: AccountDetailsReceiveOptionV2PageViewModel(
                title: LoremIpsum.veryShort,
                type: .local,
                alert: AccountDetailsReceiveOptionV2PageViewModel.Alert(
                    style: .warning,
                    viewModel: InlineAlertViewModel(
                        message: LoremIpsum.short,
                        action: Action(
                            title: "Do something",
                            handler: {}
                        )
                    )
                ),
                summaries: [
                    SummaryViewModel(
                        title: LoremIpsum.veryShort,
                        icon: Icons.download.image
                    ),
                    SummaryViewModel(
                        title: "LoremIpsum.veryShort",
                        icon: Icons.info.image
                    ),
                ],
                infoViewModel: AccountDetailsReceiveOptionInfoV2ViewModel(
                    header: AccountDetailsInfoHeaderV2ViewModel(
                        avatarAccessibilityValue: "",
                        title: LoremIpsum.veryShort,
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
                            title: LoremIpsum.veryShort,
                            information: "Lorem ipsum not short",
                            isObfuscated: false,
                            action: Action(
                                image: Icons.documents.image,
                                discoverabilityTitle: "Copy"
                            ),
                            tooltip: nil
                        ),
                        AccountDetailsInfoRowV2ViewModel(
                            title: "Lorem ipsum not short",
                            information: LoremIpsum.veryShort,
                            isObfuscated: false,
                            action: Action(
                                image: Icons.documents.image,
                                discoverabilityTitle: "Copy"
                            ),
                            tooltip: nil
                        ),
                    ]
                ),
                nudge: NudgeViewModel(
                    title: LoremIpsum.veryShort,
                    asset: NudgeViewModel.Asset.globe,
                    ctaTitle: "Do it!",
                    onSelect: {}
                )
            )
        )
        view.layoutForTest()

        TWSnapshotVerifyView(view)
    }
}
