import BalanceKit
import Neptune
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class AccountDetailsReceiveOptionV2PageViewModelFactoryTests: TWTestCase {
    private var modalDelegate: AccountDetailsInfoModalDelegateMock!

    override func setUp() {
        super.setUp()

        modalDelegate = AccountDetailsInfoModalDelegateMock()
    }

    override func tearDown() {
        modalDelegate = nil

        super.tearDown()
    }
}

// MARK: - Mapping Tests

extension AccountDetailsReceiveOptionV2PageViewModelFactoryTests {
    func testMappingStandart() {
        let expected = AccountDetailsReceiveOptionV2PageViewModel(
            title: "Sth",
            type: .local,
            alert: AccountDetailsReceiveOptionV2PageViewModel.Alert(
                style: .warning,
                viewModel: InlineAlertViewModel(
                    message: "Content",
                    action: Action(title: "Something is wrong", handler: {})
                )
            ),
            summaries: [
                SummaryViewModel(
                    title: "Sum title 1",
                    icon: Icons.limit.image,
                    info: {}
                ),
                SummaryViewModel(
                    title: "Sum title 2",
                    icon: Icons.infoCircle.image,
                    info: nil
                ),
            ],
            infoViewModel: AccountDetailsReceiveOptionInfoV2ViewModel.build(
                header: AccountDetailsInfoHeaderV2ViewModel(
                    avatarAccessibilityValue: "British Pound",
                    title: "GBP account details",
                    shareButton: AccountDetailsInfoHeaderV2ViewModel.ShareButton(
                        title: "Share",
                        action: { _ in }
                    ),
                    avatarImageCreator: { _ in
                        CurrencyCode.GBP.icon
                    }
                ),
                rows: [
                    AccountDetailsInfoRowV2ViewModel.build(title: "Item 1 Title"),
                    AccountDetailsInfoRowV2ViewModel.build(
                        title: "Item 2 Title",
                        tooltip: IconButtonView.ViewModel(
                            icon: Icons.questionMarkCircle.image,
                            discoverabilityTitle: "More information",
                            handler: {}
                        )
                    ),
                    AccountDetailsInfoRowV2ViewModel.build(
                        title: "Item 3 Title",
                        information: "Item 3 Body",
                        isObfuscated: true,
                        tooltip: nil
                    ),
                ]
            ),
            nudge: NudgeViewModel(
                title: "How to use your GBP account details",
                asset: .globe,
                ctaTitle: "See how they work",
                onSelect: {}
            )
        )
        let viewModel = AccountDetailsReceiveOptionV2PageViewModelFactory.make(
            currencyCode: .GBP,
            receiveOption: AccountDetailsReceiveOption.build(
                title: "Sth",
                summaries: [
                    AccountDetailsSummaryItem.build(
                        type: .limit,
                        title: "Sum title 1",
                        description: AccountDetailsDescription.build(
                            title: "Sum desc title 1"
                        )
                    ),
                    AccountDetailsSummaryItem.build(
                        type: .info,
                        title: "Sum title 2",
                        description: nil
                    ),
                ],
                details: [
                    AccountDetailsDetailItem.build(
                        title: "Item 1 Title"
                    ),
                    AccountDetailsDetailItem.build(
                        title: "Item 2 Title",
                        description: AccountDetailsDescription.canned
                    ),
                    AccountDetailsDetailItem.build(
                        title: "Item 3 Title",
                        body: "Item 3 Body",
                        shouldObfuscate: true
                    ),
                ],
                shareText: "Sth",
                alert: AccountDetailsAlert.build(
                    content: "Content",
                    type: .warning,
                    action: AccountDetailsAlert.Action.build(
                        text: "Something is wrong",
                        uri: ""
                    )
                )
            ),
            modalDelegate: modalDelegate,
            accountDetailsType: .standard,
            nudgeSelectAction: {},
            alertAction: { _ in }
        )

        expectNoDifference(expected, viewModel)
    }

    func testMappingForDirectDebitsType() {
        let expected = NudgeViewModel(
            title: "How to set up Direct Debits",
            asset: .calendar,
            ctaTitle: "See how they work",
            onSelect: {}
        )
        let viewModel = AccountDetailsReceiveOptionV2PageViewModelFactory.make(
            currencyCode: .GBP,
            receiveOption: .canned,
            modalDelegate: modalDelegate,
            accountDetailsType: .directDebit,
            nudgeSelectAction: {},
            alertAction: { _ in }
        ).nudge

        expectNoDifference(expected, viewModel)
    }

    func testMappingForEURAccountDetails() {
        let expected = NudgeViewModel(
            title: L10n.AccountDetails.Info.AccountDetails.Nudge.Nbb.title,
            asset: .globe,
            ctaTitle: L10n.AccountDetails.Info.Nudge.Action.Nbb.title,
            onSelect: {}
        )
        let viewModel = AccountDetailsReceiveOptionV2PageViewModelFactory.make(
            currencyCode: .EUR,
            receiveOption: .canned,
            modalDelegate: modalDelegate,
            accountDetailsType: .standard,
            nudgeSelectAction: {},
            alertAction: { _ in }
        ).nudge

        expectNoDifference(expected, viewModel)
    }
}
