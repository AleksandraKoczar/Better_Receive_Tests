import BalanceKit
import MacrosKit
import Neptune
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
import UserKit
import WiseCore

@Mock
protocol CreateRefundDelegate: AnyObject {
    func refundInitiated(_ refund: Refund)
    func topUp(balanceId: BalanceId, completion: @escaping () -> Void)
}

struct CreateRefundContent: Equatable, With {
    var moneyInputInformation: MarkupTextModel?
    var moneyInputSentiment: Sentiment
    var refundCurrency: MoneyInput.Currency
    var buttonEnabled: Bool

    static func == (lhs: CreateRefundContent, rhs: CreateRefundContent) -> Bool {
        guard lhs.moneyInputInformation?.text == rhs.moneyInputInformation?.text else { return false }
        guard lhs.moneyInputSentiment == rhs.moneyInputSentiment else { return false }
        guard lhs.refundCurrency == rhs.refundCurrency else { return false }
        guard lhs.buttonEnabled == rhs.buttonEnabled else { return false }
        return true
    }
}

@MainActor
final class CreateRefundViewModel: ModelStateViewModel<CreateRefundContent, Void, Error> {
    private let paymentId: String
    private let profileId: ProfileId
    private let useCase: AcquiringPaymentUseCase
    private let balancesUseCase: BalancesUseCase
    private weak var delegate: CreateRefundDelegate?

    private var refundAmount: Decimal? {
        MoneyFormatter.number(refundAmountValue.raw)?.decimalValue
    }

    private var payment: AcquiringPayment?

    private(set) var refreshBalancesTask: Task<Void, Never>?

    @Published
    private var refundAmountValue = MoneyInputValue(raw: "")

    @Published
    var refundReason = ""

    init(
        paymentId: String,
        profileId: ProfileId,
        useCase: AcquiringPaymentUseCase = AcquiringPaymentUseCaseFactory.make(),
        balancesUseCase: BalancesUseCase = BalancesUseCaseFactory.make(),
        delegate: CreateRefundDelegate?
    ) {
        self.paymentId = paymentId
        self.profileId = profileId
        self.delegate = delegate
        self.balancesUseCase = balancesUseCase
        self.useCase = useCase
    }

    func moneyInputValue() -> Binding<MoneyInputValue> {
        .init {
            self.refundAmountValue
        } set: { newValue in
            self.refundAmountValue.raw = newValue.raw
            self.validate(input: newValue.raw)
        }
    }

    func fetchData() async {
        await loading { [weak self] in
            guard let self else { return .initial }
            let balances = try await balancesUseCase.listenToBalancesAsyncStream(
                for: profileId,
                strategy: .expirableCacheAfter(0)
            ).first()

            async let payment = try await useCase.payment(with: paymentId, profileId: profileId)

            self.payment = try await payment
            let balanceId = try await payment.balanceId
            let balance = balances?.first(where: { $0.id == balanceId })

            let canBalancesRefund = try await canBalancesRefund(balance, payment: payment)

            let content = try await makeContent(canBalancesRefund: canBalancesRefund, payment: payment)
            refundAmountValue.raw = try await MoneyFormatter.format(payment.refundableAmount.value as NSNumber)

            return .content(content, error: nil)
        }
    }

    func continueTapped() {
        guard let refundAmount, let payment else {
            return
        }

        let inProgressRefund = Refund(
            amount: .init(currency: payment.refundableAmount.currency, value: refundAmount),
            reason: refundReason.isEmpty ? nil : refundReason,
            payerData: .init(name: payment.payerData?.name, email: payment.payerData?.email)
        )

        delegate?.refundInitiated(inProgressRefund)
    }

    private func canBalancesRefund(_ balance: Balance?, payment: AcquiringPayment) -> Bool {
        guard let balance else { return false }
        return balance.availableAmount >= payment.refundableAmount.value
    }

    private func recheckBalances() async {
        guard let payment, let currentContent = state.content else { return }

        await loading { [weak self] in
            guard let self else { return .content(currentContent, error: nil) }
            async let balances = try await balancesUseCase.listenToBalancesAsyncStream(
                for: profileId,
                strategy: .expirableCacheAfter(0)
            ).first()

            let balanceId = payment.balanceId
            let balance = try await balances?.first(where: { $0.id == balanceId })
            let canBalancesRefund = canBalancesRefund(balance, payment: payment)

            let content = makeContent(canBalancesRefund: canBalancesRefund, payment: payment)
            return .content(content, error: nil)
        }
    }
}

private extension CreateRefundViewModel {
    func validate(input: String) {
        guard let payment, let currentContent = state.content else { return }

        guard let asDecimal = MoneyFormatter.number(input)?.decimalValue else {
            state.content = currentContent.with {
                $0.buttonEnabled = false
                $0.moneyInputInformation = defaultMoneyInputInformation(payment: payment)
            }
            return
        }

        guard payment.refundableAmount.value >= asDecimal else {
            state.content = currentContent.with {
                $0.buttonEnabled = false
                $0.moneyInputSentiment = .negative
                $0.moneyInputInformation = L10n.PaymentRequest.Refund.Create.tooLargeAmount(MoneyFormatter.format(payment.refundableAmount)
                )
            }
            return
        }

        state.content = currentContent.with {
            $0.buttonEnabled = true
            $0.moneyInputSentiment = .none
            $0.moneyInputInformation = defaultMoneyInputInformation(payment: payment)
        }
    }

    private func makeContent(canBalancesRefund: Bool, payment: AcquiringPayment) -> CreateRefundContent {
        let refundCurrency = MoneyInput.Currency(
            code: payment.refundableAmount.currency.value,
            name: payment.refundableAmount.currency.localizedCurrencyName,
            supportsDecimals: true
        )

        let moneyInputInformation: MarkupLabelModel

        if canBalancesRefund {
            moneyInputInformation = defaultMoneyInputInformation(payment: payment)
        } else {
            let label = L10n.PaymentRequest.Refund.Create.needToTopUp + " " + L10n.PaymentRequest.Refund.Create.addMoney(payment.refundableAmount.currency.value).markup(tag: .link)
            moneyInputInformation = MarkupLabelModel(text: label, action: MarkupTapAction(handler: { [weak self] in
                guard let self else { return }
                delegate?.topUp(balanceId: payment.balanceId) { [weak self] in
                    guard let self else { return }
                    refreshBalancesTask = Task {
                        await self.recheckBalances()
                    }
                }
            }))
        }

        return CreateRefundContent(
            moneyInputInformation: moneyInputInformation,
            moneyInputSentiment: canBalancesRefund ? .none : .negative,
            refundCurrency: refundCurrency,
            buttonEnabled: canBalancesRefund
        )
    }

    func defaultMoneyInputInformation(payment: AcquiringPayment) -> MarkupLabelModel {
        let formattedAmount = MoneyFormatter.format(payment.refundableAmount).markup(tag: .link)
        let labelModel = L10n.PaymentRequest.Refund.Create.Amount.info(formattedAmount)

        return MarkupLabelModel(text: labelModel, action: MarkupTapAction(handler: { [weak self] in
            let formattedNumber = MoneyFormatter.format(payment.refundableAmount.value as NSNumber)
            self?.refundAmountValue.raw = formattedNumber
        }))
    }
}
