import ReceiveKit
@testable import ReceiveUIKit
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport
import WiseCoreTestingSupport

final class ReviewRefundViewTests: TWSnapshotTestCase {
    func testLayout() {
        let viewModel = ReviewRefundViewModel(
            paymentId: "",
            refund: .init(
                amount: .build(currency: .EUR, value: 1.2),
                reason: "Sent too much",
                payerData: .init(name: "Some name", email: "email@email.com")
            ),
            profileId: .canned,
            useCase: AcquiringPaymentUseCaseMock(),
            delegate: nil
        )
        let view = ReviewRefundView(viewModel: viewModel)
        viewModel.configureView()

        TWSnapshotVerifySwiftUIScreen(view)
    }
}
