import Neptune
@testable import ReceiveUIKit
import SwiftUI
import TWFoundation
import TWTestingSupportKit

final class KeyInformationDetailsViewTests: TWSnapshotTestCase {
    func testView_GivenActions() throws {
        try XCTSkipAlways("flaky")
        let items = [
            DetailedSummaryViewModel.DetailedSummaryGroupViewModel.DetailedSummaryGroupItemViewModel(
                title: LoremIpsum.short,
                body: LoremIpsum.long,
                handleURLMarkup: nil
            ),
            DetailedSummaryViewModel.DetailedSummaryGroupViewModel.DetailedSummaryGroupItemViewModel(
                title: LoremIpsum.short,
                body: LoremIpsum.long,
                handleURLMarkup: nil
            ),
        ]
        let groups = [
            DetailedSummaryViewModel.DetailedSummaryGroupViewModel(
                title: LoremIpsum.short,
                icon: Icons.bank.image,
                items: items
            ),
            DetailedSummaryViewModel.DetailedSummaryGroupViewModel(
                title: LoremIpsum.short,
                icon: Icons.confetti.image,
                items: items
            ),
        ]

        let actions = [DetailedSummaryViewModel.DetailedSummaryActionViewModel(
            title: LoremIpsum.short,
            uri: .canned,
            handleAction: { _ in }
        )]

        let model = DetailedSummaryViewModel(
            title: LoremIpsum.short,
            subtitle: LoremIpsum.medium,
            groups: groups,
            actions: actions
        )

        let view = KeyInformationDetailsView(model: model)
        TWSnapshotVerifySwiftUIView(view, size: targetSize)
    }
}
