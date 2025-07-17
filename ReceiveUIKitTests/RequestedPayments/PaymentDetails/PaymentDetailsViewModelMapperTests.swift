import Neptune
import ReceiveKit
@testable import ReceiveUIKit
import TWTestingSupportKit

final class PaymentDetailsViewModelMapperTests: TWTestCase {
    private var delegate: PaymentDetailsViewModelMapperDelegateMock!
    private let paymentId = "some-payment-id"
    private let illustrationUrn = "urn:wise:illustrations:construction-fence"

    override func setUp() {
        super.setUp()
        delegate = PaymentDetailsViewModelMapperDelegateMock()
    }

    override func tearDown() {
        delegate = nil
        super.tearDown()
    }

    func test_make_givenHasRefundAction_andRefundIsEnabled_thenCreateCorrectViewModel() {
        delegate.isRefundEnabledReturnValue = true

        let paymentDetails = makePaymentDetails(action: .refund(paymentId: paymentId))
        let result = PaymentDetailsViewModelMapper.make(
            from: paymentDetails,
            delegate: delegate
        )

        let action = makeRefundPaymentAction()
        let expected = makeExpectedViewModel(action: action)
        expectNoDifference(result, expected)
    }

    func test_make_givenHasRefundAction_butRefundIsDisabled_thenCreateCorrectViewModel() {
        delegate.isRefundEnabledReturnValue = false

        let paymentDetails = makePaymentDetails(action: .refund(paymentId: paymentId))
        let result = PaymentDetailsViewModelMapper.make(
            from: paymentDetails,
            delegate: delegate
        )

        let expected = makeExpectedViewModel(action: nil)
        expectNoDifference(result, expected)
    }

    func test_make_givenHasRefundDisableAction_thenCreateCorrectViewModel() {
        delegate.isRefundEnabledReturnValue = false

        let paymentDetails = makePaymentDetails(
            action: .refundDisabled(
                title: LoremIpsum.short,
                message: LoremIpsum.medium,
                illustrationUrn: illustrationUrn
            )
        )
        let result = PaymentDetailsViewModelMapper.make(
            from: paymentDetails,
            delegate: delegate
        )

        let action = makeRefundPaymentAction()
        let expected = makeExpectedViewModel(action: action)
        expectNoDifference(result, expected)
    }

    // MARK: - Helpers

    private func makePaymentDetails(action: PaymentDetails.Action) -> PaymentDetails {
        PaymentDetails.build(
            title: LoremIpsum.short,
            alert: PaymentDetails.Alert.build(
                content: LoremIpsum.medium,
                state: .warning
            ),
            items: [
                PaymentRequestDetailsSection.Item.listItem(
                    label: LoremIpsum.short,
                    value: LoremIpsum.medium,
                    action: nil
                ),
                .divider,
                .listItem(
                    label: LoremIpsum.short,
                    value: LoremIpsum.medium,
                    action: nil
                ),
                .listItem(
                    label: LoremIpsum.short,
                    value: LoremIpsum.medium,
                    action: nil
                ),
            ],
            actions: [action]
        )
    }

    private func makeExpectedViewModel(action: Action?) -> PaymentDetailsViewModel {
        PaymentDetailsViewModel(
            title: LoremIpsum.short,
            alert: PaymentDetailsViewModel.Alert(
                viewModel: InlineAlertViewModel(message: LoremIpsum.medium),
                style: .warning
            ),
            items: [
                PaymentDetailsViewModel.Item.listItem(
                    ReceiptItemViewModel(
                        title: LoremIpsum.short,
                        value: LoremIpsum.medium
                    )
                ),
                .separator,
                .listItem(
                    ReceiptItemViewModel(
                        title: LoremIpsum.short,
                        value: LoremIpsum.medium
                    )
                ),
                .listItem(
                    ReceiptItemViewModel(
                        title: LoremIpsum.short,
                        value: LoremIpsum.medium
                    )
                ),
            ],
            footerAction: action
        )
    }

    private func makeRefundPaymentAction() -> Action {
        Action(
            title: "Refund payment",
            handler: {}
        )
    }
}
