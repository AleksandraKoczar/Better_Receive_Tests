import BalanceKit
import Combine
import CombineSchedulers
import ContactsKit
import ContactsKitTestingSupport
import Foundation
import Neptune
import Prism
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

final class PayWithWiseQuickpayPresenterTests: TWTestCase {
    private var profile = FakePersonalProfileInfo().asProfile()
    private var acquiringPaymentKey = QuickpayAcquiringPaymentKey.build(
        acquiringPaymentId: .init("KEY"),
        clientSecret: .build(id: "SECRET")
    )

    private var contact = Contact.build(
        id: Contact.Id.match("123", contactId: "100"),
        title: "Nike Business",
        subtitle: "subtitle",
        isVerified: true,
        isHighlighted: false,
        labels: [],
        hasAvatar: true,
        avatarPublisher: .canned,
        lastUsedDate: nil,
        nickname: "TaylorSwift"
    )

    private var businessWisetag = "Nike"

    private var businessInfo = ContactSearch.build(
        contact: Contact.build(
            id: Contact.Id.match("123", contactId: "100"),
            title: "Nike Business",
            subtitle: "subtitle",
            isVerified: true,
            isHighlighted: false,
            labels: [],
            hasAvatar: true,
            avatarPublisher: .canned,
            lastUsedDate: nil,
            nickname: "TaylorSwift"
        ),
        isSelf: false,
        pageType: .business
    )

    private var payerData = QuickpayPayerData(
        value: 10,
        currency: .PLN,
        description: nil,
        businessQuickpay: "Nike"
    )

    private var presenter: PayWithWiseQuickpayPresenterImpl!
    private var notificationCenter: MockNotificationCenter!
    private var interactor: PayWithWiseInteractorMock!
    private var router: PayWithWiseRouterMock!
    private var quickpayUseCase: QuickpayUseCaseMock!
    private var flowNavigationDelegate: PayWithWiseFlowNavigationDelegateMock!
    private var viewModelFactory: PayWithWiseViewModelFactoryMock!
    private var view: PayWithWiseViewMock!
    private var userProvider: StubUserProvider!
    private var analyticsTracker: QuickpayTrackingMock!
    private var payWithWiseAnalyticsTracker: PayWithWiseAnalyticsTrackerMock!

    override func setUp() {
        super.setUp()

        notificationCenter = MockNotificationCenter()
        interactor = PayWithWiseInteractorMock()
        router = PayWithWiseRouterMock()
        quickpayUseCase = QuickpayUseCaseMock()
        flowNavigationDelegate = PayWithWiseFlowNavigationDelegateMock()
        viewModelFactory = PayWithWiseViewModelFactoryMock()
        view = PayWithWiseViewMock()
        userProvider = StubUserProvider()
        analyticsTracker = QuickpayTrackingMock()
        payWithWiseAnalyticsTracker = PayWithWiseAnalyticsTrackerMock()
        viewModelFactory.makeReturnValue = .loaded(.canned)

        presenter = makePresenter()
    }

    override func tearDown() {
        presenter = nil
        interactor = nil
        router = nil
        viewModelFactory = nil
        userProvider = nil
        notificationCenter = nil
        view = nil

        super.tearDown()
    }
}

// MARK: Start pipeline

