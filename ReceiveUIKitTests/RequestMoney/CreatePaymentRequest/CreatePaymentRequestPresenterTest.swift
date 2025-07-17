import AnalyticsKitTestingSupport
import ApiKit
@testable import BalanceKit
import Combine
import CombineSchedulers
import ContactsKit
import ContactsKitTestingSupport
import Foundation
@testable import Neptune
import PreloadKit
import Prism
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport
import WiseCore

@MainActor
final class CreatePaymentRequestPresenterTests: TWTestCase {
    private let businessProfile = Profile.business(FakeBusinessProfileInfo())
    private let paymentRequestEligibleBalance = PaymentRequestEligibleBalances.Balance.build(
        id: .init(123),
        currency: .NZD
    )
    private let eligibility = MCAEligibility(isEligible: true, accountType: .full)
    private let payerId = "beefblob-beef-blob-beef-blobbeefblob"

    private var presenter: CreatePaymentRequestPresenterImpl!
    private var view: CreatePaymentRequestViewMock!
    private var routingDelegate: CreatePaymentRequestRoutingDelegateMock!
    private var balanceManager: BalanceManagerMock!
    private var viewModelMapper: CreatePaymentRequestViewModelMapperMock!
    private var interactor: CreatePaymentRequestInteractorMock!
    private var eligibilityService: ReceiveEligibilityServiceMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var prismAnalyticsTracker: PaymentRequestTrackingMock!
    private var avatarFetcher: CancellableAvatarFetcherMock!
    private var featureService: StubFeatureService!

