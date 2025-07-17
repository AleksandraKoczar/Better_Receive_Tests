import Foundation
import ReceiveKit
import TransferResources

enum CreatePaymentRequestPersonalBodyBuilderError: Error, Equatable {
    case invalidAmount(reason: String)
}

enum CreatePaymentRequestPersonalBodyBuilder {
    static func make(
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo
    ) throws -> PaymentRequestSingleUseBody {
        let value = try parseAmount(paymentRequestInfo.value)
        return PaymentRequestSingleUseBody(
            balanceId: paymentRequestInfo.selectedBalanceId.value,
            selectedPaymentMethods: paymentRequestInfo.paymentMethods,
            amountValue: value,
            description: nil,
            message: paymentRequestInfo.message,
            payer: PaymentRequestSingleUseBody.Payer(
                contactId: paymentRequestInfo.contact?.requestCapableContactId,
                name: paymentRequestInfo.contact?.title,
                address: nil
            )
        )
    }

    // MARK: - Helpers

    private static func parseAmount(_ amount: Decimal?) throws -> Decimal {
        guard let amount else {
            throw CreatePaymentRequestPersonalBodyBuilderError.invalidAmount(reason: L10n.PaymentRequest.Create.MoneyInput.Error.empty)
        }
        guard amount > 0 else {
            throw CreatePaymentRequestPersonalBodyBuilderError.invalidAmount(reason:
                L10n.PaymentRequest.Create.MoneyInput.Error.lessThanZero)
        }
        return amount
    }
}