extension PayWithWiseQuickpayPresenterTests {
    func test_LoadingPipeline_thenReturnCorrectValues() {
        let expectedAmount = Money.build(currency: .PLN, value: 10)
        let pwwPaymentMethod = QuickpayAcquiringPayment.PaymentMethodAvailability.build(
            type: .payWithWise,
            urn: "",
            name: "PWW",
            summary: "",
            available: true
        )
        let quickpayAcquiringPayment = QuickpayAcquiringPayment.build(
            id: acquiringPaymentKey.acquiringPaymentId,
            paymentSessionId: acquiringPaymentKey.clientSecret,
            amount: expectedAmount,
            description: nil,
            paymentMethods: [pwwPaymentMethod]
        )

        let expectedBalanceId = BalanceId(123)
        let balance = Balance.build(
            id: expectedBalanceId,
            availableAmount: 100,
            currency: .PLN
        )
        let expectedTitle = "Ttl"

        interactor.acquiringPaymentLookupReturnValue = .just(quickpayAcquiringPayment)
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .build(
                    balance: balance
                ),
                fundableBalances: [balance],
                balances: [balance]
            )
        )

        interactor.createQuickpayQuoteReturnValue = .just(
            PayWithWiseQuote.build(sourceAmount: expectedAmount, targetAmount: .build(currency: .PLN, value: 10.0)))

        quickpayUseCase.createAcquiringPaymentReturnValue = .just(acquiringPaymentKey)

        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()

        viewModelFactory.makeQuickpayReturnValue = PayWithWiseViewModel.loaded(
            PayWithWiseViewModel.Loaded.build(
                header: PayWithWiseHeaderView.ViewModel(
                    title: .init(title: expectedTitle),
                    recipientName: "name",
                    description: "",
                    avatarImage: .canned
                )
            )
        )

        viewModelFactory.makeHeaderViewModelReturnValue = PayWithWiseHeaderView.ViewModel.canned

        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(
            interactor.acquiringPaymentLookupReceivedArguments?.acquiringPaymentId,
            acquiringPaymentKey.acquiringPaymentId
        )
        XCTAssertEqual(
            interactor.balancesReceivedArguments?.amount.value,
            expectedAmount.value
        )
        XCTAssertEqual(
            interactor.balancesReceivedArguments?.amount.currency,
            expectedAmount.currency
        )

        XCTAssertEqual(
            interactor.createQuickpayQuoteReceivedArguments?.session.id,
            acquiringPaymentKey.clientSecret.id
        )

        XCTAssertEqual(
            interactor.createQuickpayQuoteReceivedArguments?.profileId.value,
            profile.id.value
        )

        XCTAssertEqual(
            try view.configureReceivedViewModel?.loaded.header.title.title,
            expectedTitle
        )

        XCTAssertEqual(analyticsTracker.onBalanceAutoSelectedCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onBalanceAutoSelectedReceivedArguments?.currencyBalanceExists, true)
        XCTAssertEqual(analyticsTracker.onBalanceAutoSelectedReceivedArguments?.hasEnoughFunds, true)

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[0],
            .loaded(
                requestCurrency: "PLN",
                paymentCurrency: "PLN",
                isSameCurrency: true,
                requestCurrencyBalanceExists: true,
                requestCurrencyBalanceHasEnough: true,
                errorCode: nil,
                errorMessage: nil
            )
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .quoteCreated(success: true, requestCurrency: "PLN", paymentCurrency: "PLN", amount: 10.0)
        )
    }

    func test_loadingPipeline_givenPWWNotAvailable_thenShowErrorViewModel() {
        let expectedAmount = Money.build(currency: .PLN, value: 10)

        let quickpayAcquiringPayment = QuickpayAcquiringPayment.build(
            id: acquiringPaymentKey.acquiringPaymentId,
            paymentSessionId: acquiringPaymentKey.clientSecret,
            amount: expectedAmount,
            description: nil,
            paymentMethods: []
        )

        let expectedTitle = "Ttl"

        interactor.acquiringPaymentLookupReturnValue = .just(quickpayAcquiringPayment)
        quickpayUseCase.createAcquiringPaymentReturnValue = .just(.canned)

        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(PayWithWiseViewModel.Empty.build(title: expectedTitle))

        viewModelFactory.makeAlertViewModelReturnValue = .build(
            viewModel: InlineAlertViewModel(message: L10n.PayWithWise.Payment.Error.Message.noOpenBalances(
                expectedAmount.currency.value
            ))
        )

        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()

        viewModelFactory.makeQuickpayReturnValue = PayWithWiseViewModel.loaded(
            PayWithWiseViewModel.Loaded.build(
                header: PayWithWiseHeaderView.ViewModel(
                    title: .init(title: expectedTitle),
                    recipientName: "name",
                    description: "",
                    avatarImage: .canned
                )
            )
        )

        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeAlertViewModelReceivedArguments?.message,
            L10n.PayWithWise.Payment.Error.Message.payWithWiseNotAvailable
        )

        XCTAssertTrue(interactor.acquiringPaymentLookupCalled)

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[0],
            .loaded(
                requestCurrency: "PLN",
                paymentCurrency: "null",
                isSameCurrency: false,
                requestCurrencyBalanceExists: false,
                requestCurrencyBalanceHasEnough: false,
                errorCode: "Pay With Wise Not Available On Quickpay",
                errorMessage: "Pay With Wise is not available on this quickpay link"
            )
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[1],
            .started(context: .QuickPay(), paymentRequestType: .business, currency: .PLN)
        )
        XCTAssertEqual(payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[0], .startedLoggedIn)
    }

    func test_loadingPipeline_givenBalancesFetchingError_thenShowErrorViewModel() throws {
        let expectedAmount = Money.build(currency: .PLN, value: 10)
        let pwwPaymentMethod = QuickpayAcquiringPayment.PaymentMethodAvailability.build(
            type: .payWithWise,
            urn: "",
            name: "PWW",
            summary: "",
            available: true
        )
        let quickpayAcquiringPayment = QuickpayAcquiringPayment.build(
            id: acquiringPaymentKey.acquiringPaymentId,
            paymentSessionId: acquiringPaymentKey.clientSecret,
            amount: expectedAmount,
            description: nil,
            paymentMethods: [pwwPaymentMethod]
        )

        let expectedTitle = "Ttl"

        interactor.acquiringPaymentLookupReturnValue = .just(quickpayAcquiringPayment)

        interactor.balancesReturnValue = .fail(
            with: PayWithWiseV2Error.fetchingBalancesFailed(
                error: MockError.dummy
            )
        )

        quickpayUseCase.createAcquiringPaymentReturnValue = .just(.canned)

        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()

        viewModelFactory.makeAlertViewModelReturnValue = .build(
            viewModel: InlineAlertViewModel(message: L10n.PayWithWise.Payment.Error.Message.noOpenBalances(
                expectedAmount.currency.value
            ))
        )

        viewModelFactory.makeQuickpayReturnValue = PayWithWiseViewModel.loaded(
            PayWithWiseViewModel.Loaded.build(
                header: PayWithWiseHeaderView.ViewModel(
                    title: .init(title: expectedTitle),
                    recipientName: "name",
                    description: "",
                    avatarImage: .canned
                )
            )
        )

        viewModelFactory.makeEmptyStateViewModelReturnValue = .empty(PayWithWiseViewModel.Empty.build(title: expectedTitle))

        presenter.start(with: view)

        XCTAssertEqual(
            try view.configureReceivedViewModel?.empty.title,
            expectedTitle
        )

        XCTAssertTrue(interactor.acquiringPaymentLookupCalled)
        XCTAssertTrue(interactor.balancesCalled)
        XCTAssertFalse(interactor.createQuickpayQuoteCalled)

        XCTAssertEqual(analyticsTracker.onBalanceSelectedCallsCount, 0)

        XCTAssertEqual(payWithWiseAnalyticsTracker.trackEventReceivedInvocations[0], .loaded(
            requestCurrency: "PLN",
            paymentCurrency: "null",
            isSameCurrency: false,
            requestCurrencyBalanceExists: false,
            requestCurrencyBalanceHasEnough: false,
            errorCode: "Fetching Balances Failed",
            errorMessage: "Fetching Balanaces Failed"
        ))

        XCTAssertEqual(payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[0], .startedLoggedIn)
    }
}

