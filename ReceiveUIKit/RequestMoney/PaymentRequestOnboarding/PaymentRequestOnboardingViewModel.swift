import TWUI

// sourcery: AutoEquatableForTest
struct PaymentRequestOnboardingViewModel {
    let titleText: String
    let subtitleText: String
    let image: UIImage
    let summaryViewModels: [PaymentRequestOnboardingViewModel.SummaryViewModel]
    let footerButtonAction: Action
}

extension PaymentRequestOnboardingViewModel {
    // sourcery: AutoEquatableForTest
    struct SummaryViewModel {
        let title: String
        let description: String
        let icon: UIImage
    }
}
