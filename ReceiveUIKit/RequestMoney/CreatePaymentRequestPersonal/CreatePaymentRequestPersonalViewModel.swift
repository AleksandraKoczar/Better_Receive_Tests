import Neptune

// sourcery: AutoEquatableForTest
struct CreatePaymentRequestPersonalViewModel {
    let titleViewModel: LargeTitleViewModel
    let moneyInputViewModel: MoneyInputViewModel
    let currencySelectorEnabled: Bool
    let message: String?
    let alert: Alert?
    let nudge: CreatePaymentRequestPersonalViewModel.Nudge?
    let footerButtonEnabled: Bool
    let footerButtonTitle: String
}

extension CreatePaymentRequestPersonalViewModel {
    // sourcery: AutoEquatableForTest
    struct Nudge {
        let title: String
        let icon: NudgeViewModel.Asset
        let ctaTitle: String
    }

    // sourcery: AutoEquatableForTest
    struct Alert {
        let style: InlineAlertStyle
        let viewModel: InlineAlertViewModel
    }
}
