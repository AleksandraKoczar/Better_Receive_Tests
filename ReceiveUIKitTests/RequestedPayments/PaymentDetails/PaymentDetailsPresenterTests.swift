import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import WiseCore

final class PaymentDetailsPresenterTests: TWTestCase {
    private var presenter: PaymentDetailsPresenterImpl!
    private var view: PaymentDetailsViewMock!
    private var interactor: PaymentDetailsInteractorMock!
    private var router: PaymentDetailsRouterMock!
    private var featureService: StubFeatureService!

    private let paymentId = "some-payment-id"
    private let illustrationUrn = "urn:wise:illustrations:construction-fence"

    override func setUp() {
        super.setUp()
        view = PaymentDetailsViewMock()
        interactor = PaymentDetailsInteractorMock()
        router = PaymentDetailsRouterMock()
        featureService = StubFeatureService()
        presenter = PaymentDetailsPresenterImpl(
            profileId: ProfileId(12345678),
            router: router,
            interactor: interactor,
            featureService: featureService,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        presenter = nil
        featureService = nil
        router = nil
        interactor = nil
        view = nil
        super.tearDown()
    }

    func test_start_givenFetchPaymentDetailsSucceeds_thenConfigureView() throws {
        let paymentDetails = makePaymentDetails()
        interactor.paymentDetailsReturnValue = .just(paymentDetails)

        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        let expected = makeExpectedViewModel()
        expectNoDifference(viewModel, expected)
        XCTAssertEqual(view.configureCallsCount, 1)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(interactor.paymentDetailsCallsCount, 1)
    }

    func test_start_givenFetchPaymentDetailsFails_thenShowError() throws {
        interactor.paymentDetailsReturnValue = .fail(with: MockError.dummy)

        presenter.start(with: view)

        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(interactor.paymentDetailsCallsCount, 1)
    }

    func test_isRefundEnabled_givenRefundIsEnabled_thenReturnTrue() {
        featureService.stub(value: true, for: ReceiveKitFeatures.acquiringTransactionRefundEnabledV2)

        let result = presenter.isRefundEnabled()

        XCTAssertTrue(result)
    }

    func test_isRefundEnabled_givenRefundIsDisabled_thenReturnFalse() {
        featureService.stub(value: false, for: ReceiveKitFeatures.acquiringTransactionRefundEnabledV2)

        let result = presenter.isRefundEnabled()

        XCTAssertFalse(result)
    }

    func test_proceedRefund() {
        presenter.proceedRefund(paymentId: paymentId)

        XCTAssertEqual(router.showRefundFlowReceivedArguments?.paymentId, paymentId)
        XCTAssertEqual(router.showRefundFlowCallsCount, 1)
    }

    func test_showRefundDisabled() {
        presenter.showRefundDisabled(
            title: LoremIpsum.short,
            message: LoremIpsum.medium,
            illustrationUrn: illustrationUrn
        )

        XCTAssertEqual(router.showRefundDisabledBottomSheetReceivedArguments?.title, LoremIpsum.short)
        XCTAssertEqual(router.showRefundDisabledBottomSheetReceivedArguments?.message, LoremIpsum.medium)
        XCTAssertEqual(router.showRefundDisabledBottomSheetReceivedArguments?.illustrationUrn, illustrationUrn)
        XCTAssertEqual(router.showRefundDisabledBottomSheetCallsCount, 1)
    }

    // MARK: - Helpers

    private func makePaymentDetails() -> PaymentDetails {
        PaymentDetails.build(
            title: LoremIpsum.short
        )
    }

    private func makeExpectedViewModel() -> PaymentDetailsViewModel {
        PaymentDetailsViewModel(
            title: LoremIpsum.short,
            alert: nil,
            items: [],
            footerAction: nil
        )
    }
}