// MARK: - Dismiss

extension PayWithWiseQuickpayPresenterTests {
    func testDismiss_WhenDismissCalled_ThenDelegateReceivedCorrectValue() {
        presenter.dismiss()
        XCTAssertEqual(flowNavigationDelegate.dismissedReceivedAt, .singlePagePayer)
    }
}

// MARK: - Eligibility

extension PayWithWiseQuickpayPresenterTests {
    func testEligibility_GivenEligibleBusinessProfile_ThenCorrectParametersPassed() {
        setupDependencies()

        let profileInfo = FakeBusinessProfileInfo()
        profileInfo.addPrivilege(TransferPrivilege.create)

        let presenter = makePresenter(profile: profileInfo.asProfile())
        presenter.start(with: view)

        XCTAssertNil(viewModelFactory.makeReceivedArguments?.inlineAlert)
    }

    func testEligibility_GivenIneligibleBusinessProfile_ThenCorrectAlertShows_andPaymentDisabled() {
        setupDependencies()

        let presenter = makePresenter(profile: FakeBusinessProfileInfo().asProfile())
        presenter.start(with: view)

        XCTAssertEqual(
            viewModelFactory.makeQuickpayReceivedArguments?.inlineAlert?.viewModel.message.text,
            L10n.PayWithWise.Payment.Error.Message.ineligible
        )
    }
}

