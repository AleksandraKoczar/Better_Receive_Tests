@testable import ReceiveUIKit
import TWTestingSupportKit

final class ContactsNavigationOptionTableViewCellTests: TWTestCase {
    func testPrepareForReuse_WhenCellPreparedForReuse_ThenPresenterMethodCalled() {
        let presenter = AvatarLoadableNavigationOptionTableViewCellPresenterMock()
        let cell = AvatarLoadableNavigationOptionTableViewCellImpl()
        cell.presenter = presenter

        XCTAssertFalse(presenter.prepareForReuseCalled)
        cell.prepareForReuse()
        XCTAssertTrue(presenter.prepareForReuseCalled)
    }
}