    override func setUp() {
        super.setUp()
        view = CreatePaymentRequestViewMock()
        interactor = CreatePaymentRequestInteractorMock()
        routingDelegate = CreatePaymentRequestRoutingDelegateMock()
        balanceManager = BalanceManagerMock()
        viewModelMapper = CreatePaymentRequestViewModelMapperMock()
        eligibilityService = ReceiveEligibilityServiceMock()
        eligibilityService.mcaEligibilityReturnValue = eligibility
        analyticsTracker = StubAnalyticsTracker()
        prismAnalyticsTracker = PaymentRequestTrackingMock()
        avatarFetcher = CancellableAvatarFetcherMock()
        featureService = StubFeatureService()

        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            )
        )

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(
            .build(currencies: [
                .build(
                    currency: .PLN,
                    available: true,
                    paymentMethods: [.canned],
                    availableBalances: [.canned]
                ),
            ])
        )

        presenter = makePresenter(
            requestType: .singleUse,
            profile: businessProfile,
            paymentRequestInfo: paymentRequestInfo
        )
    }

    override func tearDown() {
        presenter = nil
        view = nil
        routingDelegate = nil
        balanceManager = nil
        viewModelMapper = nil
        eligibilityService = nil
        analyticsTracker = nil
        avatarFetcher = nil
        featureService = nil
        interactor = nil

        super.tearDown()
    }

    // MARK: - Loading and Input Validation

    func test_dismiss() {
        presenter.dismiss()
        XCTAssertEqual(routingDelegate.dismissCallsCount, 1)
    }

    func test_start_givenBusinessProfile_andSingleAndReusableRequestEligibility_thenConfigureView() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.singleUse
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        presenter.start(with: view)

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        expectNoDifference(view.configureReceivedViewModel, viewModel)
    }

    func test_start_givenBusinessProfile_andSingleOnlyRequestEligibility_thenConfigureView() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: false)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUse
        let defaultRequestType = RequestType.singleUse
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))
        featureService.stub(value: false, for: ReceiveKitFeatures.reusablePaymentLinksEnabled)

        presenter.start(with: view)

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        expectNoDifference(view.configureReceivedViewModel, viewModel)
    }

    func test_start_givenBusinessProfile_thenConfigureView_withCheckboxDisabled() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: false)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.singleUse
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        presenter.start(with: view)

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        expectNoDifference(view.configureReceivedViewModel, viewModel)
    }

    func test_Validation_nilRequestValue() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUse
        let defaultRequestType = RequestType.singleUse
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))
        interactor.createPaymentRequestReturnValue = .just(.canned)

        presenter.start(with: view)
        presenter.moneyValueUpdated(nil)
        presenter.continueTapped(inputs: .canned)

        XCTAssertEqual(view.calculatorErrorCallsCount, 1)
        XCTAssertEqual(view.calculatorErrorReceivedErrorMsg, "Please enter an amount to request")
    }

    func test_Validation_SubZeroRequestValue() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.singleUse
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        presenter.start(with: view)
        presenter.moneyValueUpdated("-20")
        presenter.continueTapped(inputs: .canned)

        XCTAssertEqual(view.calculatorErrorCallsCount, 1)
        XCTAssertEqual(view.calculatorErrorReceivedErrorMsg, "Please enter an amount greater than 0")
    }

    func test_continueTapped_givenBusinessProfile_andIsIneligible_thenShowError() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .fail(with: GenericError("Profile is ineligible"))
        interactor.createPaymentRequestReturnValue = .just(.canned)

        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            )
        )
        presenter = makePresenter(
            requestType: .singleUse,
            profile: businessProfile,
            paymentRequestInfo: paymentRequestInfo
        )
        presenter.start(with: view)

        XCTAssertEqual(view.configureWithErrorCallsCount, 1)
        XCTAssertEqual(
            view.configureWithErrorReceivedErrorViewModel?.message,
            .text("We are working on the issue. Please try again later.")
        )
    }

    func test_checkbox_switchedFromReusableToSingle_AndTrackInAnalytics() throws {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            )
        )

        presenter = makePresenter(
            requestType: .singleUse,
            profile: businessProfile,
            paymentRequestInfo: paymentRequestInfo
        )
        presenter.start(with: view)
        presenter.togglePaymentLimit()

        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Create - Type Selection Changed")
        let tabName = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["Tab"] as? String)
        XCTAssertEqual(tabName, "SingleUse")
    }

    func test_moneyInputCurrencyTapped() throws {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        presenter.start(with: view)
        presenter.moneyInputCurrencyTapped()

        let receivedCurrency = paymentRequestEligibleBalance.currency
        XCTAssertEqual(routingDelegate.showCurrencySelectorCallsCount, 1)
        XCTAssertEqual(
            routingDelegate.showCurrencySelectorReceivedArguments?.activeCurrencies,
            [receivedCurrency]
        )

        let onCurrencySelected = try XCTUnwrap(
            routingDelegate.showCurrencySelectorReceivedArguments?.onCurrencySelected
        )
        onCurrencySelected(receivedCurrency)
        XCTAssertEqual(view.updateSelectedCurrencyCallsCount, 1)
        XCTAssertEqual(
            view.updateSelectedCurrencyReceivedCurrency,
            receivedCurrency
        )
    }

    func test_moneyValueUpdatedWithDecimal_GivenMethodManagementEnabled_thenUpdatePaymentMethodOption_AndFooter() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)
        presenter.moneyValueUpdated("10.5")

        XCTAssertEqual(view.footerButtonStateReceivedEnabled, true)
        XCTAssertEqual(view.updatePaymentMethodOptionCallsCount, 2)
    }
}

// MARK: - Get Paid With Card Nudge

