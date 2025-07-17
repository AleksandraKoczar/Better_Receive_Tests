import BalanceKit
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import Testing
import TWFoundation
import TWTestingSupportKit
import UserKitTestingSupport

@MainActor
struct CreateRefundViewModelTests {
    private var useCase: AcquiringPaymentUseCaseMock!
    private var delegate: CreateRefundDelegateMock!
    private var viewModel: CreateRefundViewModel!
    private var balancesUseCase: BalancesUseCaseMock!

    init() {
        useCase = AcquiringPaymentUseCaseMock()
        delegate = CreateRefundDelegateMock()
        balancesUseCase = BalancesUseCaseMock()
        viewModel = CreateRefundViewModel(
            paymentId: .canned,
            profileId: .canned,
            useCase: useCase,
            balancesUseCase: balancesUseCase,
            delegate: delegate
        )
    }

    @Test
    func givenPayment_correctValuesAreUpdated() async {
        balancesUseCase.listenToBalancesAsyncStreamReturnValue = .build([.build(availableAmount: 12)])
        useCase.paymentReturnValue = .build(refundableAmount: .build(currency: .EUR, value: 1.3))

        await viewModel.fetchData()

        #expect(viewModel.state.content?.moneyInputInformation?.text == "You can refund any amount up to <link>1.30\(MoneyFormatter.unbreakableSpace)EUR</link>")
        #expect(viewModel.state.content?.refundCurrency == .init(code: "EUR", name: "Euro", supportsDecimals: true))
    }

    @Test
    func givenContinueTapped_delegateIsCalled() async {
        balancesUseCase.listenToBalancesAsyncStreamReturnValue = .build([.canned])
        useCase.paymentReturnValue = .build(refundableAmount: .build(currency: .EUR, value: 1.3))

        await viewModel.fetchData()

        viewModel.continueTapped()

        #expect(delegate.refundInitiatedCalled)
    }

    @Test
    func givenTooLargeInput_errorIsShown() async {
        balancesUseCase.listenToBalancesAsyncStreamReturnValue = .build([.canned])
        useCase.paymentReturnValue = .build(refundableAmount: .build(currency: .EUR, value: 1.3))

        await viewModel.fetchData()

        let valueBinding = viewModel.moneyInputValue()
        valueBinding.wrappedValue.raw = "433"

        #expect(viewModel.state.content?.moneyInputInformation?.text == "Enter an amount less than 1.30 EUR")
        #expect(viewModel.state.content?.moneyInputSentiment == .negative)
    }

    @Test
    func givenNotEnoughMoneyOnBalance_errorIsShown() async {
        balancesUseCase.listenToBalancesAsyncStreamReturnValue = .build([.canned])
        useCase.paymentReturnValue = .build(refundableAmount: .build(currency: .EUR, value: 1.3))

        await viewModel.fetchData()

        #expect(viewModel.state.content?.moneyInputInformation?.text == "To refund this amount you'll first need to top up. <link>Add EUR to your account</link>")
        #expect(viewModel.state.content?.moneyInputSentiment == .negative)
    }

    @Test
    func givenNotEnoughMoneyOnBalance_andButtonTapped_topUpFlowIsStarted() async {
        balancesUseCase.listenToBalancesAsyncStreamReturnValue = .build([.canned])
        useCase.paymentReturnValue = .build(refundableAmount: .build(currency: .EUR, value: 1.3))

        await viewModel.fetchData()

        viewModel.state.content?.moneyInputInformation?.actions.first?.action()

        #expect(delegate.topUpCalled)
    }

    @Test
    func givenNotEnoughMoneyOnBalance_andBalanceToppedUpWithEnoughMoney_viewIsRefreshed() async {
        balancesUseCase.listenToBalancesAsyncStreamReturnValue = .build([.build(id: .build(value: 1), availableAmount: 1)])
        useCase.paymentReturnValue = .build(balanceId: .build(value: 1), refundableAmount: .build(currency: .EUR, value: 1.3))

        await viewModel.fetchData()

        #expect(viewModel.state.content?.moneyInputInformation?.text == "To refund this amount you'll first need to top up. <link>Add EUR to your account</link>")

        balancesUseCase.listenToBalancesAsyncStreamReturnValue = .build([.build(id: .build(value: 1), availableAmount: 12)])

        viewModel.state.content?.moneyInputInformation?.actions.first?.action()
        delegate.topUpReceivedArguments?.completion()

        await viewModel.refreshBalancesTask?.value

        #expect(delegate.topUpCalled)
        #expect(balancesUseCase.listenToBalancesAsyncStreamCallsCount == 2)
        #expect(viewModel.state.content?.moneyInputInformation?.text == "You can refund any amount up to <link>1.30\(MoneyFormatter.unbreakableSpace)EUR</link>")
    }
}
