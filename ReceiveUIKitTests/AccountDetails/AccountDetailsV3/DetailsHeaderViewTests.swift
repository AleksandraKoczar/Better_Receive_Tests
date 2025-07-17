import Neptune
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import SwiftUI
import TWFoundation
import TWTestingSupportKit

final class DetailsHeaderViewTests: TWSnapshotTestCase {
    func testView_WithOneAction() throws {
        try XCTSkipAlways("flaky test")

        let actions = [
            DetailsHeaderViewModel.DetailsHeaderActionViewModel(
                title: "Share",
                handleAction: nil
            ),
        ]

        let model = DetailsHeaderViewModel(
            title: "Receive USD",
            subtitle: .build(value: "From many <link>countries</link>", action: nil),
            handleSubtitleMarkup: nil,
            actions: actions
        )

        let view = AccountDetailsHeaderView(viewModel: model)
        TWSnapshotVerifySwiftUIView(view, size: targetSize)
    }

    func testView_WithTwoActions() throws {
        try XCTSkipAlways("flaky test")

        let actions = [
            DetailsHeaderViewModel.DetailsHeaderActionViewModel(
                title: "Share",
                handleAction: nil
            ),
            DetailsHeaderViewModel.DetailsHeaderActionViewModel(
                title: "Copy",
                handleAction: nil
            ),
        ]

        let model = DetailsHeaderViewModel(
            title: "Receive USD",
            subtitle: .build(value: "From many <link>countries</link>", action: nil),
            handleSubtitleMarkup: nil,
            actions: actions
        )

        let view = AccountDetailsHeaderView(viewModel: model)
        TWSnapshotVerifySwiftUIView(view, size: targetSize)
    }
}
