import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class PaymentLinkPaymentDetailsViewControllerTests: TWSnapshotTestCase {
    func test_screen() {
        let viewController = PaymentLinkPaymentDetailsViewController(
            presenter: PaymentLinkPaymentDetailsPresenterMock()
        )
        let viewModel = makeViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}

// MARK: - Helpers

private extension PaymentLinkPaymentDetailsViewControllerTests {
    func makeViewModel() -> PaymentLinkPaymentDetailsViewModel {
        PaymentLinkPaymentDetailsViewModel(
            title: LargeTitleViewModel(
                title: LoremIpsum.veryShort,
                description: LoremIpsum.short
            ),
            sections: [
                PaymentLinkPaymentDetailsViewModel.Section(
                    title: LoremIpsum.veryShort,
                    items: [
                        .optionItem(
                            PaymentLinkPaymentDetailsViewModel.Section.OptionItem(
                                option: OptionViewModel(
                                    title: LoremIpsum.veryShort,
                                    subtitle: LoremIpsum.short,
                                    avatar: .icon(Icons.refundSent.image)
                                ),
                                onTap: {}
                            )
                        ),
                        .optionItem(
                            PaymentLinkPaymentDetailsViewModel.Section.OptionItem(
                                option: OptionViewModel(
                                    title: LoremIpsum.veryShort,
                                    subtitle: LoremIpsum.short,
                                    avatar: .icon(Icons.receive.image)
                                ),
                                onTap: {}
                            )
                        ),
                    ]
                ),
                PaymentLinkPaymentDetailsViewModel.Section(
                    title: LoremIpsum.veryShort,
                    items: [
                        .listItem(
                            LegacyListItemViewModel(
                                title: LoremIpsum.veryShort,
                                subtitle: LoremIpsum.short
                            )
                        ),
                        .listItem(
                            LegacyListItemViewModel(
                                title: LoremIpsum.veryShort,
                                subtitle: LoremIpsum.short
                            )
                        ),
                        .listItem(
                            LegacyListItemViewModel(
                                title: LoremIpsum.veryShort,
                                subtitle: LoremIpsum.short
                            )
                        ),
                    ]
                ),
            ]
        )
    }
}