extension CreatePaymentRequestPresenterTests {
    func test_shouldShowNudge_thenCorrectViewConfigured() throws {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))
        interactor.shouldShowNudgeReturnValue = true

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .card,
                        urn: "",
                        name: "",
                        summary: "",
                        available: false,
                        preferred: false,
                        unavailabilityReason: .requiresUserAction(dynamicForms: [.build(
                            flowId: "acquiringOnboardingConsentForm",
                            url: "url"
                        )]),
                        informationCollectionDynamicForms: [.build(flowId: "acquiringOnboardingConsentForm", url: "url")]
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)

        XCTAssertTrue(view.updateNudgeCalled)
        XCTAssertTrue(view.updateNudgeReceivedNudge.isNonNil)
        XCTAssertEqual(prismAnalyticsTracker.onCardSetupNudgeViewedCallsCount, 1)
    }

    func test_shouldNudgeSelected_thenDynamicFlowStarted() throws {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))
        interactor.shouldShowNudgeReturnValue = true

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .card,
                        urn: "",
                        name: "",
                        summary: "",
                        available: false,
                        preferred: false,
                        unavailabilityReason: .requiresUserAction(dynamicForms: [.build(
                            flowId: "acquiringOnboardingConsentForm",
                            url: "url"
                        )]),
                        informationCollectionDynamicForms: [.build(flowId: "acquiringOnboardingConsentForm", url: "url")]
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)

        let nudge = try XCTUnwrap(view.updateNudgeReceivedNudge)
        nudge.onSelect()

        XCTAssertEqual(prismAnalyticsTracker.onCardSetupNudgeOpenedCallsCount, 1)
        XCTAssertTrue(routingDelegate.showDynamicFormsMethodManagementCalled)
    }

    func test_shouldNudgeDismissed_thenCorrectViewConfigured() throws {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))
        interactor.shouldShowNudgeReturnValue = true

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .card,
                        urn: "",
                        name: "",
                        summary: "",
                        available: false,
                        preferred: false,
                        unavailabilityReason: .requiresUserAction(dynamicForms: [.build(
                            flowId: "acquiringOnboardingConsentForm",
                            url: "url"
                        )]),
                        informationCollectionDynamicForms: [.build(flowId: "acquiringOnboardingConsentForm", url: "url")]
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)

        let nudge = try XCTUnwrap(view.updateNudgeReceivedNudge)
        nudge.onDismiss!()

        XCTAssertEqual(prismAnalyticsTracker.onCardSetupNudgeDismissCallsCount, 1)
        XCTAssertTrue(view.updateNudgeReceivedNudge.isNil)
    }
}

// MARK: - Payment Method Management

