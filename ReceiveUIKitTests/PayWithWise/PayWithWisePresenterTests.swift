import AnalyticsKit
import AnalyticsKitTestingSupport
import BalanceKit
import Combine
import CombineSchedulers
import ContactsKit
import Foundation
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TransferResources
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKit
import UserKitTestingSupport
import WiseAtomsAssets
import WiseCore

@MainActor
final class PayWithWisePresenterTests: TWTestCase {
    private var presenter: PayWithWisePresenterImpl!
    private var interactor: PayWithWiseInteractorMock!
    private var router: PayWithWiseRouterMock!
    private var flowNavigationDelegate: PayWithWiseFlowNavigationDelegateMock!
    private var viewModelFactory: PayWithWiseViewModelFactoryMock!
    private var userProvider: StubUserProvider!
    private var notificationCenter: MockNotificationCenter!
    private var view: PayWithWiseViewMock!
    private var payWithWiseAnalyticsTracker: PayWithWiseAnalyticsTrackerMock!

    private let expectedMessage = "Msg"

    override func setUp() {
        super.setUp()

        interactor = PayWithWiseInteractorMock()
        router = PayWithWiseRouterMock()
        flowNavigationDelegate = PayWithWiseFlowNavigationDelegateMock()
        viewModelFactory = PayWithWiseViewModelFactoryMock()
        userProvider = StubUserProvider()
        notificationCenter = MockNotificationCenter()
        view = PayWithWiseViewMock()
        payWithWiseAnalyticsTracker = PayWithWiseAnalyticsTrackerMock()

        interactor.gatherPaymentKeyReturnValue = .just(.canned)
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup()
        interactor.balancesReturnValue = .just(.canned)
        interactor.createPaymentReturnValue = .just((PaymentRequestSession.canned, PayWithWiseQuote.canned))
        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.canned
        viewModelFactory.type().makeItemsReturnValue = []
        viewModelFactory.makeReturnValue = .loaded(.canned)

        presenter = getPresenter()
    }

    override func tearDown() {
        presenter = nil
        interactor = nil
        router = nil
        viewModelFactory = nil
        userProvider = nil
        notificationCenter = nil
        view = nil
        payWithWiseAnalyticsTracker = nil

        super.tearDown()
    }
}

// MARK: - Start & loading pipeline

extension PayWithWisePresenterTests {
    func testLoadingPipeline_GivenDefaultValues_WhenPresenterStarted_ThenCorrectParametersPassed_AndValuesReceived() throws {
        let expectedKey = "Key"
        let expectedTitle = "Ttl"
        let expectedRequestId = PaymentRequestId("ReqID")
        let expectedBalanceId = BalanceId(123)
        let expectedAvatarUrl = "http://url.com"
        let expectedAvatarImage = AvatarModel.image(Illustrations.electricPlug.image, badge: nil)
        let expectedAmount = Money.build(currency: .AUD, value: 10)
        let balance = Balance.build(
            id: expectedBalanceId,
            availableAmount: 100,
            currency: .AUD
        )

        interactor.gatherPaymentKeyReturnValue = .just(expectedKey)
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            id: expectedRequestId,
            requester: PaymentRequestLookup.Requester.build(
                avatarUrl: expectedAvatarUrl
            ),
            amount: expectedAmount
        )
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .build(
                    balance: balance
                ),
                fundableBalances: [balance],
                balances: [balance]
            )
        )
        interactor.createPaymentReturnValue = .just(
            (
                PaymentRequestSession.canned,
                PayWithWiseQuote.build(
                    sourceAmount: expectedAmount
                )
            )
        )
        interactor.loadImageReturnValue = .just(Illustrations.electricPlug.image)
        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()
        viewModelFactory.makeReturnValue = .loaded(
            PayWithWiseViewModel.Loaded.build(
                header: PayWithWiseHeaderView.ViewModel(
                    title: .init(title: expectedTitle),
                    recipientName: "Name",
                    description: nil,
                    avatarImage: .just(AvatarViewModel(avatar: expectedAvatarImage))
                )
            )
        )
        viewModelFactory.makeHeaderViewModelReturnValue = PayWithWiseHeaderView.ViewModel.canned

        presenter.start(with: view)

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedEvent,
            .loaded(
                requestCurrency: "AUD",
                paymentCurrency: "AUD",
                isSameCurrency: true,
                requestCurrencyBalanceExists: true,
                requestCurrencyBalanceHasEnough: true,
                errorCode: nil,
                errorMessage: nil
            )
        )

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(interactor.paymentRequestLookupReceivedPaymentKey, expectedKey)
        XCTAssertEqual(
            interactor.balancesReceivedArguments?.amount.value,
            expectedAmount.value
        )
        XCTAssertEqual(
            interactor.balancesReceivedArguments?.amount.currency,
            expectedAmount.currency
        )
        XCTAssertEqual(interactor.loadImageReceivedUrl?.absoluteString, expectedAvatarUrl)
        XCTAssertEqual(interactor.createPaymentReceivedArguments?.paymentKey, expectedKey)
        XCTAssertEqual(
            interactor.createPaymentReceivedArguments?.paymentRequestId,
            expectedRequestId
        )
        XCTAssertEqual(
            interactor.createPaymentReceivedArguments?.paymentRequestId,
            expectedRequestId
        )
        XCTAssertEqual(
            interactor.createPaymentReceivedArguments?.profileId.value,
            FakePersonalProfileInfo().id.value
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.loaded.header.title.title.text,
            expectedTitle
        )

        XCTAssertEqual(
            viewModelFactory.makeReceivedArguments?.avatar,
            expectedAvatarImage
        )
    }

    func testLoadingPipeline_GivenErrors_WhenPresenterStarted_ThenPipelineStoppedAtCorrectPoint() throws {
        viewModelFactory.makeAlertViewModelReturnValue = PayWithWiseViewModel.Alert.canned
        view.presentationRootViewController = UIViewController()
        interactor.gatherPaymentKeyReturnValue = .fail(with: PayWithWiseV2Error.noBalancesAvailable)

        presenter.start(with: view)

        XCTAssertFalse(interactor.paymentRequestLookupCalled)
        XCTAssertFalse(interactor.balancesCalled)
        XCTAssertFalse(interactor.createPaymentCalled)

        interactor.gatherPaymentKeyReturnValue = .just(.canned)
        interactor.paymentRequestLookupReturnValue = .fail(with: PayWithWiseV2Error.noBalancesAvailable)

        presenter.start(with: view)

        XCTAssertTrue(interactor.paymentRequestLookupCalled)
        XCTAssertFalse(interactor.balancesCalled)
        XCTAssertFalse(interactor.createPaymentCalled)

        interactor.gatherPaymentKeyReturnValue = .just("Key")
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(amount: .build(currency: .AUD, value: 10.0))
        interactor.balancesReturnValue = .fail(with: PayWithWiseV2Error.noBalancesAvailable)

        presenter.start(with: view)

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[4],
            .loaded(
                requestCurrency: "AUD",
                paymentCurrency: "null",
                isSameCurrency: false,
                requestCurrencyBalanceExists: false,
                requestCurrencyBalanceHasEnough: false,
                errorCode: "No Balances Available",
                errorMessage: "No balances available"
            )
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[5],
            .loadedWithError(errorCode: "No balances available", errorKey: .FetchingBalances())
        )

        XCTAssertEqual(payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[0], .startedLoggedIn)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[1],
            .started(context: .Link(), paymentRequestType: .business, currency: nil)
        )

        XCTAssertTrue(interactor.paymentRequestLookupCalled)
        XCTAssertTrue(interactor.balancesCalled)
        XCTAssertFalse(interactor.createPaymentCalled)
    }
}

