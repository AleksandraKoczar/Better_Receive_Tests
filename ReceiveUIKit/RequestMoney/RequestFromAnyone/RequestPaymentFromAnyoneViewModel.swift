import Neptune

// sourcery: AutoEquatableForTest
struct RequestPaymentFromAnyoneViewModel {
    let titleViewModel: LargeTitleViewModel
    let qrCodeViewModel: WisetagQRCodeViewModel
    let doneAction: SmallButtonView
    let primaryActionFooter: Action
    let secondaryActionFooter: Action
}