// MARK: - Paying for acquiring payment

extension PayWithWiseQuickpayPresenterTests {
    func testPayment_GivenDefaultValues_ThenPayReceivedCorrectParameters() throws {
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

        let expectedTitle = "Ttl"

        let expectedAmount = Money.build(currency: .PLN, value: 10)
        let pwwPaymentMethod = QuickpayAcquiringPayment.PaymentMethodAvailability.build(
            type: .payWithWise,
            urn: "",
            name: "PWW",
            summary: "",
            available: true
        )
        let quickpayAcquiringPayment = QuickpayAcquiringPayment.build(
            id: acquiringPaymentKey.acquiringPaymentId,
            paymentSessionId: acquiringPaymentKey.clientSecret,
            amount: expectedAmount,
            description: nil,
            paymentMethods: [pwwPaymentMethod]
        )

        interactor.acquiringPaymentLookupReturnValue = .just(quickpayAcquiringPayment)

        interactor.createQuickpayQuoteReturnValue = .just(
            PayWithWiseQuote.build(sourceAmount: expectedAmount))

        interactor.payReturnValue = .just(
            PayWithWisePayment.build(
                resource: PayWithWisePayment.Resource.build(type: .transfer)
            )
        )

        quickpayUseCase.createAcquiringPaymentReturnValue = .just(.canned)

        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()

        viewModelFactory.makeQuickpayReturnValue = PayWithWiseViewModel.loaded(
            PayWithWiseViewModel.Loaded.build(
                header: PayWithWiseHeaderView.ViewModel(
                    title: .init(title: expectedTitle),
                    recipientName: "name",
                    description: "",
                    avatarImage: .canned
                )
            )
        )

        presenter.start(with: view)

        let showHudCallsCount = view.showHudCallsCount
        let hideHudCallsCount = view.hideHudCallsCount

        viewModelFactory.makeQuickpayReceivedArguments?.firstButtonAction()

        XCTAssertEqual(view.showHudCallsCount, showHudCallsCount + 1)
        XCTAssertEqual(view.hideHudCallsCount, hideHudCallsCount + 1)

        XCTAssertEqual(
            interactor.payReceivedArguments?.session.id,
            acquiringPaymentKey.clientSecret.id
        )
        XCTAssertEqual(
            interactor.payReceivedArguments?.profileId,
            profile.id
        )
        XCTAssertEqual(
            interactor.payReceivedArguments?.balanceId,
            expectedBalanceId
        )

        XCTAssertEqual(
            router.showSuccessReceivedViewModel?.title,
            "All done"
        )

        XCTAssertFalse(notificationCenter.postedNotifications.contains(.balancesNeedUpdate))
        XCTAssertFalse(notificationCenter.postedNotifications.contains(.needsActivityListUpdate))

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[3],
            .paySucceed(requestType: .QuickPay(), requestCurrency: "PLN", paymentCurrency: "TRY")
        )

