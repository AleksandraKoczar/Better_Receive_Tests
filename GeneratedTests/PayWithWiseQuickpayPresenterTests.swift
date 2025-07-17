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
    // MARK: - Test Data
    
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
    
    private let businessWisetag = "Nike"
    private let expectedAmount = Money.build(currency: .PLN, value: 10)
    
    private lazy var businessInfo = ContactSearch.build(
        contact: contact,
        isSelf: false,
        pageType: .business
    )
    
    private lazy var payerData = QuickpayPayerData(
        value: 10,
        currency: .PLN,
        description: nil,
        businessQuickpay: businessWisetag
    )
    
    // MARK: - System Under Test
    
    private var presenter: PayWithWiseQuickpayPresenterImpl!
    
    // MARK: - Test Dependencies
    
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
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        setupDependencies()
        presenter = makePresenter()
    }
    
    override func tearDown() {
        presenter = nil
        interactor = nil
        router = nil
        quickpayUseCase = nil
        flowNavigationDelegate = nil
        viewModelFactory = nil
        view = nil
        userProvider = nil
        analyticsTracker = nil
        payWithWiseAnalyticsTracker = nil
        notificationCenter = nil
        
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_createsPresenterWithCorrectDependencies() {
        XCTAssertNotNil(presenter)
        // Start the presenter with the view to trigger dependencies setup
        presenter.start(with: view)
        
        // Verify dependencies are used
        XCTAssertEqual(quickpayUseCase.createAcquiringPaymentCallsCount, 1)
        XCTAssertEqual(payWithWiseAnalyticsTracker.trackPayerScreenEventCallsCount, 2)
    }
    
    // MARK: - Lifecycle Tests
    
    func test_start_showsHudAndStartsLoadingPipeline() {
        // When
        presenter.start(with: view)
        
        // Then
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(quickpayUseCase.createAcquiringPaymentCallsCount, 1)
    }
    
    func test_dismiss_notifiesFlowNavigationDelegate() {
        // When
        presenter.dismiss()
        
        // Then
        XCTAssertEqual(flowNavigationDelegate.dismissedCallsCount, 1)
        XCTAssertEqual(flowNavigationDelegate.dismissedReceivedInvocations.first, .singlePagePayer)
    }
    
    // MARK: - Data Loading Tests
    
    func test_loadingPipeline_whenSuccessful_displaysCorrectViewModel() {
        // Given
        setupSuccessfulDataLoadingScenario()
        
        // When
        presenter.start(with: view)
        
        // Then
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(view.updateCallsCount, 1)
        XCTAssertEqual(payWithWiseAnalyticsTracker.trackPayerScreenEventCallsCount, 2)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[0], 
            .startedLoggedIn
        )
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[1],
            .started(context: .QuickPay(), paymentRequestType: .business, currency: .PLN)
        )
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations[1],
            .quoteCreated(success: true, requestCurrency: "PLN", paymentCurrency: "PLN", amount: 10.0)
        )
    }
    
    func test_loadingPipeline_whenPWWNotAvailable_showsErrorViewModel() {
        // Given
        let quickpayAcquiringPayment = QuickpayAcquiringPayment.build(
            id: acquiringPaymentKey.acquiringPaymentId,
            paymentSessionId: acquiringPaymentKey.clientSecret,
            amount: expectedAmount,
            description: nil,
            paymentMethods: [] // Empty payment methods
        )
        
        interactor.acquiringPaymentLookupReturnValue = .just(quickpayAcquiringPayment)
        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()
        viewModelFactory.makeAlertViewModelReturnValue = .build(
            viewModel: InlineAlertViewModel(message: L10n.PayWithWise.Payment.Error.Message.payWithWiseNotAvailable(
                expectedAmount.currency.value
            ))
        )
        
        // When
        presenter.start(with: view)
        
        // Then
        XCTAssertEqual(view.updateCallsCount, 1)
        XCTAssertEqual(payWithWiseAnalyticsTracker.trackPayerScreenEventCallsCount, 2)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[0],
            .startedLoggedIn
        )
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations[1],
            .started(context: .QuickPay(), paymentRequestType: .business, currency: .PLN)
        )
    }
    
    func test_loadingPipeline_whenBalancesFetchingFails_showsErrorViewModel() {
        // Given
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
        interactor.balancesReturnValue = Fail(error: PayWithWiseV2Error.fetchingBalancesFailed).eraseToAnyPublisher()
        
        viewModelFactory.makeAlertViewModelReturnValue = .build(
            viewModel: InlineAlertViewModel(message: L10n.PayWithWise.Payment.Error.Message.noOpenBalances(
                expectedAmount.currency.value
            ))
        )
        
        // When
        presenter.start(with: view)
        
        // Then
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(view.updateCallsCount, 1)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations.last,
            .errorOccurred(
                requestCurrency: "PLN", 
                isSameCurrency: false, 
                requestCurrencyBalanceExists: false, 
                requestCurrencyBalanceHasEnough: false, 
                errorCode: "Fetching Balances Failed", 
                errorMessage: nil
            )
        )
    }
    
    func test_loadingPipeline_whenQuoteCreationFails_showsErrorViewModel() {
        // Given
        let balance = Balance.build(
            id: .build(value: 123),
            availableAmount: 100,
            currency: .PLN
        )
        
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
        interactor.balancesReturnValue = .just(
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .build(balance: balance),
                fundableBalances: [balance],
                balances: [balance]
            )
        )
        interactor.createQuickpayQuoteReturnValue = Fail(error: PayWithWiseV2Error.fetchingQuoteFailed).eraseToAnyPublisher()
        
        // When
        presenter.start(with: view)
        
        // Then
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations.last,
            .quoteCreated(success: false, requestCurrency: "PLN", paymentCurrency: "PLN", amount: 10.0)
        )
    }
    
    // MARK: - Payment Action Tests
    
    func test_pay_whenSuccessful_delegatesPaymentFlowAndTracksAnalytics() {
        // Given
        setupSuccessfulDataLoadingScenario()
        interactor.payReturnValue = Just(()).setFailureType(to: PayWithWiseV2Error.self).eraseToAnyPublisher()
        
        // When
        presenter.start(with: view)
        viewModelFactory.makeQuickpayReceivedArguments?.actionButtonAction?()
        
        // Then
        XCTAssertEqual(interactor.payCallsCount, 1)
        XCTAssertEqual(router.showSuccessCallsCount, 1)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations.last,
            .payCompleted(
                requestCurrency: "PLN",
                paymentCurrency: "PLN",
                requestCurrencyBalanceExists: true,
                requestCurrencyBalanceHasEnough: true,
                isSameCurrency: true
            )
        )
    }
    
    func test_pay_whenFails_showsErrorAndTracksAnalytics() {
        // Given
        setupSuccessfulDataLoadingScenario()
        interactor.payReturnValue = Fail(error: PayWithWiseV2Error.paymentFailed).eraseToAnyPublisher()
        
        // When
        presenter.start(with: view)
        viewModelFactory.makeQuickpayReceivedArguments?.actionButtonAction?()
        
        // Then
        XCTAssertEqual(interactor.payCallsCount, 1)
        XCTAssertEqual(view.showErrorCallsCount, 1)
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackEventReceivedInvocations.last,
            .payFailed(
                paymentRequestId: "KEY",
                message: nil
            )
        )
    }
    
    // MARK: - Navigation Tests
    
    func test_showDetails_whenQuickpayLookupAvailable_showsDetailsScreen() {
        // Given
        setupSuccessfulDataLoadingScenario()
        
        // When
        presenter.start(with: view)
        presenter.showDetails()
        
        // Then
        XCTAssertEqual(router.showDetailsCallsCount, 1)
    }
    
    func test_showDetails_whenQuickpayLookupNotAvailable_doesNothing() {
        // Given - quickpayLookup is nil by default
        
        // When
        presenter.showDetails()
        
        // Then
        XCTAssertEqual(router.showDetailsCallsCount, 0)
    }
    
    func test_showAlternativePaymentMethods_showsPaymentMethodsBottomSheet() {
        // Given
        setupSuccessfulDataLoadingScenario()
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
            name: "CARD",
            summary: "CARD",
            available: true
        )
        
        let quickpayAcquiringPayment = QuickpayAcquiringPayment.build(
            id: acquiringPaymentKey.acquiringPaymentId,
            paymentSessionId: acquiringPaymentKey.clientSecret,
            amount: expectedAmount,
            description: nil,
            paymentMethods: [pwwPaymentMethod, cardPaymentMethod]
        )
        
        interactor.acquiringPaymentLookupReturnValue = .just(quickpayAcquiringPayment)
        
        // When
        presenter.start(with: view)
        viewModelFactory.makeQuickpayReceivedArguments?.secondButtonAction?()
        
        // Then
        XCTAssertEqual(router.showPaymentMethodsBottomSheetQuickpayCallsCount, 1)
        
        // Simulate selection of another payment method
        router.showPaymentMethodsBottomSheetQuickpayReceivedArguments?.completion(cardPaymentMethod)
        
        // Verify analytics tracking
        XCTAssertEqual(
            payWithWiseAnalyticsTracker.trackPayerScreenEventReceivedInvocations.last,
            .paymentMethodSelected(method: .Card())
        )
        XCTAssertEqual(router.showPaymentMethodQuickpayCallsCount, 1)
    }
    
    // MARK: - Helper Methods
    
    private func setupDependencies() {
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
        
        // Default setup
        quickpayUseCase.createAcquiringPaymentReturnValue = .just(acquiringPaymentKey)
        viewModelFactory.makeReturnValue = .loaded(.canned)
        viewModelFactory.makeHeaderViewModelReturnValue = PayWithWiseHeaderView.ViewModel.canned
    }
    
    private func setupSuccessfulDataLoadingScenario() {
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
                autoSelectionResult: .build(balance: balance),
                fundableBalances: [balance],
                balances: [balance]
            )
        )
        
        interactor.createQuickpayQuoteReturnValue = .just(
            PayWithWiseQuote.build(
                sourceAmount: expectedAmount,
                targetAmount: .build(currency: .PLN, value: 10.0)
            )
        )
        
        viewModelFactory.makeBalanceOptionsContainerReturnValue = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()
        
        viewModelFactory.makeQuickpayReturnValue = PayWithWiseViewModel.loaded(
            PayWithWiseViewModel.Loaded.build(
                header: PayWithWiseHeaderView.ViewModel.canned,
                primaryActionText: "Pay",
                secondaryActionText: "Pay another way",
                actionButtonAction: { },
                secondButtonAction: { }
            )
        )
    }
    
    private func makePresenter(
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
}
