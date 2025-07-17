import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class AccountDetailsV2ViewTests: TWSnapshotTestCase {
    func testLayout() {
        let copyAction = Action(
            image: Icons.documents.image,
            discoverabilityTitle: "Copy",
            handler: {}
        )

        let view = AccountDetailsV2View()
        view.configure(
            with: AccountDetailsV2ViewModel(
                title: LargeTitleViewModel(
                    title: LoremIpsum.short
                ),
                receiveOptions: [
                    AccountDetailsReceiveOptionV2PageViewModel(
                        title: LoremIpsum.veryShort,
                        type: .local,
                        alert: AccountDetailsReceiveOptionV2PageViewModel.Alert(
                            style: InlineAlertStyle.warning,
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
                        ),
                        nudge: NudgeViewModel(
                            title: LoremIpsum.veryShort,
                            asset: NudgeViewModel.Asset.globe,
                            ctaTitle: "Do it!",
                            onSelect: {}
                        )
                    ),
                ],
                isExploreEnabled: true
            )
        )
        view.layoutForTest()

        TWSnapshotVerifyView(view)
    }
}
