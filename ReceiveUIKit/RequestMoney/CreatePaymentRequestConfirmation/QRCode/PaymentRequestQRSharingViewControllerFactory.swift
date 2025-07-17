import ReceiveKit
import TWFoundation
import UIKit
import UserKit

enum PaymentRequestQRSharingViewControllerFactory {
    static func make(profile: Profile, paymentRequest: PaymentRequestV2) -> UIViewController {
        let presenter = PaymentRequestQRSharingPresenterImpl(
            profile: profile,
            paymentRequest: paymentRequest
        )
        let autoBrightnessAdjuster = AutoBrightnessAdjusterFactory.make()
        return PaymentRequestQRSharingViewController(
            presenter: presenter,
            autoBrightnessAdjuster: autoBrightnessAdjuster
        )
    }
}
