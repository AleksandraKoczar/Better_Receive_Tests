import Neptune

// sourcery: AutoEquatableForTest
struct CreatePaymentRequestViewModel {
    let titleViewModel: LargeTitleViewModel
    let moneyInputViewModel: MoneyInputViewModel
    let currencySelectorEnabled: Bool
    let shouldShowPaymentLimitsCheckbox: Bool
    let isLimitPaymentsSelected: Bool
    let productDescription: String?
    let paymentMethodsOption: PaymentMethodsOption
    let nudge: NudgeViewModel?
    let footerButtonEnabled: Bool
    let footerButtonTitle: String

    // sourcery: AutoEquatableForTest
    struct PaymentMethodsOption {
        let viewModel: OptionViewModel
        // sourcery: skipEquality
        let onTap: () -> Void
    }
}
