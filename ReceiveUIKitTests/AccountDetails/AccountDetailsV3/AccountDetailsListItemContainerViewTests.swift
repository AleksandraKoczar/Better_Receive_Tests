@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import TWUI
import UIKit
import WiseCore

final class AccountDetailsListItemContainerViewTests: TWSnapshotTestCase {
    func testLayout() throws {
        let view = AccountDetailsListItemContainerView()

        let items = [
            AccountDetailsV3MethodViewModel.ItemViewModel(
                title: LoremIpsum.short,
                body: LoremIpsum.short,
                information: .build(value: "<link>link</link>"),
                action: .init(
                    icon: Icons.documents.image,
                    accessibilityLabel: "",
                    type: .copy,
                    copyText: "",
                    feedbackText: "",
                    handleAction: { _ in }
                ),
                handleMarkup: { _ in }
            ),
            AccountDetailsV3MethodViewModel.ItemViewModel(
                title: LoremIpsum.short,
                body: LoremIpsum.short,
                information: nil,
                action: .init(
                    icon: Icons.documents.image,
                    accessibilityLabel: "",
                    type: .copy,
                    copyText: "",
                    feedbackText: "",
                    handleAction: { _ in }
                ),
                handleMarkup: { _ in }
            ),
            AccountDetailsV3MethodViewModel.ItemViewModel(
                title: LoremIpsum.short,
                body: LoremIpsum.short,
                information: nil,
                action: .init(
                    icon: Icons.documents.image,
                    accessibilityLabel: "",
                    type: .copy,
                    copyText: "",
                    feedbackText: "",
                    handleAction: { _ in }
                ),
                handleMarkup: { _ in }
            ),
            AccountDetailsV3MethodViewModel.ItemViewModel(
                title: LoremIpsum.short,
                body: LoremIpsum.short,
                information: .build(value: "no link"),
                action: .init(
                    icon: Icons.documents.image,
                    accessibilityLabel: "",
                    type: .copy,
                    copyText: "",
                    feedbackText: "",
                    handleAction: { _ in }
                ),
                handleMarkup: { _ in }
            ),
        ]

        let viewModel = AccountDetailsV3MethodViewModel(
            items: items,
            footer: .button(
                AccountDetailsV3MethodViewModel.FooterViewModel.FooterButtonViewModel(
                    title: "Manage",
                    style: LargeSecondaryNeutralButtonAppearance.largeSecondaryNeutral,
                    action: {}
                )
            )
        )
        view.configure(with: viewModel)

        view.layoutForTest()
        TWSnapshotVerifyView(view)
    }
}
