import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import SwiftUI
import TWFoundation
import TWTestingSupportKit

final class AccountDetailsV3ViewControllerTests: TWSnapshotTestCase {
    private var viewController: AccountDetailsV3ViewController!
    private var presenter: AccountDetailsV3PresenterMock!

    override func setUp() {
        super.setUp()
        presenter = AccountDetailsV3PresenterMock()
        viewController = AccountDetailsV3ViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }

    func testView() throws {
        presenter.viewActionDelegate = AccountDetailsV3ViewActionDelegateMock()
        let viewModel = makeAccountDetailsModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    private func makeAccountDetailsModel() -> AccountDetailsV3 {
        let availability = AccountDetailsV3Availability.build(
            title: "Availability",
            items: [
                AccountDetailsV3Availability.AvailabilityItem.build(
                    type: .positive,
                    title: "Direct debit",
                    body: LoremIpsum.short
                ),
            ]
        )

        let header = AccountDetailsV3Method.DetailsHeader.build(
            title: "Receive PLN",
            body: AccountDetailsV3Markup.build(
                value: "More info",
                action: nil
            ),
            actions: [
                AccountDetailsV3Method.DetailsHeader.AccountDetailsHeaderAction.share(
                    .build(
                        title: "Share",
                        copyText: "Share"
                    )
                ),
            ]
        )

        let method = AccountDetailsV3Method.build(
            header: header,
            details: [AccountDetailsV3Method.AccountDetailsItem.build(
                title: "Account number",
                body: "1010101010",
                information: AccountDetailsV3Markup.build(value: "Some value", action: nil),
                action: .copy(.build(
                    icon: "urn:org:icons:confetti",
                    accessibilityLabel: "receive-methods.details.account-number.accessibility-label",
                    typeRawValue: "COPY",
                    copyText: "1010101010",
                    feedbackText: "receive-methods.details.copy-feedback"
                ))
            )]
        )

        let informationItem = AccountDetailsV3Information.InformationItem.build(
            type: .fees,
            title: "Fees",
            description: "Description about fees",
            summaries: [AccountDetailsV3Information.InformationItem.PreviewSummary.build(
                icon: "speed",
                title: "Title",
                body: "Body",
                information: "Information"
            )],
            detailedSummaries: AccountDetailsV3Information.InformationItem.DetailedSummary.build(
                title: "account.details.speed.information.title",
                subtitle: "account.details.speed.information.subtitle",
                groups: [AccountDetailsV3Information.InformationItem.DetailedSummary.DetailedSummaryGroup.build(
                    title: "account.details.speed.information.title",
                    icon: "urn:org:icon:confetti",
                    items: [AccountDetailsV3Information.InformationItem.DetailedSummary.DetailedSummaryGroup.DetailedSummaryGroupItem.build(
                        title: "account.details.speed.information.title",
                        body: "account.details.speed.information.body"
                    )]
                )],
                actions: [AccountDetailsV3Information.InformationItem.DetailedSummary.ModalButton.canned]
            )
        )

        let information = AccountDetailsV3Information.build(
            title: "Key Information",
            items: [informationItem]
        )

        return AccountDetailsV3.build(
            id: .build(value: 1),
            type: .accountDetails,
            currency: .PLN,
            method: method,
            information: information,
            availability: availability,
            alert: .build(
                type: .neutral,
                body: "This is an alert",
                action: .build(title: "Click here", type: "type", value: "value")
            )
        )
    }
}