extension CreatePaymentRequestPresenterTests {
    func test_updatePaymentMethodOption_whenViewLoads() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)

        XCTAssertEqual(view.updatePaymentMethodOptionCallsCount, 1)
        XCTAssertEqual(view.footerButtonStateReceivedEnabled, false)
    }

    func test_updatePaymentMethodOption_whenAmountChanged() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)
        presenter.moneyValueUpdated("10")

        XCTAssertEqual(view.updatePaymentMethodOptionCallsCount, 2)
        XCTAssertEqual(view.footerButtonStateReceivedEnabled, true)
    }

    func test_updatePaymentMethodOption_whenCurrencyChanged() throws {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)
        presenter.moneyInputCurrencyTapped()

        let onCurrencySelected = try XCTUnwrap(
            routingDelegate.showCurrencySelectorReceivedArguments?.onCurrencySelected
        )
        onCurrencySelected(.NZD)

        XCTAssertEqual(view.updatePaymentMethodOptionCallsCount, 2)
        XCTAssertEqual(view.footerButtonStateReceivedEnabled, false)
    }

    func testPaymentOptionTapped_thenShowBottomsheet() throws {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)

        let option = try XCTUnwrap(
            view?.updatePaymentMethodOptionReceivedOption
        )

        option.onTap()

        XCTAssertEqual(routingDelegate.showPaymentMethodsSheetCallsCount, 1)

        XCTAssertEqual(prismAnalyticsTracker.onPaymentMethodsOpenedCallsCount, 1)
        XCTAssertEqual(prismAnalyticsTracker.onPaymentMethodsOpenedReceivedArguments?.methodsSelected, [.payWithWise])
    }

    func test_refreshPaymentMethods_whenMethodIsDeselected() throws {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                    .build(
                        type: .card,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)

        let option = try XCTUnwrap(
            view?.updatePaymentMethodOptionReceivedOption
        )

        option.onTap()

        let newPreferences: [PaymentRequestV2PaymentMethods] = [.payWithWise]

        routingDelegate.showPaymentMethodsSheetReceivedArguments?.completion(
            newPreferences
        )

        XCTAssertEqual(prismAnalyticsTracker.onPaymentMethodsOpenedCallsCount, 1)
        XCTAssertEqual(prismAnalyticsTracker.onPaymentMethodsOpenedReceivedArguments?.methodsSelected, [.payWithWise, .card])

        XCTAssertEqual(prismAnalyticsTracker.onPaymentMethodsClosedReceivedArguments?.methodsSelected, [.payWithWise])

        XCTAssertEqual(prismAnalyticsTracker.onPaymentMethodsClosedReceivedArguments?.result, .success)

        XCTAssertEqual(routingDelegate.showPaymentMethodsSheetCallsCount, 1)
        XCTAssertEqual(view.updatePaymentMethodOptionCallsCount, 2)
    }

    func test_isFirstLoad_ThenRemotePreferencesAreLocalPreferences() throws {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                    .build(
                        type: .card,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)

        let option = try XCTUnwrap(
            view?.updatePaymentMethodOptionReceivedOption
        )

        option.onTap()

        XCTAssertEqual(routingDelegate.showPaymentMethodsSheetReceivedArguments?.localPreferences, [.payWithWise, .card])
        XCTAssertEqual(view.updatePaymentMethodOptionCallsCount, 1)
    }

    func test_cardBecamesDisabledOnCurrencyChange_thenChangeLocalPreferences() throws {
        let paymentRequestEligibleBalances = [
            PaymentRequestEligibleBalances.Balance.build(
                id: .init(123),
                currency: .NZD
            ),
            PaymentRequestEligibleBalances.Balance.build(
                id: .init(123),
                currency: .AUD
            ),
        ]
        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: paymentRequestEligibleBalances
            )
        )
        presenter = makePresenter(
            requestType: .singleUse,
            profile: businessProfile,
            paymentRequestInfo: paymentRequestInfo
        )

        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .NZD,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                    .build(
                        type: .card,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)

        let availableMethods2 = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .NZD,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                    .build(
                        type: .card,
                        urn: "",
                        name: "",
                        summary: "",
                        available: false,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods2)

        presenter.moneyInputCurrencyTapped()

        let onCurrencySelected = try XCTUnwrap(
            routingDelegate.showCurrencySelectorReceivedArguments?.onCurrencySelected
        )
        onCurrencySelected(.AUD)

        let option = try XCTUnwrap(
            view?.updatePaymentMethodOptionReceivedOption
        )

        option.onTap()

        XCTAssertEqual(routingDelegate.showPaymentMethodsSheetReceivedArguments?.localPreferences, [.payWithWise])
    }

    func test_refreshPaymentMethods_whenWebviewClosed() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))

        let availableMethods = PaymentRequestV2ReceiverAvailability.build(currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .PLN,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "",
                        name: "",
                        summary: "",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

        interactor.fetchReceiverCurrencyAvailabilityReturnValue = .just(availableMethods)

        presenter.start(with: view)
        presenter.refreshPaymentMethods()

        XCTAssertEqual(view.updatePaymentMethodOptionCallsCount, 2)
    }
}

// MARK: - Account details activation

