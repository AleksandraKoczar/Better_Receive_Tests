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

final class PaymentRequestDetailPresenterTests: TWTestCase {
    private let paymentRequestId = PaymentRequestId("ABC")
    private let link = LoremIpsum.medium
    private let file = RequestorAttachmentFileFactory.make(fileId: "XYZ", fileNameWithExtension: "BBC-123.pdf")
    private let acquiringPaymentId = AcquiringPaymentId("some-acquiring-payment-id")
    private let transactionId = AcquiringTransactionId("some-transaction-id")
    private let transferId = ReceiveTransferId("some-transfer-id")
    private let avatarUrlString = "https://wise.com/xyz"

    private var presenter: PaymentRequestDetailPresenterImpl!
    private var paymentRequestUseCase: PaymentRequestUseCaseV2Mock!
    private var router: PaymentRequestDetailRouterMock!
    private var view: PaymentRequestDetailViewMock!
    private var attachmentService: AttachmentFileServiceMock!
    private var paymentRequestDetailsUseCase: PaymentRequestDetailsUseCaseMock!
    private var paymentRequestDetailViewModelFactory: PaymentRequestDetailViewModelFactoryMock!
    private var updateDelegate: PaymentRequestListUpdaterMock!
    private var pasteboard: MockPasteboard!
    private var dateFormatter: WiseDateFormatterProtocolMock!
    private var imageLoader: URIImageLoaderMock!
    private var analyticsTracker: StubAnalyticsTracker!

    override func setUp() {
        super.setUp()
        paymentRequestUseCase = PaymentRequestUseCaseV2Mock()
        attachmentService = AttachmentFileServiceMock()
        paymentRequestDetailsUseCase = PaymentRequestDetailsUseCaseMock()
        paymentRequestDetailViewModelFactory = PaymentRequestDetailViewModelFactoryMock()
        router = PaymentRequestDetailRouterMock()
        view = PaymentRequestDetailViewMock()
        updateDelegate = PaymentRequestListUpdaterMock()
        pasteboard = MockPasteboard()
        imageLoader = URIImageLoaderMock()
        analyticsTracker = StubAnalyticsTracker()
        presenter = PaymentRequestDetailPresenterImpl(
            paymentRequestId: paymentRequestId,
            profile: FakeBusinessProfileInfo().asProfile(),
            router: router,
            listUpdateDelegate: updateDelegate,
            imageLoader: imageLoader,
            paymentRequestUseCase: paymentRequestUseCase,
            attachmentService: attachmentService,
            paymentRequestDetailsUseCase: paymentRequestDetailsUseCase,
            paymentRequestDetailViewModelFactory: paymentRequestDetailViewModelFactory,
            analyticsTracker: analyticsTracker,
            pasteboard: pasteboard,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        presenter = nil
        paymentRequestUseCase = nil
        router = nil
        view = nil
        attachmentService = nil
        paymentRequestDetailsUseCase = nil
        paymentRequestDetailViewModelFactory = nil
        pasteboard = nil
        imageLoader = nil
        analyticsTracker = nil
        super.tearDown()
    }

    func test_start() throws {
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        let expectedViewModel = makeViewModel()
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(expectedViewModel)

        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(viewModel, expectedViewModel)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - Viewing Details")
    }

    func test_dismiss() {
        presenter.dismiss()
        XCTAssertEqual(router.dismissCallsCount, 1)
    }

    func test_goBackToAllPayments() {
        presenter.goBackToAllPayments()
        XCTAssertEqual(router.goBackToAllPaymentsCallsCount, 1)
    }

    func test_paymentDetailsTapped_givenNavigateToAcquiringPayment_thenShowPaymentLinkPaymentDetails() {
        presenter.paymentDetailsTapped(
            action: .navigateToAcquiringPayment(acquiringPaymentId)
        )

        XCTAssertEqual(router.showPaymentLinkPaymentDetailsReceivedAcquiringPaymentId, acquiringPaymentId)
        XCTAssertEqual(router.showPaymentLinkPaymentDetailsCallsCount, 1)
    }

    func test_paymentDetailsTapped_givenNavigateToAcquiringTransaction_thenShowAcquiringTransactionPaymentDetails() {
        presenter.paymentDetailsTapped(
            action: .navigateToAcquiringTransaction(transactionId)
        )

        XCTAssertEqual(router.showAcquiringTransactionPaymentDetailsReceivedTransactionId, transactionId)
        XCTAssertEqual(router.showAcquiringTransactionPaymentDetailsCallsCount, 1)
    }

    func test_paymentDetailsTapped_givenNavigateToTransfer_thenShowTransferPaymentDetails() {
        presenter.paymentDetailsTapped(
            action: .navigateToTransfer(transferId)
        )

        XCTAssertEqual(router.showTransferPaymentDetailsReceivedTransferId, transferId)
        XCTAssertEqual(router.showTransferPaymentDetailsCallsCount, 1)
    }

    func test_cancelPaymentRequestTapped() throws {
        paymentRequestDetailViewModelFactory.makeCancelConfirmationReturnValue = InfoSheetViewModel.canned

        presenter.cancelPaymentRequestTapped(requestType: .singleUse)

        XCTAssertEqual(paymentRequestDetailViewModelFactory.makeCancelConfirmationCallsCount, 1)
        XCTAssertEqual(paymentRequestDetailViewModelFactory.makeCancelConfirmationReceivedArguments?.requestType, .singleUse)
        XCTAssertEqual(router.showActionConfirmationCallsCount, 1)
        XCTAssertEqual(router.showActionConfirmationReceivedViewModel, InfoSheetViewModel.canned)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - Open Cancellation Prompt")
    }

    func test_cancelPaymentRequestConfirmed_givenUpdateSuccess_thenConfigureView() throws {
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .just(.canned)
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.cancelPaymentRequestConfirmed()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.configureCallsCount, 2)
        XCTAssertEqual(paymentRequestUseCase.updatePaymentRequestStatusCallsCount, 1)
        XCTAssertEqual(paymentRequestUseCase.updatePaymentRequestStatusReceivedArguments?.body.status, .invalidated)
        XCTAssertEqual(paymentRequestDetailViewModelFactory.makeCallsCount, 2)
        XCTAssertEqual(updateDelegate.requestStatusUpdatedCallsCount, 1)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - Cancel Request")
    }