// MARK: - Show details

extension PayWithWisePresenterTests {
    func testShowDetails_GivenValues_WhenShowDetailsCalled_ThenCorrectValuesReceived() {
        viewModelFactory.type().makeItemsReturnValue = [
            LegacyListItemViewModel(title: "", subtitle: expectedMessage),
        ]

        presenter.start(with: view)
        presenter.showDetails()

        XCTAssertEqual(payWithWiseAnalyticsTracker.trackEventReceivedEvent, .viewDetailsTapped)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedEvent,
            .started(context: .Link(), paymentRequestType: .business, currency: nil)
        )

        XCTAssertEqual(router.showDetailsReceivedViewModel?.rows.count, 1)
        XCTAssertEqual(
            router.showDetailsReceivedViewModel?.rows.first?.subtitle.text,
            expectedMessage
        )

        XCTAssertNil(router.showDetailsReceivedViewModel?.buttonConfiguration)
    }

    func testShowDetails_GivenAttachment_WhenShowDetailsCalled_ThenViewAttachmentButtonIsNotNull() {
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            attachmentFiles: [PayerAttachmentFile.canned]
        )

        presenter.start(with: view)
        presenter.showDetails()

        XCTAssertNotNil(router.showDetailsReceivedViewModel?.buttonConfiguration)
    }
}

// MARK: - Dismiss

extension PayWithWisePresenterTests {
    func testDismiss_WhenDismissCalled_ThenDelegateReceivedCorrectValue() {
        presenter.dismiss()
        XCTAssertEqual(flowNavigationDelegate.dismissedReceivedAt, .singlePagePayer)
    }
}

// MARK: - Payment

