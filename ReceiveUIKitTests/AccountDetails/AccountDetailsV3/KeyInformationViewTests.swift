import Neptune
@testable import ReceiveUIKit
import SwiftUI
import TWFoundation
import TWTestingSupportKit

final class KeyInformationViewTests: TWSnapshotTestCase {
    func testView_GivenSupportsDetailedSummary() throws {
        try XCTSkipAlways("flaky test")
        let chips = [
            KeyInformationViewModel.ChipViewModel(title: "Speed", type: .speed),
            KeyInformationViewModel.ChipViewModel(title: "Fees", type: .fees),
        ]

        let speedItems = [
            KeyInformationListItemViewModel(title: LoremIpsum.short, subtitle: LoremIpsum.short, description: LoremIpsum.short),
            KeyInformationListItemViewModel(title: LoremIpsum.short, subtitle: LoremIpsum.short, description: LoremIpsum.short),
        ]

        let feesItems = [
            KeyInformationListItemViewModel(title: LoremIpsum.short, subtitle: LoremIpsum.short, description: LoremIpsum.short),
            KeyInformationListItemViewModel(title: LoremIpsum.short, subtitle: LoremIpsum.short, description: LoremIpsum.short),
        ]

        let items = [
            KeyInformationItem(
                type: .speed,
                subtitle: LoremIpsum.short,
                isDetailSupported: true,
                items: speedItems
            ),
            KeyInformationItem(
                type: .fees,
                subtitle: LoremIpsum.short,
                isDetailSupported: false,
                items: feesItems
            ),
        ]

        let model = KeyInformationViewModel(
            title: "Key Information",
            chips: chips,
            items: items,
            selectedChip: chips.first!,
            selectedItem: items.first!,
            onContainerTap: { _ in },
            trackChipSelected: { _ in }
        )

        let view = KeyInformationView(model: model)
        TWSnapshotVerifySwiftUIView(view, size: targetSize)
    }
}
