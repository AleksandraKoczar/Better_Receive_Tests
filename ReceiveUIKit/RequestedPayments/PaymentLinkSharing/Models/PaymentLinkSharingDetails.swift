import ReceiveKit
import TWFoundation
import UIKit

typealias PaymentLinkSharingDetailsModelState = ModelState<PaymentLinkSharingDetails, Error>

// sourcery: AutoEquatableForTest, Buildable
struct PaymentLinkSharingDetails {
    let paymentRequest: PaymentRequestV2
    let qrCodeImage: UIImage?
}
