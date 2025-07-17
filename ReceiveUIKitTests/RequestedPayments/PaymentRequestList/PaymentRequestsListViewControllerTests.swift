import Combine
import ContactsKit
import Neptune
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit
import TWUI

final class PaymentRequestsListViewControllerTests: TWSnapshotTestCase {
    private var viewController: PaymentRequestsListViewController!

    override func setUp() {
        super.setUp()
        viewController = PaymentRequestsListViewController(presenter: PaymentRequestsListPresenterMock())
    }

    override func tearDown() {
        viewController = nil
        super.tearDown()
    }

    func test_screen_forEmptySummariesWithMethodsDisabled() {
        let viewModel = makeViewModelForEmptySummariesWithMethodDisabled()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_forEmptySummariesWithMethodsEnabled() {
        let viewModel = makeViewModelForEmptySummariesWithMethodEnabled()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    // MARK: - Helpers

    private func makeHeaderViewModel() -> PaymentRequestsListHeaderView.ViewModel {
        PaymentRequestsListHeaderView.ViewModel(
            title: LargeTitleViewModel(title: L10n.PaymentRequest.List.title),
            segmentedControl: SegmentedControlView.ViewModel(
                segments: [
                    L10n.PaymentRequest.List.Chip.unpaid,
                    L10n.PaymentRequest.List.Chip.paid,
                ],
                selectedIndex: 0,
                onChange: { _ in }
            )
        )
    }

    private func makeViewModelForEmptySummariesWithMethodEnabled() -> PaymentRequestsListViewModel {
        PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(
                    title: "New",
                    icon: Icons.plus.image,
                    action: {}
                ),
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(
                    title: nil,
                    icon: Icons.slider.image,
                    action: {}
                ),
            ],
            header: makeHeaderViewModel(),
            content: .empty(
                EmptyViewModel(
                    illustrationConfiguration: .init(asset: .image(Neptune.Illustrations.receive.image)),
                    message: .text(L10n.PaymentRequest.List.Empty.unpaid)
                )
            ),
            isCreatePaymentRequestHidden: false
        ))
    }

    private func makeViewModelForEmptySummariesWithMethodDisabled() -> PaymentRequestsListViewModel {
        PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: [PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(
                title: "New",
                icon: Icons.plus.image,
                action: {}
            )],
            header: makeHeaderViewModel(),
            content: .empty(
                EmptyViewModel(
                    illustrationConfiguration: .init(asset: .image(Neptune.Illustrations.receive.image)),
                    message: .text(L10n.PaymentRequest.List.Empty.unpaid)
                )
            ),
            isCreatePaymentRequestHidden: false
        ))
    }
}