extension PayWithWisePresenterTests {
    func testPayment_GivenDefaultValues_ThenPayReceivedCorrectParameters() throws {
        let expectedSession = PaymentRequestSession.build(id: "Id")
        let expectedBalanceId = BalanceId(42)
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult.build(
                    balance: Balance.build(
                        id: expectedBalanceId,
                        currency: .TRY
                    )
                )
            )
        )
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            requester: PaymentRequestLookup.Requester.build(
                fullName: "Jane Doe"
            ),
            amount: Money.build(currency: .GBP, value: 10)
        )
        interactor.createPaymentReturnValue = .just(
            (expectedSession, PayWithWiseQuote.canned)
        )
        interactor.payReturnValue = .just(
            PayWithWisePayment.build(
                resource: PayWithWisePayment.Resource.build(type: .transfer)
            )
        )

        presenter.start(with: view)

        let showHudCallsCount = view.showHudCallsCount
        let hideHudCallsCount = view.hideHudCallsCount
        viewModelFactory.makeReceivedArguments?.firstButtonAction()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .payTapped(
                requestCurrency: "GBP",
                paymentCurrency: "TRY",
                profileType: .personal
            )
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .paySucceed(
                requestType: .Link(),
                requestCurrency: "GBP",
                paymentCurrency: "TRY"
            )
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[0],
            .startedLoggedIn
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[1],
            .started(context: .Link(), paymentRequestType: .business, currency: nil)
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[2],
            .paymentMethodSelected(method: .PayWithWise())
        )

        XCTAssertEqual(view.showHudCallsCount, showHudCallsCount + 1)
        XCTAssertEqual(view.hideHudCallsCount, hideHudCallsCount + 1)

        XCTAssertEqual(
            interactor.payReceivedArguments?.session,
            expectedSession
        )
        XCTAssertEqual(
            interactor.payReceivedArguments?.profileId,
            FakePersonalProfileInfo().id
        )
        XCTAssertEqual(
            interactor.payReceivedArguments?.balanceId,
            expectedBalanceId
        )

        let expectedSuccessPromptViewModel = PayWithWiseSuccessPromptViewModel(
            asset: .scene3D(.confetti),
            title: "All done",
            message: .textWithLink(
                text: "Get paid just as quick when you request money with Wise",
                linkText: "request money",
                action: {}
            ),
            primaryButtonTitle: "Done",
            completion: {}
        )
        XCTAssertEqual(
            router.showSuccessReceivedViewModel,
            expectedSuccessPromptViewModel
        )

        XCTAssertFalse(notificationCenter.postedNotifications.contains(.balancesNeedUpdate))
        XCTAssertFalse(notificationCenter.postedNotifications.contains(.needsActivityListUpdate))
    }

    func testPayment_GivenDefaultValues_ThenPayReceivedCorrectParameters_AndReceivedResourceTypeIsNotTransfer() throws {
        let expectedSession = PaymentRequestSession.build(id: "Id")
        let expectedBalanceId = BalanceId(42)
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult.build(
                    balance: Balance.build(
                        id: expectedBalanceId,
                        currency: .TRY
                    )
                )
            )
        )
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            requester: PaymentRequestLookup.Requester.build(
                fullName: "Jane Doe"
            ),
            amount: Money.build(currency: .GBP, value: 10)
        )
        interactor.createPaymentReturnValue = .just(
            (expectedSession, PayWithWiseQuote.canned)
        )
        interactor.payReturnValue = .just(
            PayWithWisePayment.build(
                resource: PayWithWisePayment.Resource.build(type: .other)
            )
        )

        presenter.start(with: view)

        let showHudCallsCount = view.showHudCallsCount
        let hideHudCallsCount = view.hideHudCallsCount
        viewModelFactory.makeReceivedArguments?.firstButtonAction()

        XCTAssertEqual(view.showHudCallsCount, showHudCallsCount + 1)
        XCTAssertEqual(view.hideHudCallsCount, hideHudCallsCount + 1)

        XCTAssertEqual(
            interactor.payReceivedArguments?.session,
            expectedSession
        )
        XCTAssertEqual(
            interactor.payReceivedArguments?.profileId,
            FakePersonalProfileInfo().id
        )
        XCTAssertEqual(
            interactor.payReceivedArguments?.balanceId,
            expectedBalanceId
        )

        let expectedSuccessPromptViewModel = PayWithWiseSuccessPromptViewModel(
            asset: .scene3D(.globe),
            title: "Almost there",
            message: .text("We just need a few more minutes to finish your transfer. Won't be long."),
            primaryButtonTitle: "Track your transfer",
            completion: {}
        )
        XCTAssertEqual(
            router.showSuccessReceivedViewModel,
            expectedSuccessPromptViewModel
        )

        XCTAssertFalse(notificationCenter.postedNotifications.contains(.balancesNeedUpdate))
        XCTAssertFalse(notificationCenter.postedNotifications.contains(.needsActivityListUpdate))
    }

    func testPayment_GivenMessageLinkTappedOnSuccessScreen_thenStartRequestMoney() throws {
        let expectedSession = PaymentRequestSession.build(id: "Id")
        let expectedBalanceId = BalanceId(42)
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult.build(
                    balance: Balance.build(
                        id: expectedBalanceId,
                        currency: .TRY
                    )
                )
            )
        )
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            requester: PaymentRequestLookup.Requester.build(
                fullName: "Jane Doe"
            ),
            amount: Money.build(currency: .GBP, value: 10)
        )
        interactor.createPaymentReturnValue = .just(
            (expectedSession, PayWithWiseQuote.canned)
        )
        interactor.payReturnValue = .just(
            PayWithWisePayment.build(
                resource: PayWithWisePayment.Resource.build(type: .transfer)
            )
        )

        presenter.start(with: view)
        viewModelFactory.makeReceivedArguments?.firstButtonAction()

        let message = try XCTUnwrap(router.showSuccessReceivedViewModel?.message)
        guard case let .textWithLink(_, _, action) = message else {
            XCTFail("Message config mismatches")
            return
        }
        action()

        XCTAssertEqual(router.showRequestMoneyCallsCount, 1)
    }

    func testPayment_GivenContactPayment_ThenSuccessScreenReceivedCorrectValues() throws {
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            requester: PaymentRequestLookup.Requester.build(
                fullName: "Jane Doe"
            ),
            amount: Money.build(currency: .EUR)
        )
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult.build(
                    balance: Balance.build(
                        currency: .NZD
                    )
                )
            )
        )
        interactor.createPaymentReturnValue = .just(
            (
                PaymentRequestSession.canned,
                PayWithWiseQuote.canned
            )
        )

        interactor.payReturnValue = .just(
            PayWithWisePayment.build(
                resource: PayWithWisePayment.Resource.build(type: .transfer)
            )
        )

        let presenter = getPresenter(source: .paymentKey(.contact(paymentKey: "")))

        presenter.start(with: view)
        viewModelFactory.makeReceivedArguments?.firstButtonAction()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .payTapped(
                requestCurrency: "EUR",
                paymentCurrency: "NZD",
                profileType: .personal
            )
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .paySucceed(
                requestType: .Contact(),
                requestCurrency: "EUR",
                paymentCurrency: "NZD"
            )
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[0],
            .startedLoggedIn
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[1],
            .started(context: .Contact(), paymentRequestType: .personal, currency: nil)
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[2],
            .paymentMethodSelected(method: .PayWithWise())
        )

        let expectedSuccessPromptViewModel = PayWithWiseSuccessPromptViewModel(
            asset: .scene3D(.confetti),
            title: "Request Paid",
            message: .textWithLink(
                text: "Get paid just as quick when you request money with Wise",
                linkText: "request money",
                action: {}
            ),
            primaryButtonTitle: "Done",
            completion: {}
        )

        XCTAssertEqual(
            router.showSuccessReceivedViewModel,
            expectedSuccessPromptViewModel
        )
    }
}

// MARK: - Secondary Action