extension CreatePaymentRequestPresenterTests {
    func testCurrencySelector_GivenEligibilities_ThenRouterReceivedTheCorrectCurrencies() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))
        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [
                    paymentRequestEligibleBalance,
                    .build(currency: .AED),
                ],
                eligibilities: [
                    PaymentRequestEligibleBalances.Eligibility.build(
                        currency: .USD,
                        eligibleForBalance: true,
                        eligibleForAccountDetails: true
                    ),
                    .build(
                        currency: .AUD,
                        eligibleForBalance: true,
                        eligibleForAccountDetails: false
                    ),
                ]
            )
        )
        presenter = makePresenter(
            requestType: .singleUse,
            profile: businessProfile,
            paymentRequestInfo: paymentRequestInfo
        )

        presenter.start(with: view)
        presenter.moneyInputCurrencyTapped()

        XCTAssertEqual(
            routingDelegate.showCurrencySelectorReceivedArguments?.activeCurrencies,
            [
                .AED,
                .NZD,
            ]
        )
        XCTAssertEqual(
            routingDelegate.showCurrencySelectorReceivedArguments?.eligibleCurrencies,
            [
                .USD,
                .AUD,
            ]
        )
    }

    func testCurrencySelection_GivenAccountDetailsEligibleCurrency_ThenActivateBalance_AndAccountDetails() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))
        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [
                    paymentRequestEligibleBalance,
                ],
                eligibilities: [
                    PaymentRequestEligibleBalances.Eligibility.build(
                        currency: .USD,
                        eligibleForBalance: true,
                        eligibleForAccountDetails: true
                    ),
                    .build(
                        currency: .AUD,
                        eligibleForBalance: true,
                        eligibleForAccountDetails: false
                    ),
                ]
            )
        )
        interactor.fetchEligibleBalancesReturnValue = .just(
            PaymentRequestEligibleBalances.build(
                balances: [
                    PaymentRequestEligibleBalances.Balance.build(
                        currency: .USD
                    ),
                ]
            )
        )
        presenter = makePresenter(
            requestType: .singleUse,
            profile: businessProfile,
            paymentRequestInfo: paymentRequestInfo
        )
        let accountdetailsSubject = PassthroughSubject<Void, Never>()
        routingDelegate.showAccountDetailsFlowReturnValue = accountdetailsSubject.eraseToAnyPublisher()

        presenter.start(with: view)
        presenter.moneyInputCurrencyTapped()
        routingDelegate.showCurrencySelectorReceivedArguments?.onCurrencySelected(.USD)
        XCTAssertEqual(
            balanceManager.activateReceivedArguments?.balance.currency, .USD
        )
        balanceManager.activateReceivedArguments?.completion(
            .success(
                Balance.build(
                    id: .build(value: 123),
                    currency: .USD
                )
            )
        )
        XCTAssertFalse(
            interactor.fetchEligibleBalancesCalled
        )
        XCTAssertEqual(routingDelegate.showAccountDetailsFlowReceivedCurrencyCode, .USD)
        accountdetailsSubject.send(())
        XCTAssertTrue(
            interactor.fetchEligibleBalancesCalled
        )
        XCTAssertEqual(view.updateSelectedCurrencyReceivedCurrency, .USD)
    }

    func testCurrencySelection_GivenBalanceEligibleCurrency_ThenBalanceActivatedForCurrency() {
        let viewModel = makeViewModelForBusinessProfile(shouldShowCheckbox: true)
        viewModelMapper.makeReturnValue = viewModel
        let eligibility = RequestMoneyProductEligibility.singleUseAndReusable
        let defaultRequestType = RequestType.reusable
        interactor.fetchEligibilityAndDefaultRequestTypeReturnValue = .just((eligibility, defaultRequestType))
        viewModelMapper.makeReturnValue = viewModel
        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [
                    paymentRequestEligibleBalance,
                ],
                eligibilities: [
                    PaymentRequestEligibleBalances.Eligibility.build(
                        currency: .USD,
                        eligibleForBalance: true,
                        eligibleForAccountDetails: true
                    ),
                    .build(
                        currency: .AUD,
                        eligibleForBalance: true,
                        eligibleForAccountDetails: false
                    ),
                ]
            )
        )
        interactor.fetchEligibleBalancesReturnValue = .just(
            PaymentRequestEligibleBalances.build(
                balances: [
                    PaymentRequestEligibleBalances.Balance.build(
                        currency: .AUD
                    ),
                ]
            )
        )
        presenter = makePresenter(
            requestType: .singleUse,
            profile: businessProfile,
            paymentRequestInfo: paymentRequestInfo
        )

        presenter.start(with: view)
        presenter.moneyInputCurrencyTapped()

        routingDelegate.showCurrencySelectorReceivedArguments?.onCurrencySelected(.AUD)
        XCTAssertEqual(
            balanceManager.activateReceivedArguments?.balance.currency, .AUD
        )
        balanceManager.activateReceivedArguments?.completion(
            .success(
                Balance.build(
                    id: .build(value: 123),
                    currency: .AUD
                )
            )
        )
        XCTAssertTrue(view.showHudCalled)
        XCTAssertTrue(view.hideHudCalled)
        XCTAssertTrue(
            interactor.fetchEligibleBalancesCalled
        )
        XCTAssertEqual(view.updateSelectedCurrencyReceivedCurrency, .AUD)
    }
}

