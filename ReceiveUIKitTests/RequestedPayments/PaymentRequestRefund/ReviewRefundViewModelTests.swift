import ReceiveKit
@testable import ReceiveUIKit
import Testing
import TWFoundation
import UserKitTestingSupport
import WiseCoreTestingSupport

@MainActor
struct ReviewRefundViewModelTests {
    private var viewModel: ReviewRefundViewModel!
    private var useCase: AcquiringPaymentUseCaseMock!
    private var delegate: ReviewRefundDelegateMock!

    init() {
        delegate = ReviewRefundDelegateMock()
        useCase = AcquiringPaymentUseCaseMock()
        viewModel = ReviewRefundViewModel(
            paymentId: "",
            refund: .init(
                amount: .build(currency: .EUR, value: 3.2),
                reason: "Sent too much",
                payerData: .init(name: "My name", email: nil)
            ),
            profileId: .canned,
            useCase: useCase,
            delegate: delegate
        )
    }

    @Test
    func viewIsCorrect() {
        let expectedSections = [
            ReviewRefundContent.Section(
                title: "Refund",
                items: [
                    .init(title: "Amount", subtitle: "3.20\(MoneyFormatter.unbreakableSpace)EUR"),
                    .init(title: "Reason to refund", subtitle: "Sent too much"),
                ]
            ),
            ReviewRefundContent.Section(
                title: "Customer details",
                items: [
                    .init(title: "To", subtitle: "My name"),
                ]
            ),
        ]
        viewModel.configureView()

        #expect(viewModel.state.content?.sections == expectedSections)
    }

    @MainActor @Test
    func delegateIsCalledWhenEditTapped() {
        viewModel.editTapped()

        #expect(delegate.dismissCalled)
    }

    @MainActor @Test
    func delegateIsCalledWhenRefundTapped() async {
        useCase.refundClosure = { _, _, _, _ in }

        await viewModel.refundTapped()

        #expect(delegate.showSuccessCalled)
    }
}
