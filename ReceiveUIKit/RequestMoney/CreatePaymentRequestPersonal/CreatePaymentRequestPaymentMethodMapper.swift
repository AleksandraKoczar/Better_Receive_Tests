import ReceiveKit

enum CreatePaymentRequestPaymentMethodMapper {
    static func mapPaymentMethod(types: [AcquiringPaymentMethodType]) -> [PaymentMethodTypeV2] {
        types.map { method in
            switch method {
            case .applePay:
                PaymentMethodTypeV2.applePay
            case .bankTransfer:
                PaymentMethodTypeV2.bankTransfer
            case .card:
                PaymentMethodTypeV2.card
            case .payWithWise:
                PaymentMethodTypeV2.payWithWise
            case .payNow:
                PaymentMethodTypeV2.payNow
            case .pisp:
                PaymentMethodTypeV2.pisp
            }
        }
    }

    static func mapToAcquiringPaymentMethod(types: [PaymentMethodTypeV2]) -> [AcquiringPaymentMethodType] {
        types.map { method in
            switch method {
            case .applePay:
                AcquiringPaymentMethodType.applePay
            case .bankTransfer:
                AcquiringPaymentMethodType.bankTransfer
            case .card:
                AcquiringPaymentMethodType.card
            case .payWithWise:
                AcquiringPaymentMethodType.payWithWise
            case .payNow:
                AcquiringPaymentMethodType.payNow
            case .pisp:
                AcquiringPaymentMethodType.pisp
            }
        }
    }
}
