import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit
import TWUI

final class PaymentRequestsListHeaderViewTests: TWSnapshotTestCase {
    func test_view() {
        let view = PaymentRequestsListHeaderView()
        let viewModel = PaymentRequestsListHeaderView.ViewModel(
            title: LargeTitleViewModel(title: LoremIpsum.short),
            segmentedControl: SegmentedControlView.ViewModel(
                segments: [
                    LoremIpsum.veryShort,
                    LoremIpsum.short,
                ],
                selectedIndex: 0,
                onChange: { _ in }
            )
        )
        view.configure(with: viewModel)
        view.layoutForTest()
        TWSnapshotVerifyView(view)
    }
}
