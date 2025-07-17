import Combine
import ReceiveKit
import WiseCore

final class TransferPaymentDetailsInteractor {
    private let useCase: PaymentRequestDetailsUseCase
    private let paymentRequestId: PaymentRequestId
    private let transferId: ReceiveTransferId

    init(
        paymentRequestId: PaymentRequestId,
        transferId: ReceiveTransferId,
        useCase: PaymentRequestDetailsUseCase = PaymentRequestDetailsUseCaseFactory.make()
    ) {
        self.paymentRequestId = paymentRequestId
        self.transferId = transferId
        self.useCase = useCase
    }
}

// MARK: - PaymentDetailsInteractor

extension TransferPaymentDetailsInteractor: PaymentDetailsInteractor {
    func paymentDetails(profileId: ProfileId) -> AnyPublisher<PaymentDetails, Error> {
        useCase.paymentDetails(
            profileId: profileId,
            paymentRequestId: paymentRequestId,
            transferId: transferId
        )
    }
}
