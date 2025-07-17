import Combine
import ReceiveKit
import WiseCore

final class AcquiringTransactionPaymentDetailsInteractor {
    private let useCase: PaymentRequestDetailsUseCase
    private let transactionId: AcquiringTransactionId

    init(
        transactionId: AcquiringTransactionId,
        useCase: PaymentRequestDetailsUseCase = PaymentRequestDetailsUseCaseFactory.make()
    ) {
        self.transactionId = transactionId
        self.useCase = useCase
    }
}

// MARK: - PaymentDetailsInteractor

extension AcquiringTransactionPaymentDetailsInteractor: PaymentDetailsInteractor {
    func paymentDetails(profileId: ProfileId) -> AnyPublisher<PaymentDetails, Error> {
        useCase.paymentDetails(
            profileId: profileId,
            transactionId: transactionId
        )
    }
}
