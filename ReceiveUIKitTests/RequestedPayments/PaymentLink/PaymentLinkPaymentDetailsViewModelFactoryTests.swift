import Neptune
import ReceiveKit
@testable import ReceiveUIKit
import TWTestingSupportKit

final class PaymentLinkPaymentDetailsViewModelFactoryTests: TWTestCase {
    func test_make() {
        let factory = PaymentLinkPaymentDetailsViewModelFactoryImpl()
        let result = factory.make(
            from: makePaymentLinkPaymentDetails(),
            delegate: PaymentLinkPaymentDetailsViewModelDelegateMock()
        )

        let expected = makeViewModel()
        expectNoDifference(result, expected)
    }
}

// MARK: - Domain model

private extension PaymentLinkPaymentDetailsViewModelFactoryTests {
    func makePaymentLinkPaymentDetails() -> PaymentLinkPaymentDetails {
        PaymentLinkPaymentDetails.build(
            title: LoremIpsum.veryShort,
            subtitle: LoremIpsum.short,
            sections: [
                PaymentLinkPaymentDetails.Section.build(
                    title: LoremIpsum.veryShort,
                    items: [
                        .optionItem(
                            label: LoremIpsum.veryShort,
                            value: LoremIpsum.short,
                            icon: "urn:wise:icons:refund-sent",
                            action: .navigateToAcquiringTransaction(
                                AcquiringTransactionId(LoremIpsum.veryShort)
                            )
                        ),
                        .optionItem(
                            label: LoremIpsum.veryShort,
                            value: LoremIpsum.short,
                            icon: "urn:wise:icons:receive",
                            action: .navigateToTransfer(
                                ReceiveTransferId(LoremIpsum.veryShort)
                            )
                        ),
                    ]
                ),
                PaymentLinkPaymentDetails.Section.build(
                    title: LoremIpsum.veryShort,
                    items: [
                        .listItem(
                            label: LoremIpsum.short,
                            value: LoremIpsum.medium
                        ),
                        .listItem(
                            label: LoremIpsum.short,
                            value: LoremIpsum.medium
                        ),
                        .listItem(
                            label: LoremIpsum.short,
                            value: LoremIpsum.medium
                        ),
                    ]
                ),
            ]
        )
    }
}

// MARK: View model

private extension PaymentLinkPaymentDetailsViewModelFactoryTests {
    func makeViewModel() -> PaymentLinkPaymentDetailsViewModel {
        PaymentLinkPaymentDetailsViewModel(
            title: LargeTitleViewModel(
                title: LoremIpsum.veryShort,
                description: MarkupLabelModel(text: LoremIpsum.short, actions: [])
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
                                title: LoremIpsum.short,
                                subtitle: MarkupLabelModel(
                                    text: LoremIpsum.medium,
                                    actions: []
                                )
                            )
                        ),
                        .listItem(
                            LegacyListItemViewModel(
                                title: LoremIpsum.short,
                                subtitle: MarkupLabelModel(
                                    text: LoremIpsum.medium,
                                    actions: []
                                )
                            )
                        ),
                        .listItem(
                            LegacyListItemViewModel(
                                title: LoremIpsum.short,
                                subtitle: MarkupLabelModel(
                                    text: LoremIpsum.medium,
                                    actions: []
                                )
                            )
                        ),
                    ]
                ),
            ]
        )
    }
}
