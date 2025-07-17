import ReceiveKit
@testable import ReceiveUIKit
import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import WiseCore

final class PaymentLinkPaymentDetailsRouterTests: TWTestCase {
    private let paymentRequestId = PaymentRequestId("fake-payment-request-id")
    private let profileId = ProfileId(12345678)

    private var router: PaymentLinkPaymentDetailsRouterImpl!
    private var navigationController: MockNavigationController!
    private var paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegateMock!
    private var paymentDetailsViewControllerFactory: PaymentDetailsViewControllerFactoryMock.Type!

    override func setUp() {
        super.setUp()
        navigationController = MockNavigationController()
        paymentDetailsRefundFlowDelegate = PaymentDetailsRefundFlowDelegateMock()
        paymentDetailsViewControllerFactory = PaymentDetailsViewControllerFactoryMock.self
        router = PaymentLinkPaymentDetailsRouterImpl(
            paymentRequestId: paymentRequestId,
            profileId: profileId,
            paymentDetailsRefundFlowDelegate: paymentDetailsRefundFlowDelegate,
            navigationController: navigationController,
            webViewControllerFactory: WebViewControllerFactoryMock.self,
            paymentDetailsViewControllerFactory: paymentDetailsViewControllerFactory
        )
    }

    override func tearDown() {
        router = nil
        navigationController = nil
        paymentDetailsRefundFlowDelegate = nil
        paymentDetailsViewControllerFactory = nil
        super.tearDown()
    }

    func test_showAcquiringTransactionPaymentDetails() throws {
        let viewController = ViewControllerMock()
        paymentDetailsViewControllerFactory.makeWithTransactionIdReturnValue = viewController

        let transactionId = AcquiringTransactionId(LoremIpsum.short)
        router.showAcquiringTransactionPaymentDetails(transactionId: transactionId)

        XCTAssertTrue(paymentDetailsViewControllerFactory.makeWithTransactionIdCalled)
        let arguments = try XCTUnwrap(paymentDetailsViewControllerFactory.makeWithTransactionIdReceivedArguments)
        XCTAssertEqual(arguments.paymentRequestId, paymentRequestId)
        XCTAssertEqual(arguments.profileId, profileId)
        XCTAssertEqual(arguments.transactionId, transactionId)
        XCTAssertTrue(navigationController.lastPushedViewController === viewController)
    }

    func test_showTransferPaymentDetails() throws {
        let viewController = ViewControllerMock()
        paymentDetailsViewControllerFactory.makeWithTransferIdReturnValue = viewController

        let transferId = ReceiveTransferId(LoremIpsum.short)
        router.showTransferPaymentDetails(transferId: transferId)

        XCTAssertTrue(paymentDetailsViewControllerFactory.makeWithTransferIdCalled)
        let arguments = try XCTUnwrap(paymentDetailsViewControllerFactory.makeWithTransferIdReceivedArguments)
        XCTAssertEqual(arguments.paymentRequestId, paymentRequestId)
        XCTAssertEqual(arguments.profileId, profileId)
        XCTAssertEqual(arguments.transferId, transferId)
        XCTAssertTrue(navigationController.lastPushedViewController === viewController)
    }
}
