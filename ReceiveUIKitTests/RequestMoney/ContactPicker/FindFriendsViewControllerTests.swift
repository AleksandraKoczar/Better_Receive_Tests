import Neptune
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit

final class FindFriendsViewControllerTests: TWSnapshotTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipAlways("TODO: view implementation should be fixed to use common layout method instead of manual autolayout")
    }

    func test_layout() {
        let modelProvider = FindFriendsModelProvider()

        let viewController = FindFriendsViewController(
            modelProvider: modelProvider,
            actionHandler: FindFriendsActionDelegateMock()
        )

        TWSnapshotVerifyViewController(viewController)
    }

    func test_layout_withLearnMore() {
        let modelProvider = FindFriendsModelProvider()

        let viewController = FindFriendsViewController(
            modelProvider: modelProvider,
            actionHandler: FindFriendsActionDelegateMock()
        )

        viewController.loadViewIfNeeded()
        viewController.pageUpdate(2)

        TWSnapshotVerifyViewController(viewController)
    }
}