// MARK: - Helpers

private extension CreatePaymentRequestPresenterTests {
    func makePresenter(
        requestType: RequestType,
        profile: Profile,
        paymentRequestInfo: CreatePaymentRequestPresenterInfo
    ) -> CreatePaymentRequestPresenterImpl {
        CreatePaymentRequestPresenterImpl(
            interactor: interactor,
            balanceManager: balanceManager,
            viewModelMapper: viewModelMapper,
            profile: profile,
            paymentRequestInfo: paymentRequestInfo,
            featureService: featureService,
            routingDelegate: routingDelegate,
            analyticsTracker: analyticsTracker,
            prismAnalyticsTracker: prismAnalyticsTracker,
            scheduler: .immediate
        )
    }

    func makePaymentRequest(
        amount: Decimal,
        paymemtMethods: [PaymentMethodTypeV2] = [.card]
    ) -> PaymentRequestV2 {
        PaymentRequestV2.build(
            amount: .build(
                currency: paymentRequestEligibleBalance.currency,
                value: amount
            ),
            balanceId: paymentRequestEligibleBalance.id,
            creator: .canned,
            selectedPaymentMethods: paymemtMethods
        )
    }

    func makePaymentRequestUpdateSingleUse(
        amount: Decimal,
        paymentRequestId: PaymentRequestId? = nil,
        paymemtMethods: [AcquiringPaymentMethodType] = [.card],
        payer: PaymentRequestSingleUseBody.Payer? = nil
    ) -> PaymentRequestBodyV2 {
        let body = PaymentRequestSingleUseBody.build(
            requestType: "SINGLE_USE",
            balanceId: paymentRequestEligibleBalance.id.value,
            selectedPaymentMethods: CreatePaymentRequestPaymentMethodMapper.mapPaymentMethod(types: paymemtMethods),
            amountValue: amount,
            description: .canned,
            message: .canned,
            payer: payer
        )
        return PaymentRequestBodyV2.singleUse(body)
    }

    func makePaymentRequestUpdateReusable(
        amount: Decimal,
        paymentRequestId: PaymentRequestId? = nil,
        paymemtMethods: [AcquiringPaymentMethodType] = [.card],
        payer: PaymentRequestSingleUseBody.Payer? = nil
    ) -> PaymentRequestBodyV2 {
        let body = PaymentRequestReusableBody.build(
            requestType: "REUSABLE",
            balanceId: paymentRequestEligibleBalance.id.value,
            selectedPaymentMethods: CreatePaymentRequestPaymentMethodMapper.mapPaymentMethod(types: paymemtMethods),
            amountValue: amount,
            description: nil
        )

        return PaymentRequestBodyV2.reusable(body)
    }

    func makeViewModelForBusinessProfile(shouldShowCheckbox: Bool) -> CreatePaymentRequestViewModel {
        CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: true,
            shouldShowPaymentLimitsCheckbox: shouldShowCheckbox,
            isLimitPaymentsSelected: false,
            productDescription: nil,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: ._icon(Icons.fastFlag.image, badge: nil)),
                onTap: {}
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        )
    }
}
