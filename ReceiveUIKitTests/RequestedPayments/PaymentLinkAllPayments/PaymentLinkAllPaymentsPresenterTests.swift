import AnalyticsKitTestingSupport
import ContactsKitTestingSupport
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TransferResources
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

final class PaymentLinkAllPaymentsPresenterTests: TWTestCase {
    private let paymentRequestId = PaymentRequestId("ABC")
    private let acquiringPaymentId = AcquiringPaymentId("some-acquiring-payment-id")
    private let transactionId = AcquiringTransactionId("some-transaction-id")
    private let transferId = ReceiveTransferId("some-transfer-id")
    private let seekPosition = "2023-08-03T12:26:48.395873Z"

    private var presenter: PaymentLinkAllPaymentsPresenterImpl!
    private var router: PaymentLinkAllPaymentsRouterMock!
    private var view: PaymentLinkAllPaymentsViewMock!
    private var paymentLinkAllPaymentsUseCase: PaymentLinkAllPaymentsListUseCaseMock!

    override func setUp() {
        super.setUp()
        view = PaymentLinkAllPaymentsViewMock()
        paymentLinkAllPaymentsUseCase = PaymentLinkAllPaymentsListUseCaseMock()
        router = PaymentLinkAllPaymentsRouterMock()
        presenter = PaymentLinkAllPaymentsPresenterImpl(
            router: router,
            paymentRequestId: paymentRequestId,
            paymentLinkAllPaymentsUseCase: paymentLinkAllPaymentsUseCase,
            profile: FakeBusinessProfileInfo().asProfile(),
            scheduler: .immediate
        )
    }

    override func tearDown() {
        presenter = nil
        view = nil
        paymentLinkAllPaymentsUseCase = nil
        router = nil
        super.tearDown()
    }

    func test_start_givenLoadAllPaymentsSuccess_thenConfigureView() throws {
        let allPayments = makeAllPayments()
        paymentLinkAllPaymentsUseCase.getAllPaymentsForPaymentLinkReturnValue = .just(allPayments)
        presenter.start(with: view)

        let expectedViewModel = makeViewModel()
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)

        expectNoDifference(viewModel, expectedViewModel)
        XCTAssertEqual(view.configureCallsCount, 1)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(paymentLinkAllPaymentsUseCase.getAllPaymentsForPaymentLinkCallsCount, 1)
    }

    func test_start_givenLoadAllPaymentsFailure_thenShowError() throws {
        paymentLinkAllPaymentsUseCase.getAllPaymentsForPaymentLinkReturnValue = .fail(with: MockError.dummy)

        presenter.start(with: view)

        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(paymentLinkAllPaymentsUseCase.getAllPaymentsForPaymentLinkCallsCount, 1)
    }

    func test_prefetch() throws {
        paymentLinkAllPaymentsUseCase.getAllPaymentsForPaymentLinkReturnValue = .just(makeAllPayments())

        presenter.start(with: view)
        presenter.prefetch(id: "22")

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.showNewSectionsCallsCount, 1)
        XCTAssertEqual(paymentLinkAllPaymentsUseCase.getAllPaymentsForPaymentLinkCallsCount, 2)
        let arguments = try XCTUnwrap(paymentLinkAllPaymentsUseCase.getAllPaymentsForPaymentLinkReceivedArguments)
        XCTAssertEqual(arguments.cursor, seekPosition)
    }

    func test_paymentDetailsTapped_givenNavigateToAcquiringPayment_thenShowPaymentLinkPaymentDetails() {
        presenter.rowTapped(
            action: .navigateToAcquiringPayment(acquiringPaymentId)
        )

        XCTAssertEqual(router.showPaymentLinkPaymentDetailsReceivedAcquiringPaymentId, acquiringPaymentId)
        XCTAssertEqual(router.showPaymentLinkPaymentDetailsCallsCount, 1)
    }

    func test_paymentDetailsTapped_givenNavigateToAcquiringTransaction_thenShowAcquiringTransactionPaymentDetails() {
        presenter.rowTapped(
            action: .navigateToAcquiringTransaction(transactionId)
        )

        XCTAssertEqual(router.showAcquiringTransactionPaymentDetailsReceivedTransactionId, transactionId)
        XCTAssertEqual(router.showAcquiringTransactionPaymentDetailsCallsCount, 1)
    }

    func test_paymentDetailsTapped_givenNavigateToTransfer_thenShowTransferPaymentDetails() {
        presenter.rowTapped(
            action: .navigateToTransfer(transferId)
        )

        XCTAssertEqual(router.showTransferPaymentDetailsReceivedTransferId, transferId)
        XCTAssertEqual(router.showTransferPaymentDetailsCallsCount, 1)
    }
}

