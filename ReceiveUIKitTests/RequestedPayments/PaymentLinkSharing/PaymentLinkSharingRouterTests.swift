import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import Testing
import TWUITestingSupport
import UserKit
import UserKitTestingSupport
import WiseCore
import WiseCoreTestingSupport

@MainActor
struct PaymentLinkSharingRouterTests {
    private let router: PaymentLinkSharingRouterImpl
    private let delegate: PaymentLinkSharingDelegateMock
    private let navigationController: MockNavigationController
    private let shareMessageFactory: ShareMessageFactoryMock

    private let profile = Profile.personal(FakePersonalProfileInfo())

    init() {
        delegate = .init()
        navigationController = .init()
        shareMessageFactory = .init()
        router = .init(
            profile: profile,
            paymentRequestDetailsHandler: { _ in },
            navigationController: navigationController,
            shareMessageFactory: shareMessageFactory
        )

        shareMessageFactory.makeReturnValue = ""
    }

    @Test
    func openLinkSharing() {
        let viewController = ViewControllerMock()
        navigationController.setViewControllers([viewController], animated: false)

        router.openLinkSharing(for: .canned)

        #expect(shareMessageFactory.makeCallsCount == 1)
        #expect(shareMessageFactory.makeReceivedArguments?.paymentRequest == PaymentRequestV2.canned)
        #expect(shareMessageFactory.makeReceivedArguments?.profile.id == profile.id)
        #expect(viewController.viewControllerPresented is UIActivityViewController)
    }

    @Test
    func openPaymentRequestDetails() {
        var receivedPaymentRequestId: PaymentRequestId?
        let router = PaymentLinkSharingRouterImpl(
            profile: profile,
            paymentRequestDetailsHandler: { receivedPaymentRequestId = $0 },
            navigationController: navigationController,
            shareMessageFactory: shareMessageFactory
        )
        router.openPaymentRequestDetails(for: .canned)

        #expect(receivedPaymentRequestId == PaymentRequestId.canned)
    }
}
