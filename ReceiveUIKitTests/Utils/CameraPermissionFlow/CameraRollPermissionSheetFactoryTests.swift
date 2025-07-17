import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class CameraRollPermissionSheetFactoryTests: TWSnapshotTestCase {
    private var factory: CameraRollPermissionSheetFactory!
    override func setUp() {
        super.setUp()
        factory = CameraRollPermissionSheetFactoryImpl()
    }

    override func tearDown() {
        factory = nil
        super.tearDown()
    }

    func test_makeCustomAlert() {
        let sheet = factory.makeCustomAlertBottomSheet(
            title: title,
            message: message,
            primaryAction: primaryActionCustom
        )
        TWSnapshotVerifyViewController(sheet)
    }
}

private extension CameraRollPermissionSheetFactoryTests {
    var title: String { "Some camera title here" }
    var message: String { "Some camera permission message here." }
    var primaryAction: UIAlertAction {
        .init(
            title: "Primary action",
            style: .default,
            handler: { _ in }
        )
    }

    var secondaryAction: UIAlertAction {
        .init(
            title: "Secondary action",
            style: .cancel,
            handler: { _ in }
        )
    }

    var primaryActionCustom: Action {
        .init(
            title: "Primary action",
            handler: {}
        )
    }
}