    func test_cancelPaymentRequestConfirmed_givenUdpateFailure_thenShowError() {
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .fail(with: PaymentRequestUseCaseError.customError(message: "custom"))
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.cancelPaymentRequestConfirmed()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
        XCTAssertEqual(paymentRequestUseCase.updatePaymentRequestStatusCallsCount, 1)
        XCTAssertEqual(updateDelegate.requestStatusUpdatedCallsCount, 0)
    }

    func test_markAsPaidTapped() throws {
        paymentRequestDetailViewModelFactory.makeMarkAsPaidConfirmationReturnValue = InfoSheetViewModel.canned

        presenter.markAsPaidTapped(requestType: .singleUse)

        XCTAssertEqual(paymentRequestDetailViewModelFactory.makeMarkAsPaidConfirmationCallsCount, 1)
        XCTAssertEqual(paymentRequestDetailViewModelFactory.makeMarkAsPaidConfirmationReceivedArguments?.requestType, .singleUse)
        XCTAssertEqual(router.showActionConfirmationCallsCount, 1)
        XCTAssertEqual(router.showActionConfirmationReceivedViewModel, InfoSheetViewModel.canned)
    }

    func test_markAsPaidConfirmed_givenUpdateSuccess_thenConfigureView() throws {
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .just(.canned)
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.markAsPaidConfirmed()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.configureCallsCount, 2)
        XCTAssertEqual(paymentRequestUseCase.updatePaymentRequestStatusCallsCount, 1)
        XCTAssertEqual(paymentRequestUseCase.updatePaymentRequestStatusReceivedArguments?.body.status, .completed)
        XCTAssertEqual(paymentRequestDetailViewModelFactory.makeCallsCount, 2)
        XCTAssertEqual(updateDelegate.requestStatusUpdatedCallsCount, 1)
    }

    func test_markAsPaidConfirmed_givenUpdateFailure_thenShowError() {
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .fail(with: PaymentRequestUseCaseError.customError(message: "custom"))
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.markAsPaidConfirmed()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
        XCTAssertEqual(paymentRequestUseCase.updatePaymentRequestStatusCallsCount, 1)
        XCTAssertEqual(updateDelegate.requestStatusUpdatedCallsCount, 0)
    }

    func test_copyTapped() throws {
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.copyTapped(link)

        XCTAssertEqual(pasteboard.clipboard, [link])
        XCTAssertEqual(view.showSnackBarCallsCount, 1)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - Copy Request Link")
    }

    func test_viewAttachmentFileTapped_success() throws {
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)
        view.documentDelegate = UIDocumentInteractionControllerDelegateMock()
        attachmentService.downloadFileReturnValue = .just(URL.canned)

        presenter.viewAttachmentFileTapped(file)

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(attachmentService.downloadFileCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(router.showDocumentPreviewCallsCount, 1)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - View Invoice")
    }

    func test_viewAttachmentFileTapped_failure() throws {
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)
        attachmentService.downloadFileReturnValue = .fail(with: AttachmentFileDownloadError.downloadError)

        presenter.viewAttachmentFileTapped(file)

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(attachmentService.downloadFileCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - View Invoice")
    }

    func test_paymentMethodSummariesTapped() throws {
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        let viewModel = PaymentRequestDetailPaymentMethodsViewModel(
            title: LoremIpsum.short,
            summaries: [
                SummaryViewModel(
                    title: LoremIpsum.short,
                    description: LoremIpsum.medium,
                    icon: Icons.bank.image
                ),
                SummaryViewModel(
                    title: LoremIpsum.short,
                    description: LoremIpsum.medium,
                    icon: Icons.card.image
                ),
            ]
        )
        presenter.paymentMethodSummariesTapped(viewModel: viewModel)

        XCTAssertEqual(view.showPaymentMethodSummariesCallsCount, 1)
        XCTAssertEqual(view.showPaymentMethodSummariesReceivedViewModel, viewModel)
    }

    func test_shareOptionsTapped() throws {
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        let viewModel = PaymentRequestDetailShareOptionsViewModel(
            paymentLink: link,
            options: [
                OptionViewModel(
                    title: "paymentRequest.detail.paymentLink.options.copy",
                    avatar: .icon(Icons.link.image)
                ),
                OptionViewModel(
                    title: "paymentRequest.detail.paymentLink.options.qrCode",
                    avatar: .icon(Icons.qrCode.image)
                ),
                OptionViewModel(
                    title: "paymentRequest.detail.paymentLink.options.share",
                    avatar: .icon(Icons.shareAndroid.image)
                ),
            ],
            handler: { _, _ in }
        )
        presenter.shareOptionsTapped(viewModel: viewModel)

        XCTAssertEqual(view.showShareOptionsCallsCount, 1)
        XCTAssertEqual(view.showShareOptionsReceivedViewModel, viewModel)
    }

    func test_shareWithQRCodeTapped_givenFetchPaymentRequestSucceeds_thenShowQRCode() {
        paymentRequestUseCase.paymentRequestReturnValue = .just(.canned)
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.shareWithQRCodeTapped()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(router.showQRCodeCallsCount, 1)
    }

    func test_shareWithQRCodeTapped_givenFetchPaymentRequestFails_thenShowQRCode() {
        paymentRequestUseCase.paymentRequestReturnValue = .fail(with: PaymentRequestUseCaseError.customError(message: "custom"))
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.shareWithQRCodeTapped()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
    }

    func test_shareSheetTapped_givenFetchPaymentRequestSucceeds_thenShowShareSheet() {
        paymentRequestUseCase.paymentRequestReturnValue = .just(.canned)
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.shareSheetTapped()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(router.showShareSheetCallsCount, 1)
    }

    func test_shareSheetTapped_givenFetchPaymentRequestFails_thenShowError() {
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .fail(with: MockError.dummy)
        paymentRequestUseCase.paymentRequestReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.shareSheetTapped()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
    }

    func test_fetchAvatarViewModel_givenFetchImageSuccess_thenReturnCorrectViewModel() throws {
        let image = UIImage()
        imageLoader.loadReturnValue = .just(image)

        let result = try awaitPublisher(
            presenter.fetchAvatarViewModel(
                urlString: avatarUrlString,
                fallbackImage: UIImage(),
                badge: nil
            )
        )

        let expected = AvatarViewModel.image(image, badge: nil)
        expectNoDifference(result.value, expected)
    }

    func test_fetchAvatarViewModel_givenFetchImageFailure_thenReturnCorrectViewModel() throws {
        imageLoader.loadReturnValue = .fail(with: MockError.dummy)

        let fallbackImage = UIImage()
        let result = try awaitPublisher(
            presenter.fetchAvatarViewModel(
                urlString: avatarUrlString,
                fallbackImage: fallbackImage,
                badge: nil
            )
        )

        let expected = AvatarViewModel.icon(fallbackImage, badge: nil)
        expectNoDifference(result.value, expected)
    }

    func test_didRefundFlowCompleted() throws {
        paymentRequestDetailsUseCase.paymentRequestDetailsReturnValue = .just(.canned)
        paymentRequestDetailViewModelFactory.makeReturnValue = .just(makeViewModel())
        presenter.start(with: view)

        presenter.didRefundFlowCompleted()

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        let expectedViewModel = makeViewModel()
        expectNoDifference(viewModel, expectedViewModel)
        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.configureCallsCount, 2)
        XCTAssertEqual(router.goBackToPaymentRequestDetailCallsCount, 1)
    }

    func test_viewAllPaymentsTapped() throws {
        let urnString = "urn:wise:requests:ABcd-wxYz:payments"
        presenter.sectionHeaderActionTapped(urnString: urnString)

        XCTAssertEqual(router.goToViewAllPaymentsCallsCount, 1)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - Urn Pressed")
        let properties = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked)
        let urn = try XCTUnwrap(properties["Urn"] as? String)
        XCTAssertEqual(urn, urnString)
    }
}

// MARK: - Helpers

private extension PaymentRequestDetailPresenterTests {
    func makeViewModel() -> PaymentRequestDetailViewModel {
        let headerViewModel = PaymentRequestDetailViewModel.HeaderViewModel(
            icon: .icon(Icons.requestSend.image),
            iconStyle: .size56,
            title: LoremIpsum.short,
            subtitle: LoremIpsum.medium
        )
        let footerViewModel = PaymentRequestDetailViewModel.FooterViewModel(
            primaryAction: Action(
                title: "Cancel request",
                handler: {}
            ),
            secondaryAction: nil,
            configuration: .positiveOnly
        )
        return PaymentRequestDetailViewModel(
            header: headerViewModel,
            sections: [],
            footer: footerViewModel
        )
    }
}

private class UIDocumentInteractionControllerDelegateMock: UIViewControllerMock, UIDocumentInteractionControllerDelegate {}
