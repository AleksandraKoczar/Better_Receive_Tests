import Foundation
import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit
import TWUITestingSupport

final class PayWithWiseRequestDetailsViewTests: TWSnapshotTestCase {
    private let title = LoremIpsum.veryShort
    private let rows: [LegacyListItemViewModel] = [
        LegacyListItemViewModel(
            title: LoremIpsum.veryShort,
            subtitle: LoremIpsum.short
        ),
        LegacyListItemViewModel(
            title: String(LoremIpsum.veryShort.reversed()),
            subtitle: String(LoremIpsum.short.reversed())
        ),
    ]
}

// MARK: - Tests

extension PayWithWiseRequestDetailsViewTests {
    func testLayoutWithoutButton() {
        let viewModel = PayWithWiseRequestDetailsView.ViewModel(
            title: title,
            rows: rows,
            buttonConfiguration: nil
        )

        let vc = BottomSheetViewController.makeWithSwiftUIContent(
            title: viewModel.title
        ) {
            PayWithWiseRequestDetailsView(viewModel: viewModel)
        }
        TWSnapshotVerifyViewController(vc)
    }

    func testLayoutWithButton() {
        let viewModel = PayWithWiseRequestDetailsView.ViewModel(
            title: title,
            rows: rows,
            buttonConfiguration: (
                title: LoremIpsum.veryShort,
                handler: {}
            )
        )
        let vc = BottomSheetViewController.makeWithSwiftUIContent(
            title: viewModel.title
        ) {
            PayWithWiseRequestDetailsView(viewModel: viewModel)
        }
        TWSnapshotVerifyViewController(vc)
    }
}
