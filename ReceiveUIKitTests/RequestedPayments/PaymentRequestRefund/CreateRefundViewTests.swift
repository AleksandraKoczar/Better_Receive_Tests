import BalanceKit
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import SwiftUI
import TWTestingSupportKit
import UserKitTestingSupport

final class CreateRefundViewTests: TWSnapshotTestCase {
    @MainActor
    func testLayout() async {
        let useCase = AcquiringPaymentUseCaseMock()
        useCase.paymentReturnValue = AcquiringPayment.build(
            balanceId: .build(value: 12),
            refundableAmount: .build(currency: .AUD, value: 1.3)
        )

        let balancesUseCase = BalancesUseCaseMock()
        balancesUseCase.listenToBalancesAsyncStreamReturnValue = .build([.build(id: .build(value: 12), availableAmount: 30)])

        let viewModel = CreateRefundViewModel(
            paymentId: "",
            profileId: .canned,
            useCase: useCase,
            balancesUseCase: balancesUseCase,
            delegate: CreateRefundDelegateMock()
        )

        let vc = SwiftUIHostingController {
            NavigationView {
                CreateRefundView(viewModel: viewModel)
            }.navigationViewStyle(.stack)
        }

        await viewModel.fetchData()

        TWSnapshotVerifyViewController(vc)
    }
}