extension PayWithWisePresenterTests {
    func testSecondaryAction_GivenContactRequestId_WhenSecondaryActionTriggered_ThenInteractorReceivesThatRequestId() throws {
        let requestId = PaymentRequestId("Ida")
        let presenter = getPresenter(source: .paymentKey(.contact(paymentKey: "")))
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            id: requestId
        )
        interactor.rejectRequestReturnValue = .just(OwedPaymentRequestStatusUpdate.canned)
        viewModelFactory.type().makeRejectConfirmationModelReturnValue = InfoSheetViewModel.canned

        presenter.start(with: view)

        let showHudCallsCount = view.showHudCallsCount
        let hideHudCallsCount = view.hideHudCallsCount
        viewModelFactory.makeReceivedArguments?.secondButtonAction()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .declineTapped(requestCurrencyBalanceExists: false)
        )
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[0],
            .startedLoggedIn
        )

        viewModelFactory.type().makeRejectConfirmationModelReceivedArguments?.confirmAction()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .declineConfirmed
        )

        XCTAssertTrue(interactor.rejectRequestCalled)
        XCTAssertEqual(view.showHudCallsCount, showHudCallsCount + 1)
        XCTAssertEqual(view.hideHudCallsCount, hideHudCallsCount + 1)
        XCTAssertEqual(
            interactor.rejectRequestReceivedArguments?.paymentRequestId,
            requestId
        )
        XCTAssertTrue(router.showRejectSuccessCalled)
    }

    func testSecondaryAction_GivenContactRequestIdAndFailure_WhenSecondaryActionTriggered_ThenCorrectErrorMessageShown() throws {
        let requestId = PaymentRequestId("Ida")
        let expectedTitle = "Ttle"
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            id: requestId
        )
        interactor.rejectRequestReturnValue = .fail(
            with: PayWithWiseV2Error.rejectingPaymentFailed(
                error: MockError.dummy
            )
        )

        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(PayWithWiseViewModel.Empty.build(title: expectedTitle))
        viewModelFactory.type().makeRejectConfirmationModelReturnValue = InfoSheetViewModel.canned

        let presenter = getPresenter(source: .paymentKey(.contact(paymentKey: "")))

        presenter.start(with: view)

        viewModelFactory.makeReceivedArguments?.secondButtonAction()
        viewModelFactory.type().makeRejectConfirmationModelReceivedArguments?.confirmAction()
        XCTAssertTrue(interactor.rejectRequestCalled)
        XCTAssertEqual(
            interactor.rejectRequestReceivedArguments?.paymentRequestId,
            requestId
        )
        XCTAssertFalse(router.showRejectSuccessCalled)
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.title,
            expectedTitle
        )
    }

    func testSecondaryAction_GivenLinkRequest_WhenSecondaryActionTriggered_ThenRouterReceivedCorrectNavigation() throws {
        let expectedPaymentKey = "Key"
        let expectedName = "Jane Doe"
        let paymentMethods = [
            PayerAcquiringPaymentMethod.build(
                type: AcquiringPaymentMethodType.card
            ),
            .build(type: .card),
        ]
        interactor.gatherPaymentKeyReturnValue = .just(expectedPaymentKey)
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            requester: PaymentRequestLookup.Requester.build(
                fullName: expectedName
            ),
            amount: Money.build(currency: .NOK, value: 10),
            availablePaymentMethods: paymentMethods
        )

        presenter.start(with: view)
        viewModelFactory.makeReceivedArguments?.secondButtonAction()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .payAnotherWayTapped(
                requestCurrency: "NOK",
                requestCurrencyBalanceExists: false,
                requestCurrencyBalanceHasEnough: false
            )
        )

        XCTAssertEqual(
            router.showPaymentMethodsBottomSheetReceivedArguments?.requesterName,
            expectedName
        )
        XCTAssertEqual(
            router.showPaymentMethodsBottomSheetReceivedArguments?.paymentMethods,
            paymentMethods
        )
    }

    func testSecondaryAction_GivenLinkRequestAndSinglePaymentMethod_WhenSecondaryActionTriggered_ThenRouterReceivedCorrectNavigation() throws {
        let expectedPaymentKey = "Key"
        let expectedName = "Jane Doe"
        let expectedMethod = "ACCOUNT_DETAILS"
        let paymentMethod = PayerAcquiringPaymentMethod.build(
            type: AcquiringPaymentMethodType.bankTransfer,
            value: expectedMethod
        )

        interactor.gatherPaymentKeyReturnValue = .just(expectedPaymentKey)
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            requester: PaymentRequestLookup.Requester.build(
                fullName: expectedName
            ),
            amount: Money.build(currency: .NOK),
            availablePaymentMethods: [paymentMethod]
        )

        presenter.start(with: view)
        viewModelFactory.makeReceivedArguments?.secondButtonAction()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[0],
            .startedLoggedIn
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[1],
            .started(context: .Link(), paymentRequestType: .business, currency: nil)
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[2],
            .paymentMethodSelected(method: .BankTransfer())
        )

        XCTAssertEqual(
            router.showPaymentMethodReceivedArguments?.paymentKey,
            expectedPaymentKey
        )

        XCTAssertEqual(
            router.showPaymentMethodReceivedArguments?.paymentMethod,
            paymentMethod
        )
    }
}

// MARK: - Attachment loading

extension PayWithWisePresenterTests {
    func testAttachmentDownloading_GivenAttachmentFileAndURL_WhenLoadAttachmentActionTriggered_ThenCorrectAttachmentDisplayed() throws {
        let attachmentFile = PayerAttachmentFile.build(id: "Sth")
        let expectedURL = try XCTUnwrap(URL(string: "https://abc.com"))
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            attachmentFiles: [attachmentFile]
        )
        interactor.loadAttachmentReturnValue = .just(expectedURL)
        view.documentDelegate = StubDocumentInteractionViewController()

