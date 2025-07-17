import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWTestingSupportKit

final class PaymentLinkAllPaymentsViewControllerTests: TWSnapshotTestCase {
    func test_screen() {
        let viewController = PaymentLinkAllPaymentsViewController(presenter: PaymentLinkAllPaymentsPresenterMock())
        let viewModel = makeViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}

// MARK: - Helpers

private extension PaymentLinkAllPaymentsViewControllerTests {
    func makeViewModel() -> PaymentLinkAllPaymentsViewModel {
        PaymentLinkAllPaymentsViewModel(
            title: LargeTitleViewModel(title: LoremIpsum.veryShort),
            content: .sections([
                PaymentLinkAllPaymentsViewModel.Section(
                    id: LoremIpsum.veryShort,
                    title: LoremIpsum.veryShort,
                    viewModel: SectionHeaderViewModel(
                        title: LoremIpsum.short,
                        action: nil,
                        accessibilityHint: LoremIpsum.short
                    ),
                    items: [
                        PaymentLinkAllPaymentsViewModel.Section.OptionItem(
                            id: LoremIpsum.veryShort,
                            option: OptionViewModel(
                                title: LoremIpsum.veryShort,
                                subtitle: LoremIpsum.short,
                                avatar: .icon(Icons.refundSent.image)
                            ),
                            actionType: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort))
                        ),
                        PaymentLinkAllPaymentsViewModel.Section.OptionItem(
                            id: LoremIpsum.veryShort,
                            option: OptionViewModel(
                                title: LoremIpsum.veryShort,
                                subtitle: LoremIpsum.short,
                                avatar: .icon(Icons.receive.image)
                            ),
                            actionType: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort))
                        ),
                    ]
                ),
                PaymentLinkAllPaymentsViewModel.Section(
                    id: LoremIpsum.veryShort,
                    title: LoremIpsum.veryShort,
                    viewModel: SectionHeaderViewModel(
                        title: LoremIpsum.short,
                        action: nil,
                        accessibilityHint: LoremIpsum.short
                    ),
                    items: [
                        PaymentLinkAllPaymentsViewModel.Section.OptionItem(
                            id: LoremIpsum.veryShort,
                            option: OptionViewModel(
                                title: LoremIpsum.veryShort,
                                subtitle: LoremIpsum.short,
                                avatar: .icon(Icons.refundSent.image)
                            ),
                            actionType: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort))
                        ),
                        PaymentLinkAllPaymentsViewModel.Section.OptionItem(
                            id: LoremIpsum.veryShort,
                            option: OptionViewModel(
                                title: LoremIpsum.veryShort,
                                subtitle: LoremIpsum.short,
                                avatar: .icon(Icons.receive.image)
                            ),
                            actionType: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort))
                        ),
                    ]
                ),
            ]
            )
        )
    }
}
