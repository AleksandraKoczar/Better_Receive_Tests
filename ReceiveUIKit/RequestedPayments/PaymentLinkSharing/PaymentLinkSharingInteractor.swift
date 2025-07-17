import Combine
import MacrosKit
import ReceiveKit
import TWFoundation
import WiseCore

// sourcery: AutoMockable
protocol PaymentLinkSharingInteractor: AnyObject {
    func fetchDetails() -> AnyPublisher<PaymentLinkSharingDetailsModelState, Never>
}

@Init
final class PaymentLinkSharingInteractorImpl: PaymentLinkSharingInteractor {
    private let paymentRequestId: PaymentRequestId
    private let profileId: ProfileId

    @Init(default: PaymentRequestUseCaseFactoryV2.make())
    private let paymentRequestUseCase: PaymentRequestUseCaseV2

    @Init(default: WisetagUseCaseFactory.make())
    private let wisetagUseCase: WisetagUseCase

    func fetchDetails() -> AnyPublisher<PaymentLinkSharingDetailsModelState, Never> {
        paymentRequestUseCase.paymentRequest(
            profileId: profileId,
            paymentRequestId: paymentRequestId
        ).flatMap { [wisetagUseCase] paymentRequest in
            wisetagUseCase.qrCode(content: paymentRequest.link)
                .map { qrCodeImage in
                    PaymentLinkSharingDetails(
                        paymentRequest: paymentRequest,
                        qrCodeImage: qrCodeImage
                    )
                }
                .replaceError(
                    with: PaymentLinkSharingDetails(
                        paymentRequest: paymentRequest,
                        qrCodeImage: nil
                    )
                )
        }
        .asResult()
        .map {
            switch $0 {
            case let .success(content):
                .content(content)
            case let .failure(error):
                .error(error)
            }
        }
        .prepend(.loading(nil))
        .eraseToAnyPublisher()
    }
}