        presenter.start(with: view)
        presenter.showDetails()
        router.showDetailsReceivedViewModel?.buttonConfiguration?.handler()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .viewDetailsTapped
        )

        let showHudCallsCount = view.showHudCallsCount
        let hideHudCallsCount = view.hideHudCallsCount

        XCTAssertEqual(view.showHudCallsCount, showHudCallsCount)
        XCTAssertEqual(view.hideHudCallsCount, hideHudCallsCount)
        XCTAssertEqual(
            interactor.loadAttachmentReceivedArguments?.attachmentFile,
            attachmentFile
        )
        XCTAssertEqual(
            router.showAttachmentReceivedArguments?.url,
            expectedURL
        )
    }

    func testAttachmentDownloading_GivenError_WhenLoadAttachmentActionTriggered_ThenCorrectErrorDisplayed() throws {
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            attachmentFiles: [PayerAttachmentFile.canned]
        )
        interactor.loadAttachmentReturnValue = .fail(
            with: PayWithWiseV2Error.downloadingAttachmentFailed
        )

        presenter.start(with: view)
        presenter.showDetails()
        router.showDetailsReceivedViewModel?.buttonConfiguration?.handler()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .viewDetailsTapped
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .viewAttachmentTapped
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[3],
            .attachmentLoadingFailed(message: "Downloading Attachment Failed")
        )

        XCTAssertEqual(
            view.showErrorAlertReceivedArguments?.title,
            L10n.PaymentRequest.Detail.Error.title
        )
        XCTAssertEqual(
            view.showErrorAlertReceivedArguments?.message,
            L10n.PaymentRequest.Detail.Error.Download.subtitle
        )
    }
}

// MARK: - Balance selection

extension PayWithWisePresenterTests {
    func testBalanceSelection_GivenBalances_WhenIndexSelected_CorrectIdSentToInteractor() throws {
        let balances = [
            Balance.build(
                id: BalanceId(16),
                currency: .AUD
            ),
            .build(
                id: BalanceId(32),
                currency: .NZD
            ),
            .build(
                id: BalanceId(64),
                currency: .TRY
            ),
        ]
        viewModelFactory.makeBalanceOptionsContainerReturnValue = .build(
            fundables: [
                PayWithWiseViewModelFactoryImpl.BalanceOption.build(
                    id: balances[0].id
                ),
                .build(
                    id: balances[1].id
                ),
                .build(
                    id: balances[2].id
                ),
            ]
        )
        viewModelFactory.makeBalanceSectionsReturnValue = [
            PayWithWiseBalanceSelectorViewModel.Section.build(
                options: [
                    .canned,
                    .canned,
                    .canned,
                ]
            ),
        ]
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            amount: Money.build(currency: .USD, value: 1)
        )
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult.build(
                    balance: balances[0],
                    hasSameCurrencyBalance: true,
                    hasFunds: true
                ),
                fundableBalances: balances,
                balances: balances
            )
        )

        presenter.start(with: view)
        viewModelFactory.makeReceivedArguments?.selectBalanceAction()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .balanceSelectorOpened(noOfBalances: 3)
        )

        XCTAssertEqual(
            router.showBalanceSelectorReceivedViewModel?.sections.first?.options.count,
            3
        )

        XCTAssertEqual(interactor.createPaymentCallsCount, 1)
        XCTAssertFalse(router.dismissBalanceSelectorCalled)
        router.showBalanceSelectorReceivedViewModel?.selectAction(
            IndexPath(row: 1, section: 0)
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .balanceSelected(
                requestCurrency: "USD",
                paymentCurrency: "NZD",
                isSameCurrency: false,
                requestCurrencyBalanceExists: false,
                requestCurrencyBalanceHasEnough: false
            )
        )

        XCTAssertTrue(router.dismissBalanceSelectorCalled)
        XCTAssertEqual(interactor.createPaymentCallsCount, 2)
        XCTAssertEqual(
            interactor.createPaymentReceivedInvocations.last?.balanceId,
            balances[1].id
        )
    }
}

// MARK: - Profile change

extension PayWithWisePresenterTests {
    func testProfileChangeSupport_GivenMultipleProfilesAndLinkRequest_ThenSupportsIt() {
        userProvider.profiles = [
            FakePersonalProfileInfo().asProfile(),
            FakeBusinessProfileInfo().asProfile(),
        ]
        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeReceivedArguments?.supportsProfileChange,
            true
        )
    }

    func testProfileChangeSupport_GivenSingleProfileAndLinkRequest_ThenDoesNotSupportsIt() {
        userProvider.profiles = [
            FakeBusinessProfileInfo().asProfile(),
        ]

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeReceivedArguments?.supportsProfileChange,
            false
        )
    }

    func testProfileChangeSupport_GivenMultipleProfilesAndContactRequest_ThenDoesNotSupportsIt() {
        userProvider.profiles = [
            FakePersonalProfileInfo().asProfile(),
            FakeBusinessProfileInfo().asProfile(),
        ]
        let presenter = getPresenter(source: .paymentKey(.contact(paymentKey: "")))
        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeReceivedArguments?.supportsProfileChange,
            false
        )
    }

    func testProfileChange_GivenNewProfileInfo_WhenProfileChanged_ThenDataRefreshedWithNewProfile() throws {
        let newProfileInfo = FakeBusinessProfileInfo()
        newProfileInfo.id = ProfileId(128)
        let oldProfileInfo = FakePersonalProfileInfo()

        presenter.start(with: view)

        XCTAssertEqual(
            interactor.balancesReceivedArguments?.profileId,
            oldProfileInfo.id
        )

        viewModelFactory.makeReceivedArguments?.selectProfileAction()

        XCTAssertTrue(router.showProfileSwitcherCalled)
        userProvider.activeProfile = newProfileInfo.asProfile()

        let completion = try XCTUnwrap(router.showProfileSwitcherReceivedCompletion)
        completion()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .profileChanged(profileType: .business)
        )

        XCTAssertEqual(interactor.balancesReceivedArguments?.profileId, newProfileInfo.id)
    }
}

