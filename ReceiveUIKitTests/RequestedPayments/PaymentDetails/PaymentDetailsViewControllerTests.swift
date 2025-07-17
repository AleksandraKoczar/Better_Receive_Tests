import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class PaymentDetailsViewControllerTests: TWSnapshotTestCase {
    private var viewController: PaymentDetailsViewController!
    private var presenter: PaymentDetailsPresenterMock!

    override func setUp() {
        super.setUp()
        presenter = PaymentDetailsPresenterMock()
        viewController = PaymentDetailsViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }

    func test_screen() {
        let viewModel = makeViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_withoutAlert() {
        let viewModel = makeViewModel(hasAlert: false)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    // MARK: - Helpers

    private func makeViewModel(hasAlert: Bool = true) -> PaymentDetailsViewModel {
        let alert = PaymentDetailsViewModel.Alert(
            viewModel: InlineAlertViewModel(message: LoremIpsum.medium),
            style: .warning
        )
        return PaymentDetailsViewModel(
            title: LoremIpsum.short,
            alert: hasAlert ? alert : nil,
            items: [
                PaymentDetailsViewModel.Item.listItem(
                    ReceiptItemViewModel(
                        title: LoremIpsum.veryShort,
                        value: LoremIpsum.short
                    )
                ),
                .separator,
                .listItem(
                    ReceiptItemViewModel(
                        title: LoremIpsum.veryShort,
                        value: LoremIpsum.short
                    )
                ),
                .listItem(
                    ReceiptItemViewModel(
                        title: LoremIpsum.veryShort,
                        value: LoremIpsum.short
                    )
                ),
            ],
            footerAction: Action(
                title: LoremIpsum.veryShort,
                handler: {}
            )
        )
    }
}
