import Foundation
import ReceiveKit
import TransferResources
import TWUI

// sourcery: AutoEquatableForTest
struct CreatePaymentRequestFromContactSuccessViewModel {
    let asset: PromptAsset
    let title: String
    let message: String
    let buttonConfiguration: PromptConfiguration.SecondaryButtonConfiguration
}

// MARK: - View model factory

extension CreatePaymentRequestFromContactSuccessViewModel {
    static func make(
        contact: RequestMoneyContact,
        paymentRequest: PaymentRequestV2,
        primaryButtonAction: @escaping (UIViewController?) -> Void,
        secondaryButtonAction: @escaping (UIViewController?) -> Void
    ) -> CreatePaymentRequestFromContactSuccessViewModel {
        CreatePaymentRequestFromContactSuccessViewModel(
            asset: PromptAsset.scene3D(.confetti),
            title: L10n.PaymentRequest.WithContact.Success.title,
            message: L10n.PaymentRequest.WithContact.Success.message(contact.title),
            buttonConfiguration: PromptConfiguration.SecondaryButtonConfiguration(
                title: L10n.PaymentRequest.WithContact.Success.PrimaryAction.title,
                actionHandler: primaryButtonAction
            )
        )
    }
}