// MARK: - Error handling

extension PayWithWisePresenterTests {
    func testErrorHandling_GivenFetchingPaymentKeyFailed_ThenCorrectErrorShown() {
        interactor.gatherPaymentKeyReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingPaymentKeyFailed(
                error: MockError.dummy
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            L10n.PayWithWise.Payment.Error.Message.generic
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.exclamationMark.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenFetchingPaymentRequestInfoFailedAlreadyPaid_ThenCorrectErrorShown() {
        interactor.paymentRequestLookupReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingPaymentRequestInfoFailed(
                error: PayWithWisePaymentRequestInfoError.alreadyPaid(message: expectedMessage)
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            expectedMessage
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.receive.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenFetchingPaymentRequestInfoFailedExpired_ThenCorrectErrorShown() {
        interactor.paymentRequestLookupReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingPaymentRequestInfoFailed(
                error: PayWithWisePaymentRequestInfoError.expired(message: expectedMessage)
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            expectedMessage
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.electricPlug.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenFetchingPaymentRequestInfoFailedOther_ThenCorrectErrorShown() {
        interactor.paymentRequestLookupReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingPaymentRequestInfoFailed(
                error: PayWithWisePaymentRequestInfoError.other(MockError.dummy)
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: MockError.dummy.localizedDescription
            )
        )

        presenter.start(with: view)
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            MockError.dummy.localizedDescription
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.exclamationMark.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            MockError.dummy.localizedDescription
        )
    }

    func testErrorHandling_GivenFetchingPaymentRequestInfoFailedUnknown_ThenCorrectErrorShown() {
        interactor.paymentRequestLookupReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingPaymentRequestInfoFailed(
                error: PayWithWisePaymentRequestInfoError.unknown(message: expectedMessage)
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            expectedMessage
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.exclamationMark.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenFetchingPaymentRequestInfoFailedNotFound_ThenCorrectErrorShown() {
        interactor.paymentRequestLookupReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingPaymentRequestInfoFailed(
                error: PayWithWisePaymentRequestInfoError.notFound(message: expectedMessage)
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            expectedMessage
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.exclamationMark.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenDownloadingAttachmentFailed_ThenCorrectErrorShown() {
        interactor.loadAttachmentReturnValue = .fail(
            with: PayWithWiseV2Error.downloadingAttachmentFailed
        )
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            attachmentFiles: [PayerAttachmentFile.canned]
        )
        presenter.start(with: view)
        presenter.showDetails()
        router.showDetailsReceivedViewModel?.buttonConfiguration?.handler()

        XCTAssertEqual(
            view.showErrorAlertReceivedArguments?.title,
            L10n.PaymentRequest.Detail.Error.title
        )
        XCTAssertEqual(
            view.showErrorAlertReceivedArguments?.message,
            L10n.PaymentRequest.Detail.Error.Download.subtitle
        )
    }

    func testErrorHandling_GivenSavingAttachmentFailed_ThenCorrectErrorShown() {
        interactor.loadAttachmentReturnValue = .fail(
            with: PayWithWiseV2Error.savingAttachmentFailed
        )
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            attachmentFiles: [PayerAttachmentFile.canned]
        )
        presenter.start(with: view)
        presenter.showDetails()
        router.showDetailsReceivedViewModel?.buttonConfiguration?.handler()
        presenter.start(with: view)
        XCTAssertEqual(
            view.showErrorAlertReceivedArguments?.title,
            L10n.PaymentRequest.Detail.Error.title
        )
        XCTAssertEqual(
            view.showErrorAlertReceivedArguments?.message,
            L10n.PaymentRequest.Detail.Error.Download.subtitle
        )
    }

    func testErrorHandling_GivenFetchingBalancesFailed_ThenCorrectErrorShown() {
        interactor.balancesReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingBalancesFailed(
                error: MockError.dummy
            )
        )

        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            L10n.PayWithWise.Payment.Error.Message.generic
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.exclamationMark.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenFetchingFundableBalancesFailed_ThenCorrectErrorShown() {
        interactor.balancesReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingFundableBalancesFailed(
                error: MockError.dummy
            )
        )

        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            L10n.PayWithWise.Payment.Error.Message.generic
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.exclamationMark.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenNoBalancesAvailable_ThenCorrectErrorShown() throws {
        interactor.paymentRequestLookupReturnValue = makePaymentRequestLookup(
            amount: Money.build(
                currency: .AUD,
                value: 1
            )
        )
        interactor.balancesReturnValue = .fail(
            with: PayWithWiseV2Error.noBalancesAvailable
        )
        viewModelFactory.makeAlertViewModelReturnValue = .build(
            viewModel: InlineAlertViewModel(message: expectedMessage)
        )
        view.presentationRootViewController = UIViewController()

        presenter.start(with: view)

        let action = try XCTUnwrap(
            viewModelFactory.makeAlertViewModelReceivedArguments?.action
        )

        action.handler()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .loadedWithError(errorCode: "No balances available", errorKey: .FetchingBalances())
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .topUpTapped
        )

        XCTAssertTrue(
            router.showTopUpFlowCalled
        )
        XCTAssertEqual(
            router.showTopUpFlowReceivedArguments?.targetAmount,
            .build(currency: .AUD, value: 1)
        )

        XCTAssertEqual(
            viewModelFactory.makeAlertViewModelReceivedArguments?.message,
            "You haven\'t opened a balance in AUD yet. Open it now or choose a different way to pay."
        )
        XCTAssertEqual(
            viewModelFactory.makeReceivedArguments?.inlineAlert?.viewModel.message.text,
            expectedMessage
        )
    }

    func testErrorHandling_GivenFetchingSessionFailed_ThenCorrectErrorShown() {
        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingSessionFailed(
                error: MockError.dummy
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )
        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            L10n.PayWithWise.Payment.Error.Message.generic
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.exclamationMark.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenFetchingQuoteFailedAlreadyPaid_ThenCorrectErrorShown() {
        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingQuoteFailed(
                error: PayWithWisePaymentError.alreadyPaid(
                    message: expectedMessage
                )
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            expectedMessage
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.receive.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenFetchingQuoteFailedTargetIsSelf_ThenCorrectErrorShown() {
        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingQuoteFailed(
                error: PayWithWisePaymentError.targetIsSelf(
                    message: expectedMessage
                )
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        viewModelFactory.makeAlertViewModelReturnValue = .build(
            viewModel: InlineAlertViewModel(message: expectedMessage)
        )

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeAlertViewModelReceivedArguments?.message,
            expectedMessage
        )
        XCTAssertEqual(
            viewModelFactory.makeAlertViewModelReceivedArguments?.style,
            .negative
        )
    }

    func testErrorHandling_GivenFetchingQuoteFailedSourceUnavailable_ThenCorrectErrorShown() {
        view.presentationRootViewController = UIViewController()
        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingQuoteFailed(
                error: PayWithWisePaymentError.sourceUnavailable(
                    message: expectedMessage
                )
            )
        )
        viewModelFactory.makeAlertViewModelReturnValue = .build(
            viewModel: InlineAlertViewModel(message: expectedMessage)
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeAlertViewModelReceivedArguments?.message,
            expectedMessage
        )
        XCTAssertEqual(
            viewModelFactory.makeAlertViewModelReceivedArguments?.style,
            .negative
        )
    }

    func testErrorHandling_GivenFetchingQuoteFailedOther_ThenCorrectErrorShown() {
        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingQuoteFailed(
                error: PayWithWisePaymentError.other(MockError.dummy)
            )
        )
        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            L10n.PayWithWise.Payment.Error.Message.generic
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.exclamationMark.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenRejectingPaymentFailed_ThenCorrectErrorShown() {
        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingQuoteFailed(
                error: PayWithWisePaymentError.other(MockError.dummy)
            )
        )

        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(
            PayWithWiseViewModel.Empty.build(
                message: expectedMessage
            )
        )

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.message,
            L10n.PayWithWise.Payment.Error.Message.generic
        )
        XCTAssertEqual(
            viewModelFactory.makeEmptyStateViewModelReceivedArguments?.image,
            Illustrations.exclamationMark.image
        )
        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.message,
            expectedMessage
        )
    }

    func testErrorHandling_GivenCustomError_ThenCorrectErrorShown() throws {
        let expectedIdentifier = "Code"
        let expectedMessage = "Msg"

        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingQuoteFailed(
                error: PayWithWisePaymentError.customError(
                    code: expectedIdentifier,
                    message: expectedMessage
                )
            )
        )
        viewModelFactory.makeAlertViewModelReturnValue = PayWithWiseViewModel.Alert.canned

        presenter.start(with: view)

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[0],
            .loaded(
                requestCurrency: "",
                paymentCurrency: "null",
                isSameCurrency: false,
                requestCurrencyBalanceExists: false,
                requestCurrencyBalanceHasEnough: false,
                errorCode: "Fetching Quote Failed",
                errorMessage: "Msg"
            )
        )

        XCTAssertEqual(
            viewModelFactory.makeAlertViewModelReceivedArguments?.message,
            expectedMessage
        )
    }
}

// MARK: - Eligibility

extension PayWithWisePresenterTests {
    func testEligibility_GivenEligibleBusinessProfile_ThenCorrectParametersPassed() {
        let profileInfo = FakeBusinessProfileInfo()
        profileInfo.addPrivilege(TransferPrivilege.create)

        presenter.start(with: view)

        XCTAssertNil(viewModelFactory.makeReceivedArguments?.inlineAlert)
    }

    func testEligibility_GivenIneligibleBusinessProfile_ThenCorrectParametersPassed() {
        let presenter = getPresenter(source: .paymentRequestId(.canned), profile: FakeBusinessProfileInfo().asProfile())

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeReceivedArguments?.inlineAlert?.viewModel.message.text,
            L10n.PayWithWise.Payment.Error.Message.ineligible
        )
    }
}

// MARK: - Analytics

extension PayWithWisePresenterTests {
    func testStartAnalytics_GivenLinkRequest_WhenViewStarted_ThenCorrectEventsTracked() throws {
        interactor.gatherPaymentKeyReturnValue = .just("")
        interactor.paymentRequestLookupReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingPaymentRequestInfoFailed(
                error: .unknown(message: "")
            )
        )

        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(PayWithWiseViewModel.Empty.canned)

