import Neptune
import ReceiveKit
import UIKit

struct PayWithWisePaymentOption {
    let type: AcquiringPaymentMethodType
    let viewModel: OptionViewModel
}

struct PayWithWisePaymentOptionQuickpay {
    let type: QuickpayAcquiringPayment.PaymentMethodType
    let viewModel: OptionViewModel
}