private extension PaymentLinkAllPaymentsPresenterTests {
    func makeViewModel() -> PaymentLinkAllPaymentsViewModel {
        PaymentLinkAllPaymentsViewModel(
            title: LargeTitleViewModel(
                title: "All payments"
            ),
            content: .sections(
                [
                    PaymentLinkAllPaymentsViewModel.Section(
                        id: "1",
                        title: LoremIpsum.veryShort,
                        viewModel: SectionHeaderViewModel(title: LoremIpsum.veryShort),
                        items: [
                            PaymentLinkAllPaymentsViewModel.Section.OptionItem(
                                id: "11",
                                option: OptionViewModel(
                                    title: LoremIpsum.veryShort,
                                    subtitle: LoremIpsum.veryShort,
                                    avatar: .icon(Icons.requestSend.image)
                                ),
                                actionType: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort))
                            ),
                            PaymentLinkAllPaymentsViewModel.Section.OptionItem(
                                id: "12",
                                option: OptionViewModel(
                                    title: LoremIpsum.veryShort,
                                    subtitle: LoremIpsum.veryShort,
                                    avatar: .icon(Icons.requestSend.image)
                                ),
                                actionType: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort))
                            ),
                        ]
                    ),
                    PaymentLinkAllPaymentsViewModel.Section(
                        id: "2",
                        title: LoremIpsum.veryShort,
                        viewModel: SectionHeaderViewModel(title: LoremIpsum.veryShort),
                        items: [
                            PaymentLinkAllPaymentsViewModel.Section.OptionItem(
                                id: "21",
                                option: OptionViewModel(
                                    title: LoremIpsum.veryShort,
                                    subtitle: LoremIpsum.veryShort,
                                    avatar: .icon(Icons.requestSend.image)
                                ),
                                actionType: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort))
                            ),
                            PaymentLinkAllPaymentsViewModel.Section.OptionItem(
                                id: "22",
                                option: OptionViewModel(
                                    title: LoremIpsum.veryShort,
                                    subtitle: LoremIpsum.veryShort,
                                    avatar: .icon(Icons.requestSend.image)
                                ),
                                actionType: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort))
                            ),
                        ]
                    ),
                ]
            )
        )
    }

    func makeAllPayments() -> PaymentLinkAllPayments {
        PaymentLinkAllPayments.build(
            groups: makeGroups(),
            nextPageState: .hasNextPage(seekPosition: seekPosition)
        )
    }

    func makeGroups() -> [PaymentLinkAllPayments.Group] {
        [
            PaymentLinkAllPayments.Group.build(
                groupLabel: LoremIpsum.veryShort,
                groupId: "1",
                content: makeContent1()
            ),
            PaymentLinkAllPayments.Group.build(
                groupLabel: LoremIpsum.veryShort,
                groupId: "2",
                content: makeContent2()
            ),
        ]
    }

    func makeContent1() -> [PaymentLinkAllPayments.Group.Content] {
        [
            PaymentLinkAllPayments.Group.Content.build(
                id: "11",
                title: LoremIpsum.veryShort,
                subtitle: LoremIpsum.veryShort,
                action: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort)),
                icon: "urn:wise:icons:request-send"
            ),
            PaymentLinkAllPayments.Group.Content.build(
                id: "12",
                title: LoremIpsum.veryShort,
                subtitle: LoremIpsum.veryShort,
                action: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort)),
                icon: "urn:wise:icons:request-send"
            ),
        ]
    }

    func makeContent2() -> [PaymentLinkAllPayments.Group.Content] {
        [
            PaymentLinkAllPayments.Group.Content.build(
                id: "21",
                title: LoremIpsum.veryShort,
                subtitle: LoremIpsum.veryShort,
                action: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort)),
                icon: "urn:wise:icons:request-send"
            ),
            PaymentLinkAllPayments.Group.Content.build(
                id: "22",
                title: LoremIpsum.veryShort,
                subtitle: LoremIpsum.veryShort,
                action: .navigateToAcquiringPayment(AcquiringPaymentId.build(value: LoremIpsum.veryShort)),
                icon: "urn:wise:icons:request-send"
            ),
        ]
    }
}
