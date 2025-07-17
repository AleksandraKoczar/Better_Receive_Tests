import Foundation
import ReceiveKit
import TransferResources

enum CreatePaymentRequestBodyBuilderError: Error, Equatable {
    case invalidAmount(reason: String)
}

enum CreatePaymentRequestBodyBuilder {
    static func make(
        requestType: RequestType,
        paymentRequestInfo: CreatePaymentRequestPresenterInfo
    ) throws -> PaymentRequestBodyV2 {
        let value = try parseAmount(paymentRequestInfo.value)

        if requestType == .singleUse {
            let body = PaymentRequestSingleUseBody(
                balanceId: paymentRequestInfo.selectedBalanceId.value,
                selectedPaymentMethods: parsePaymentMethods(methods: paymentRequestInfo.paymentMethods),
                amountValue: value,
                description: paymentRequestInfo.productDescription,
                message: nil,
                payer: nil
            )
            return PaymentRequestBodyV2.singleUse(body)
        } else {
            let body = PaymentRequestReusableBody(
                balanceId: paymentRequestInfo.selectedBalanceId.value,
                selectedPaymentMethods: parsePaymentMethods(methods: paymentRequestInfo.paymentMethods),
                amountValue: value,
                description: paymentRequestInfo.productDescription
            )
            return PaymentRequestBodyV2.reusable(body)
        }
    }

    // MARK: - Helpers

    private static func parsePaymentMethods(methods: [AcquiringPaymentMethodType]) -> [PaymentMethodTypeV2] {
        methods.compactMap { method in
            switch method {
            case .applePay:
                .applePay
            case .bankTransfer:
                .bankTransfer
            case .card:
                .card
            case .payWithWise:
                .payWithWise
            case .payNow:
                .payNow
            case .pisp:
                .pisp
            }
        }
    }

    private static func parseAmount(_ amount: Decimal?) throws -> Decimal {
        guard let amount else {
            throw CreatePaymentRequestBodyBuilderError.invalidAmount(reason: L10n.PaymentRequest.Create.MoneyInput.Error.empty)
        }
        guard amount > 0 else {
            throw CreatePaymentRequestBodyBuilderError.invalidAmount(reason: L10n.PaymentRequest.Create.MoneyInput.Error.lessThanZero)
        }
        return amount
    }
}