        XCTAssertEqual(payWithWiseAnalyticsTracker.trackEventReceivedInvocations.count, 4)

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .payTapped(requestCurrency: "PLN", paymentCurrency: "TRY", profileType: .personal)
        )

        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedEvent,
            .paymentMethodSelected(method: .PayWithWise())
        )
    }

    func testPayment_GivenDefaultValues_ThenPayReceivedCorrectParameters_AndResourceIsNotTransfer() throws {
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

        let expectedTitle = "Ttl"
        let expectedAmount = Money.build(currency: .AUD, value: 10)
        let pwwPaymentMethod = QuickpayAcquiringPayment.PaymentMethodAvailability.build(
            type: .payWithWise,
            urn: "",
            name: "PWW",
            summary: "",
            available: true
        )
        let quickpayAcquiringPayment = QuickpayAcquiringPayment.build(
            id: acquiringPaymentKey.acquiringPaymentId,
            paymentSessionId: acquiringPaymentKey.clientSecret,
            amount: expectedAmount,
            description: nil,
            paymentMethods: [pwwPaymentMethod]
        )

        interactor.acquiringPaymentLookupReturnValue = .just(quickpayAcquiringPayment)

        interactor.createQuickpayQuoteReturnValue = .just(
            PayWithWiseQuote.build(sourceAmount: expectedAmount))

        interactor.payReturnValue = .just(
            PayWithWisePayment.build(
                resource: PayWithWisePayment.Resource.build(type: .other)
            )
        )

        quickpayUseCase.createAcquiringPaymentReturnValue = .just(.canned)

        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()

        viewModelFactory.makeQuickpayReturnValue = PayWithWiseViewModel.loaded(
            PayWithWiseViewModel.Loaded.build(
                header: PayWithWiseHeaderView.ViewModel(
                    title: .init(title: expectedTitle),
                    recipientName: "name",
                    description: nil,
                    avatarImage: .canned
                )
            )
        )

        presenter.start(with: view)

        let showHudCallsCount = view.showHudCallsCount
        let hideHudCallsCount = view.hideHudCallsCount

        viewModelFactory.makeQuickpayReceivedArguments?.firstButtonAction()

        XCTAssertEqual(view.showHudCallsCount, showHudCallsCount + 1)
        XCTAssertEqual(view.hideHudCallsCount, hideHudCallsCount + 1)

        XCTAssertEqual(
            interactor.payReceivedArguments?.session.id,
            acquiringPaymentKey.clientSecret.id
        )
        XCTAssertEqual(
            interactor.payReceivedArguments?.profileId,
            profile.id
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
}

// MARK: - Payment methods bottomsheet

extension PayWithWiseQuickpayPresenterTests {
    func testOpenPaymentMethodsBottomsheet_WhenSecondaryActionTriggered_AndSelectCard_ThenRouterReceivedCorrectNavigation() throws {
        let expectedAmount = Money.build(currency: .PLN, value: 10)
        let businessName = "Nike Business"

        let pwwPaymentMethod = QuickpayAcquiringPayment.PaymentMethodAvailability.build(
            type: .payWithWise,
            urn: "",
            name: "PWW",
            summary: "",
            available: true
        )

        let cardPaymentMethod = QuickpayAcquiringPayment.PaymentMethodAvailability.build(
            type: .card,
            urn: "",
            name: "Card",
            summary: "",
            available: true
        )

        let quickpayAcquiringPayment = QuickpayAcquiringPayment.build(
            id: acquiringPaymentKey.acquiringPaymentId,
            paymentSessionId: acquiringPaymentKey.clientSecret,
            amount: expectedAmount,
            description: nil,
            paymentMethods: [pwwPaymentMethod, cardPaymentMethod]
        )

        let expectedBalanceId = BalanceId(123)
        let balance = Balance.build(
            id: expectedBalanceId,
            availableAmount: 100,
            currency: .AUD
        )

        interactor.acquiringPaymentLookupReturnValue = .just(quickpayAcquiringPayment)
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .build(
                    balance: balance
                ),
                fundableBalances: [balance],
                balances: [balance]
            )
        )

        interactor.createQuickpayQuoteReturnValue = .just(
            PayWithWiseQuote.build(sourceAmount: expectedAmount))

        quickpayUseCase.createAcquiringPaymentReturnValue = .just(.canned)

        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()

        viewModelFactory.makeQuickpayReturnValue = PayWithWiseViewModel.loaded(
            PayWithWiseViewModel.Loaded.build(
                header: PayWithWiseHeaderView.ViewModel(
                    title: .init(title: businessName),
                    recipientName: "name",
                    description: "",
                    avatarImage: .canned
                )
            )
        )

        viewModelFactory.makeHeaderViewModelReturnValue = PayWithWiseHeaderView.ViewModel.canned

        presenter.start(with: view)

        viewModelFactory.makeQuickpayReceivedArguments?.secondButtonAction()

        XCTAssertEqual(router.showPaymentMethodsBottomSheetQuickpayCallsCount, 1)
        XCTAssertEqual(
            router.showPaymentMethodsBottomSheetQuickpayReceivedArguments?.businessName,
            businessName
        )
        XCTAssertEqual(
            router.showPaymentMethodsBottomSheetQuickpayReceivedArguments?.paymentMethods,
            [pwwPaymentMethod, cardPaymentMethod]
        )

        router.showPaymentMethodsBottomSheetQuickpayReceivedArguments?.completion(.build(
            type: .card,
            urn: "",
            name: "CARD",
            summary: "CARD",
            available: true
        ))

        XCTAssertEqual(payWithWiseAnalyticsTracker.trackEventReceivedInvocations.count, 3)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[2],
            .payAnotherWayTapped(
                requestCurrency: "PLN",
                requestCurrencyBalanceExists: false,
                requestCurrencyBalanceHasEnough: false
            )
        )
        XCTAssertEqual(payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedEvent, .paymentMethodSelected(method: .Card()))
    }
}

