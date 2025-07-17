import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit

final class PayWithWiseBalanceSelectorViewControllerTests: TWSnapshotTestCase {
    func testLayout() {
        let viewController = PayWithWiseBalanceSelectorViewController(
            viewModel: PayWithWiseBalanceSelectorViewModel.build()
        )

        TWSnapshotVerifyViewController(viewController)
    }
}
