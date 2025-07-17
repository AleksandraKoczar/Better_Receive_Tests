import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class PaymentLinkSharingViewTests: TWSnapshotTestCase {
    private var viewController: PaymentLinkSharingViewController!

    override func setUp() {
        super.setUp()
        viewController = .init(presenter: PaymentLinkSharingPresenterMock())
    }

    override func tearDown() {
        viewController = nil
        super.tearDown()
    }

    func test_layout() {
        viewController.configure(
            with: .init(
                qrCodeImage: UIImage.color(.red),
                title: "Title",
                amount: "100 GBP",
                navigationOptions: [
                    .init(viewModel: .init(title: "Action 1", avatar: .icon(Icons.card.image)), onTap: {}),
                    .init(viewModel: .init(title: "Action 2", avatar: .icon(Icons.card.image)), onTap: {}),
                ]
            )
        )

        TWSnapshotVerifyViewController(viewController)
    }
}
