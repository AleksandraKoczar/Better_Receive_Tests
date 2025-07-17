import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import WiseCore

final class PaymentLinkPaymentDetailsPresenterTests: TWTestCase {
    private let paymentRequestId = PaymentRequestId("fake-payment-request-id")
    private let acquiringPaymentId = AcquiringPaymentId("fake-acquiring-payment-id")
    private let profileId = ProfileId(12345678)

    private var presenter: PaymentLinkPaymentDetailsPresenterImpl!
    private var view: PaymentLinkPaymentDetailsViewMock!
    private var paymentLinkPaymentDetailsUseCase: PaymentLinkPaymentDetailsUseCaseMock!
    private var router: PaymentLinkPaymentDetailsRouterMock!
    private var viewModelFactory: PaymentLinkPaymentDetailsViewModelFactoryMock!

    override func setUp() {
        super.setUp()
        view = PaymentLinkPaymentDetailsViewMock()
        paymentLinkPaymentDetailsUseCase = PaymentLinkPaymentDetailsUseCaseMock()
        router = PaymentLinkPaymentDetailsRouterMock()
        viewModelFactory = PaymentLinkPaymentDetailsViewModelFactoryMock()
        presenter = PaymentLinkPaymentDetailsPresenterImpl(
            paymentRequestId: paymentRequestId,
            acquiringPaymentId: acquiringPaymentId,
            profileId: profileId,
            router: router,
            paymentLinkPaymentDetailsUseCase: paymentLinkPaymentDetailsUseCase,
            viewModelFactory: viewModelFactory,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        presenter = nil
        view = nil
        paymentLinkPaymentDetailsUseCase = nil
        router = nil
        viewModelFactory = nil
        super.tearDown()
    }

    func test_start_givenFetchPaymentDetailsSuccess_thenConfigureView() throws {
        paymentLinkPaymentDetailsUseCase.paymentDetailsReturnValue = .just(.canned)
        let viewModel = makeViewModel()
        viewModelFactory.makeReturnValue = viewModel

        presenter.start(with: view)

        XCTAssertEqual(paymentLinkPaymentDetailsUseCase.paymentDetailsCallsCount, 1)
        let arguments = try XCTUnwrap(paymentLinkPaymentDetailsUseCase.paymentDetailsReceivedArguments)
        XCTAssertEqual(arguments.profileId, profileId)
        XCTAssertEqual(arguments.paymentRequestId, paymentRequestId)
        XCTAssertEqual(arguments.acquiringPaymentId, acquiringPaymentId)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        expectNoDifference(view.configureReceivedViewModel, viewModel)
    }

    func test_start_givenFatchePaymentDetailsFailure_thenShowError() throws {
        paymentLinkPaymentDetailsUseCase.paymentDetailsReturnValue = .fail(with: MockError.dummy)

        presenter.start(with: view)

        XCTAssertEqual(paymentLinkPaymentDetailsUseCase.paymentDetailsCallsCount, 1)
        let arguments = try XCTUnwrap(paymentLinkPaymentDetailsUseCase.paymentDetailsReceivedArguments)
        XCTAssertEqual(arguments.profileId, profileId)
        XCTAssertEqual(arguments.paymentRequestId, paymentRequestId)
        XCTAssertEqual(arguments.acquiringPaymentId, acquiringPaymentId)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
    }

    func test_optionItemTapped_givenAcquiringTransactionResourceType_thenShowAcquiringTransactionPaymentDetails() {
        let transactionId = AcquiringTransactionId(LoremIpsum.short)
        presenter.optionItemTapped(
            action: .navigateToAcquiringTransaction(transactionId)
        )

        XCTAssertEqual(router.showAcquiringTransactionPaymentDetailsCallsCount, 1)
        XCTAssertEqual(
            router.showAcquiringTransactionPaymentDetailsReceivedTransactionId,
            transactionId
        )
    }

    func test_optionItemTapped_givenTransferResourceType_thenShowTransferPaymentDetails() {
        let transferId = ReceiveTransferId(LoremIpsum.short)
        presenter.optionItemTapped(
            action: .navigateToTransfer(transferId)
        )

        XCTAssertEqual(router.showTransferPaymentDetailsCallsCount, 1)
        XCTAssertEqual(router.showTransferPaymentDetailsReceivedTransferId, transferId)
    }
}

// MARK: - PaymentLinkPaymentDetailsPresenterTests

private extension PaymentLinkPaymentDetailsPresenterTests {
    func makeViewModel() -> PaymentLinkPaymentDetailsViewModel {
        PaymentLinkPaymentDetailsViewModel(
            title: LargeTitleViewModel(
                title: LoremIpsum.veryShort,
                description: LoremIpsum.short
            ),
            sections: []
        )
    }
}