        presenter.start(with: view)
    }

    func testStartAnalytics_GivenContactRequest_WhenViewStarted_ThenCorrectEventsTracked() throws {
        interactor.gatherPaymentKeyReturnValue = .just("")
        interactor.paymentRequestLookupReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingPaymentRequestInfoFailed(
                error: .unknown(message: "")
            )
        )

        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(PayWithWiseViewModel.Empty.canned)

        let presenter = getPresenter(source: .paymentKey(.contact(paymentKey: "")))
        presenter.start(with: view)
    }
}

// MARK: - Top up

extension PayWithWisePresenterTests {
    func testTopUp_GivenSourceUnavailable_ThenMakeTopUpFlowInvoked() throws {
        let expectedAmount = Money.build(
            currency: .TRY,
            value: 1000
        )
        view.presentationRootViewController = UIViewController()
        interactor.gatherPaymentKeyReturnValue = .just("")
        interactor.paymentRequestLookupReturnValue = .just(
            PaymentRequestLookup.build(
                amount: expectedAmount,
                availablePaymentMethods: [
                    PayerAcquiringPaymentMethod.build(
                        type: .payWithWise,
                        value: ""
                    ),
                ]
            )
        )
        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingQuoteFailed(
                error: PayWithWisePaymentError.sourceUnavailable(
                    message: "No money"
                )
            )
        )
        viewModelFactory.makeAlertViewModelReturnValue = PayWithWiseViewModel.Alert.canned