private extension PayWithWiseQuickpayPresenterTests {
    func makePresenter(
        profile: Profile = FakePersonalProfileInfo().asProfile()
    ) -> PayWithWiseQuickpayPresenterImpl {
        PayWithWiseQuickpayPresenterImpl(
            profile: profile,
            payerData: payerData,
            businessInfo: businessInfo,
            interactor: interactor,
            quickpayUseCase: quickpayUseCase,
            router: router,
            analyticsTracker: analyticsTracker,
            payWithWiseAnalyticsTracker: payWithWiseAnalyticsTracker,
            flowNavigationDelegate: flowNavigationDelegate,
            viewModelFactory: viewModelFactory,
            userProvider: userProvider,
            notificationCenter: notificationCenter,
            scheduler: .immediate
        )
    }

    func setupDependencies() {
        let expectedAmount = Money.build(currency: .PLN, value: 10)
        let pwwPaymentMethod = QuickpayAcquiringPayment.PaymentMethodAvailability.build(
            type: .payWithWise,
            urn: "",
            name: "PWW",
            summary: "",
            available: true
        )
        let quickpayAcquiringPayment = QuickpayAcquiringPayment.build(
            id: acquiringPaymentKey.acquiringPaymentId,
            paymentSessionId: acquiringPaymentKey.clientSecret,
            amount: expectedAmount,
            description: nil,
            paymentMethods: [pwwPaymentMethod]
        )

        let balance = Balance.build(
            id: .build(value: 123),
            availableAmount: 100,
            currency: .PLN
        )

        interactor.acquiringPaymentLookupReturnValue = .just(quickpayAcquiringPayment)
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .build(
                    balance: balance
                ),
                fundableBalances: [balance],
                balances: [balance]
            )
        )

        interactor.createQuickpayQuoteReturnValue = .just(
            PayWithWiseQuote.build(sourceAmount: expectedAmount, targetAmount: .build(currency: .PLN, value: 10.0)))

        quickpayUseCase.createAcquiringPaymentReturnValue = .just(acquiringPaymentKey)

        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()

        viewModelFactory.makeQuickpayReturnValue = PayWithWiseViewModel.loaded(
            .canned
        )
    }
}
