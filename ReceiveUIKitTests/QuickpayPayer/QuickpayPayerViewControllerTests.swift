import Neptune
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit

final class QuickpayPayerViewControllerTests: TWSnapshotTestCase {
    private var viewController: QuickpayPayerViewController!
    private var presenter: QuickpayPayerPresenterMock!

    override func setUp() {
        super.setUp()
        presenter = QuickpayPayerPresenterMock()
        viewController = QuickpayPayerViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }

    func test_screen() {
        let viewModel = makeQuickpayPayerViewModel(description: "test")
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    // MARK: - Helpers

    private func makeQuickpayPayerViewModel(description: String?) -> QuickpayPayerViewModel {
        QuickpayPayerViewModel(
            avatar: .canned,
            businessName: "Bolt",
            subtitle: "Wise Business Account",
            moneyInputViewModel: .init(
                titleText: "You pay",
                amount: "10",
                currencyName: "PLN",
                currencyAccessibilityName: "PLN",
                flagImage: FlagFactory.fallback
            ),
            description: description
        )
    }
}