        presenter.start(with: view)

        let action = try XCTUnwrap(
            viewModelFactory.makeAlertViewModelReceivedArguments?.action
        )

        action.handler()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .topUpTapped
        )

        XCTAssertTrue(
            router.showTopUpFlowCalled
        )
        XCTAssertEqual(
            router.showTopUpFlowReceivedArguments?.targetAmount,
            expectedAmount
        )
    }

    func testTopUp_WhenTopUpCompletedSuccessfully_ThenDataReloaded() throws {
        view.presentationRootViewController = UIViewController()
        interactor.gatherPaymentKeyReturnValue = .just("")
        interactor.paymentRequestLookupReturnValue = .just(
            PaymentRequestLookup.build(
                availablePaymentMethods: [
                    PayerAcquiringPaymentMethod.build(
                        type: .payWithWise,
                        value: ""
                    ),
                ]
            )
        )
        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingQuoteFailed(
                error: PayWithWisePaymentError.sourceUnavailable(
                    message: "No money"
                )
            )
        )
        viewModelFactory.makeAlertViewModelReturnValue = PayWithWiseViewModel.Alert.canned
        presenter.start(with: view)

        let action = try XCTUnwrap(
            viewModelFactory.makeAlertViewModelReceivedArguments?.action
        )
        action.handler()

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .topUpTapped
        )

        let showHudCallsCount = view.showHudCallsCount
        let balancesCallsCount = interactor.balancesCallsCount
        router.showTopUpFlowReceivedArguments?.completion(
            TopUpBalanceFlowResult.completed
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[3],
            .topUpCompleted(success: true)
        )

        XCTAssertEqual(view.showHudCallsCount, showHudCallsCount + 1)
        XCTAssertEqual(interactor.balancesCallsCount, balancesCallsCount + 1)
    }

    func testTopUp_WhenTopUpAborted_ThenCorrectEventsTriggered() throws {
        view.presentationRootViewController = UIViewController()
        interactor.gatherPaymentKeyReturnValue = .just("")
        interactor.paymentRequestLookupReturnValue = .just(
            PaymentRequestLookup.build(
                availablePaymentMethods: [
                    PayerAcquiringPaymentMethod.build(
                        type: .payWithWise,
                        value: ""
                    ),
                ]
            )
        )
        interactor.createPaymentReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingQuoteFailed(
                error: PayWithWisePaymentError.sourceUnavailable(
                    message: "No money"
                )
            )
        )
        viewModelFactory.makeAlertViewModelReturnValue = PayWithWiseViewModel.Alert.canned

        presenter.start(with: view)

        let action = try XCTUnwrap(
            viewModelFactory.makeAlertViewModelReceivedArguments?.action
        )
        action.handler()

        let showHudCallsCount = view.showHudCallsCount
        let balancesCallsCount = interactor.balancesCallsCount
        router.showTopUpFlowReceivedArguments?.completion(
            TopUpBalanceFlowResult.aborted
        )
        XCTAssertEqual(view.showHudCallsCount, showHudCallsCount)
        XCTAssertEqual(interactor.balancesCallsCount, balancesCallsCount)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[3],
            .topUpCompleted(success: false)
        )
    }
}

// MARK: - Helpers

private extension PayWithWisePresenterTests {
    func makePresenter(
        source: PayWithWiseFlow.PaymentInitializationSource = .canned,
        profile: Profile = FakePersonalProfileInfo().asProfile()
    ) {
        presenter = PayWithWisePresenterImpl(
            source: source,
            profile: profile,
            interactor: interactor,
            router: router,
            flowNavigationDelegate: flowNavigationDelegate,
            viewModelFactory: viewModelFactory,
            userProvider: userProvider,
            payWithWiseAnalyticsTracker: payWithWiseAnalyticsTracker,
            notificationCenter: notificationCenter,
            scheduler: .immediate
        )
    }

    func getPresenter(
        source: PayWithWiseFlow.PaymentInitializationSource = .canned,
        profile: Profile = FakePersonalProfileInfo().asProfile()
    ) -> PayWithWisePresenterImpl {
        PayWithWisePresenterImpl(
            source: source,
            profile: profile,
            interactor: interactor,
            router: router,
            flowNavigationDelegate: flowNavigationDelegate,
            viewModelFactory: viewModelFactory,
            userProvider: userProvider,
            payWithWiseAnalyticsTracker: payWithWiseAnalyticsTracker,
            notificationCenter: notificationCenter,
            scheduler: .immediate
        )
    }

    func makePaymentRequestLookup(
        id: PaymentRequestId = .canned,
        requester: PaymentRequestLookup.Requester = .canned,
        amount: Money = Money.canned,
        message: String = "",
        description: String = "",
        attachmentFiles: [PayerAttachmentFile] = [],
        availablePaymentMethods: [PayerAcquiringPaymentMethod] = [
            PayerAcquiringPaymentMethod.build(
                type: .payWithWise
            ),
        ]
    ) -> AnyPublisher<PaymentRequestLookup, PayWithWiseV2Error> {
        .just(
            PaymentRequestLookup.build(
                id: id,
                requester: requester,
                amount: amount,
                message: message,
                description: description,
                attachmentFiles: attachmentFiles,
                availablePaymentMethods: availablePaymentMethods
            )
        )
    }
}
