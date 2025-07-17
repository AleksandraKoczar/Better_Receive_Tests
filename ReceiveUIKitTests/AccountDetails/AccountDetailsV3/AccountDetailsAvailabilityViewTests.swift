import Neptune
@testable import ReceiveUIKit
import SwiftUI
import TWFoundation
import TWTestingSupportKit

final class AccountDetailsAvailabilityViewTests: TWSnapshotTestCase {
    func testView_WithMultilineSubtitles() throws {
        try XCTSkipAlways("flaky test")

        let containerViewModel = AvailabilityContainerViewModel(items: [
            .init(title: LoremIpsum.short, subtitle: LoremIpsum.medium, iconStyle: .positive),
            .init(title: LoremIpsum.short, subtitle: LoremIpsum.medium, iconStyle: .negative),
        ])
        let model = AvailabilityViewModel(title: "Availability", containerViewModel: containerViewModel)

        let view = AvailabilityView(model: model)
        TWSnapshotVerifySwiftUIView(view, size: targetSize)
    }
}
