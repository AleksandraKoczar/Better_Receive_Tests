import Combine
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import Testing
import TWFoundationTestingSupport
import TWTestingSupportKit
import WiseCore
import WiseCoreTestingSupport

final class PaymentLinkSharingInteractorTests {
    private let interactor: PaymentLinkSharingInteractorImpl
    private let paymentRequestUseCase: PaymentRequestUseCaseV2Mock
    private let wisetagUseCase: WisetagUseCaseMock

    private let profileId = ProfileId.canned
    private let paymentRequestId = PaymentRequestId.canned
    private let paymentRequest = PaymentRequestV2.build(link: "wise.com")

    private var states: [PaymentLinkSharingDetailsModelState] = []
    private var cancellable: AnyCancellable?

    init() {
        paymentRequestUseCase = .init()
        wisetagUseCase = .init()
        interactor = .init(
            paymentRequestId: paymentRequestId,
            profileId: profileId,
            paymentRequestUseCase: paymentRequestUseCase,
            wisetagUseCase: wisetagUseCase
        )

        paymentRequestUseCase.paymentRequestReturnValue = .just(paymentRequest)
        wisetagUseCase.qrCodeReturnValue = .just(.canned)
    }

    @Test
    func fetchDetails() {
        cancellable = interactor.fetchDetails()
            .sink { [weak self] in self?.states.append($0) }

        #expect(paymentRequestUseCase.paymentRequestCallsCount == 1)
        #expect(paymentRequestUseCase.paymentRequestReceivedArguments?.profileId == profileId)
        #expect(paymentRequestUseCase.paymentRequestReceivedArguments?.paymentRequestId == paymentRequestId)

        #expect(wisetagUseCase.qrCodeCallsCount == 1)
        #expect(wisetagUseCase.qrCodeReceivedContent == paymentRequest.link)

        expectNoDifference(
            states,
            [
                .loading(nil),
                .content(
                    .init(
                        paymentRequest: paymentRequest,
                        qrCodeImage: UIImage.canned
                    )
                ),
            ]
        )
    }

    @Test
    func fetchDetails_givenQrCodeFailsToFetch_sendsLoadedContentWithNoImage() {
        wisetagUseCase.qrCodeReturnValue = .fail(with: MockError.dummy)
        cancellable = interactor.fetchDetails()
            .sink { [weak self] in self?.states.append($0) }

        expectNoDifference(
            states,
            [
                .loading(nil),
                .content(
                    .init(
                        paymentRequest: paymentRequest,
                        qrCodeImage: nil
                    )
                ),
            ]
        )
    }

    @Test
    func fetchDetails_givenBothAPIsFail_sendsError() throws {
        let paymentRequestError = PaymentRequestUseCaseError.other(error: MockError.dummy)
        paymentRequestUseCase.paymentRequestReturnValue = .fail(with: paymentRequestError)
        wisetagUseCase.qrCodeReturnValue = .fail(with: MockError.dummy)

        cancellable = interactor.fetchDetails()
            .sink { [weak self] in self?.states.append($0) }
        let error = try #require(states.last?.error)
        #expect(error is PaymentRequestUseCaseError)
    }
}
