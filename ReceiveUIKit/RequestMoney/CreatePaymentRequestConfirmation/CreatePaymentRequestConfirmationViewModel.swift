import Neptune
import UIKit

// sourcery: AutoEquatableForTest
struct CreatePaymentRequestConfirmationViewModel {
    let asset: IllustrationView.Asset
    let title: CreatePaymentRequestConfirmationViewModel.LabelViewModel
    let info: CreatePaymentRequestConfirmationViewModel.LabelViewModel
    let privacyNotice: CreatePaymentRequestConfirmationViewModel.LabelViewModel
    let shareButtons: [CreatePaymentRequestConfirmationViewModel.ButtonViewModel]
    let shouldShowExtendedFooter: Bool
}

extension CreatePaymentRequestConfirmationViewModel {
    // sourcery: AutoEquatableForTest
    struct LabelViewModel {
        let text: String?
        let style: LabelStyle
        // sourcery: skipEquality
        let action: (() -> Void)?
    }

    // sourcery: AutoEquatableForTest
    struct ButtonViewModel {
        let icon: UIImage
        let title: String
        // sourcery: skipEquality
        let action: () -> Void
    }
}
