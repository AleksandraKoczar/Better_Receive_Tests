import AnalyticsKitTestingSupport
import ApiKit
@testable import BalanceKit
import Combine
import CombineSchedulers
import ContactsKit
import ContactsKitTestingSupport
import Foundation
import Neptune
import PreloadKit
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
final class CreatePaymentRequestPersonalPresenterTests: TWTestCase {
    private let personalProfile = Profile.personal(FakePersonalProfileInfo())
    private let paymentRequestEligibleBalance = PaymentRequestEligibleBalances.Balance.build(
        id: .init(123),
        currency: .NZD
    )
    private let eligibility = MCAEligibility(isEligible: true, accountType: .full)
    private let payerId = "beefblob-beef-blob-beef-blobbeefblob"
    private let payerName = LoremIpsum.short

    private var presenter: CreatePaymentRequestPersonalPresenter!
    private var view: CreatePaymentRequestPersonalViewMock!
    private var routingDelegate: CreatePaymentRequestPersonalRoutingDelegateMock!
    private var paymentRequestUseCase: PaymentRequestUseCaseV2Mock!
    private var paymentMethodsUseCase: PaymentMethodsUseCaseMock!
    private var payWithWiseNudgePreferenceUseCase: PayWithWiseNudgePreferenceUseCaseMock!
    private var paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCaseMock!
    private var viewModelMapper: CreatePaymentRequestPersonalViewModelMapperMock!
    private var eligibilityService: ReceiveEligibilityServiceMock!
    private var avatarFetcher: CancellableAvatarFetcherMock!
    private var balanceManager: BalanceManagerMock!

    override func setUp() {
        super.setUp()
        view = CreatePaymentRequestPersonalViewMock()
        routingDelegate = CreatePaymentRequestPersonalRoutingDelegateMock()
        paymentRequestUseCase = PaymentRequestUseCaseV2Mock()
        paymentMethodsUseCase = PaymentMethodsUseCaseMock()
        payWithWiseNudgePreferenceUseCase = PayWithWiseNudgePreferenceUseCaseMock()
        payWithWiseNudgePreferenceUseCase.payWithWiseNudgeShouldShowReturnValue = false
        paymentRequestEligibilityUseCase = PaymentRequestEligibilityUseCaseMock()
        viewModelMapper = CreatePaymentRequestPersonalViewModelMapperMock()
        eligibilityService = ReceiveEligibilityServiceMock()
        eligibilityService.mcaEligibilityReturnValue = eligibility
        avatarFetcher = CancellableAvatarFetcherMock()
        balanceManager = BalanceManagerMock()

        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            ),
            contact: nil
        )
        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )
    }

    override func tearDown() {
        presenter = nil
        view = nil
        routingDelegate = nil
        paymentRequestUseCase = nil
        paymentMethodsUseCase = nil
        viewModelMapper = nil
        eligibilityService = nil
        avatarFetcher = nil
        payWithWiseNudgePreferenceUseCase = nil
        paymentRequestEligibilityUseCase = nil

        super.tearDown()
    }

    func test_dismiss() {
        presenter.dismiss()

        XCTAssertEqual(routingDelegate.dismissCallsCount, 1)
    }

    func test_start_givenPersonalProfile_thenConfigureView() {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)

        payWithWiseNudgePreferenceUseCase.payWithWiseNudgeShouldShowReturnValue = true
        let avatarModel = AvatarModel.icon(
            Icons.giftBox.image,
            badge: nil
        )
        avatarFetcher.fetchClosure = { _, completion in
            completion(avatarModel)
        }
        let viewModel = makeViewModelForPersonalProfile()
        viewModelMapper.makeReturnValue = viewModel
        var paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: PaymentRequestEligibleBalances.Balance.build(
                currency: .NZD
            ),
            eligibleBalances: .build(
                balances: [
                    PaymentRequestEligibleBalances.Balance.build(
                        currency: .NZD
                    ),
                ]
            ),
            contact: RequestMoneyContact.build(
                title: "Jane Doe",
                subtitle: "Wise acc",
                hasRequestCapability: true,
                avatarPublisher: AvatarPublisher.icon(
                    avatarPublisher: .just(
                        avatarModel
                    ),
                    gradientPublisher: .canned,
                    path: .canned
                )
            )
        )
        paymentRequestInfo.value = 0.07
        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )

        presenter.start(with: view)

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        expectNoDifference(view.configureReceivedViewModel, viewModel)
        let expectedContactListItemViewModel = OptionViewModel(
            title: "Jane Doe",
            subtitle: "Wise acc",
            avatar: AvatarViewModel.icon(
                Icons.giftBox.image,
                badge: nil
            )
        )
        expectNoDifference(view.configureContactReceivedViewModel, expectedContactListItemViewModel)
    }

    func test_nudgeSelected() {
        presenter.nudgeSelected()

        XCTAssertEqual(routingDelegate.showPayWithWiseEducationCallsCount, 1)
    }

    func test_nudgeCloseTapped() throws {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        payWithWiseNudgePreferenceUseCase.payWithWiseNudgeShouldShowReturnValue = true
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        presenter.start(with: view)

        presenter.nudgeCloseTapped()

        XCTAssertEqual(payWithWiseNudgePreferenceUseCase.payWithWiseNudgeShouldShowCallsCount, 1)
        XCTAssertEqual(payWithWiseNudgePreferenceUseCase.setPayWithWiseNudgePreferenceCallsCount, 1)
        let arguments = try XCTUnwrap(payWithWiseNudgePreferenceUseCase.setPayWithWiseNudgePreferenceReceivedArguments)
        XCTAssertFalse(arguments.shouldShow)
        XCTAssertEqual(view.hideNudgeCallsCount, 1)
    }

    func test_Validation_nilRequestValue() {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        presenter.start(with: view)
        presenter.moneyValueUpdated(nil)

        presenter.sendRequestTapped(note: "abc")

        XCTAssertEqual(view.calculatorErrorCallsCount, 1)
        XCTAssertEqual(view.calculatorErrorReceivedErrorMsg, "Please enter an amount to request")
    }

    func test_Validation_SubZeroRequestValue() {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        presenter.start(with: view)
        presenter.moneyValueUpdated("-20")
        presenter.sendRequestTapped(note: "abc")

        XCTAssertEqual(view.calculatorErrorCallsCount, 1)
        XCTAssertEqual(view.calculatorErrorReceivedErrorMsg, "Please enter an amount greater than 0")
    }

    func test_continueTapped_givenPersonalProfile_andRequestFromContact_andNoPayWiseWiseAvailability_thenShowError() {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .card),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)

        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            ),
            contact: RequestMoneyContact.build(hasRequestCapability: true)
        )
        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        presenter.start(with: view)
        let value: Decimal = 20
        presenter.moneyValueUpdated(value.description)
        presenter.sendRequestTapped(note: "abc")

        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
        XCTAssertEqual(
            view.showDismissableAlertReceivedArguments?.message,
            L10n.PaymentRequest.Create.PaymentMethodSelection.Error.Message.payWithWiseNotFound
        )
    }

    func test_PWWUnavailable_BecauseOfRequiresUserAction_thenShowAlert() {
        let summary = LoremIpsum.medium
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(
                    type: .payWithWise,
                    summary: summary
                ),
                availability: .requiresUserAction(dynamicForms: [])
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)

        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            ),
            contact: RequestMoneyContact.build(hasRequestCapability: true)
        )
        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )

        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfileWithWarningAlert()

        presenter.start(with: view)

        let alert = CreatePaymentRequestPersonalViewModel.Alert(
            style: .warning,
            viewModel: Neptune.InlineAlertViewModel(
                message: "requires action"
            )
        )

        XCTAssertEqual(view.configureReceivedViewModel?.alert, alert)
        XCTAssertEqual(view.configureReceivedViewModel?.footerButtonEnabled, false)
    }

    func test_PWWUnavailable_BecauseOfPendingVerification_thenShowAlert() {
        let summary = LoremIpsum.medium
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(
                    type: .payWithWise,
                    summary: summary
                ),
                availability: .pendingVerification
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)

        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            ),
            contact: RequestMoneyContact.build(hasRequestCapability: true)
        )
        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )

        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfileWithAlert()

        presenter.start(with: view)

        let alert = CreatePaymentRequestPersonalViewModel.Alert(
            style: .neutral,
            viewModel: Neptune.InlineAlertViewModel(
                message: "pending verification"
            )
        )

        XCTAssertEqual(view.configureReceivedViewModel?.alert, alert)
        XCTAssertEqual(view.configureReceivedViewModel?.footerButtonEnabled, false)
    }

    func test_IsRequestFromContact_andPayWiseWiseIsUnavailable_thenShowError() {
        let summary = "There is no available payment method for creating a payment request."
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(
                    type: .payWithWise,
                    summary: summary
                ),
                availability: .unavailable
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)

        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            ),
            contact: RequestMoneyContact.build(hasRequestCapability: true)
        )
        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        presenter.start(with: view)

        XCTAssertEqual(view.configureWithErrorCallsCount, 1)
    }

    func test_continueTapped_givenPersonalProfile_andRequestFromContact_andPayWiseWiseIsAvailability_andCreationSucceeds_thenShowRequestFromContactSuccess() throws {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        let value: Decimal = 20
        let paymentRequest = makePaymentRequest(amount: value)
        paymentRequestUseCase.createPaymentRequestReturnValue = .just(paymentRequest)

        let contactId = LoremIpsum.veryShort
        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            ),
            contact: RequestMoneyContact.build(
                id: contactId,
                hasRequestCapability: true
            )
        )
        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        presenter.start(with: view)
        presenter.moneyValueUpdated(value.description)
        presenter.sendRequestTapped(note: "abc")

        let expectedPaymentRequestUpdate = makePaymentRequestUpdate(
            amount: value,
            paymemtMethods: [.payWithWise],
            payer: PaymentRequestSingleUseBody.Payer.build(contactId: contactId, name: "", address: nil)
        )

        let arguments = try XCTUnwrap(paymentRequestUseCase.createPaymentRequestReceivedArguments)
        XCTAssertEqual(arguments.body, .singleUse(expectedPaymentRequestUpdate))

        XCTAssertEqual(routingDelegate.showRequestFromContactsSuccessCallsCount, 1)
        XCTAssertEqual(
            routingDelegate.showRequestFromContactsSuccessReceivedArguments?.paymentRequest,
            paymentRequest
        )
    }

    func test_continueTapped_givenPersonalProfile_andNoAvailablePaymentMethod_thenShowError() {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .bankTransfer),
                availability: .unavailable
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)

        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            ),
            contact: nil
        )
        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        presenter.start(with: view)
        let value: Decimal = 20
        presenter.moneyValueUpdated(value.description)
        presenter.sendRequestTapped(note: "abc")

        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
        XCTAssertEqual(
            view.showDismissableAlertReceivedArguments?.message,
            "Pay with Wise payment method is not available for request a payment from a contact."
        )
    }

    func test_continueTapped_givenPersonalProfile_andServiceError_thenShowError() {
        let expectedMessage = "Msg"
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .fail(
            with: ReceiveError.customError(code: "", message: expectedMessage)
        )

        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            ),
            contact: nil
        )
        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        presenter.start(with: view)
        let value: Decimal = 20
        presenter.moneyValueUpdated(value.description)
        presenter.sendRequestTapped(note: "abc")

        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
        XCTAssertEqual(
            view.showDismissableAlertReceivedArguments?.message,
            expectedMessage
        )
    }

    func test_continueTapped_givenPersonalProfile_andHasAvailablePaymentMethod_andCreationSucceeds_thenShowConfirmation() throws {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        let value: Decimal = 20
        let paymentRequest = makePaymentRequest(amount: value)
        paymentRequestUseCase.createPaymentRequestReturnValue = .just(paymentRequest)

        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: paymentRequestEligibleBalance,
            eligibleBalances: .build(
                balances: [paymentRequestEligibleBalance]
            ),
            contact: nil
        )

        presenter = makePresenter(
            profile: personalProfile,
            paymentRequestInfo: paymentRequestInfo
        )
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        presenter.start(with: view)
        presenter.moneyValueUpdated(value.description)
        presenter.sendRequestTapped(note: "abc")

        let expectedPaymentRequestUpdate = makePaymentRequestUpdateNoPayer(
            amount: value,
            paymemtMethods: [.payWithWise]
        )

        let arguments = try XCTUnwrap(paymentRequestUseCase.createPaymentRequestReceivedArguments)
        XCTAssertEqual(arguments.body, .singleUse(expectedPaymentRequestUpdate))

        XCTAssertEqual(routingDelegate.showConfirmationCallsCount, 1)
        XCTAssertEqual(
            routingDelegate.showConfirmationReceivedPaymentRequest,
            paymentRequest
        )
    }

    func test_moneyInputCurrencyTapped() throws {
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
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

    func test_isValidPersonalMessage_givenMessageIsValid_thenDismissMessageError() {
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        presenter.start(with: view)

        let result = presenter.isValidPersonalMessage(LoremIpsum.short)

        XCTAssertTrue(result)
        XCTAssertEqual(view.dismissMessageInputErrorCallsCount, 1)
    }

    func test_isValidPersonalMessage_givenMessageIsTooLong_thenShowMessageError() {
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        presenter.start(with: view)

        let result = presenter.isValidPersonalMessage(LoremIpsum.veryLong)

        XCTAssertFalse(result)
        XCTAssertEqual(view.showMessageInputErrorCallsCount, 1)
        XCTAssertEqual(view.showMessageInputErrorReceivedErrorMessage, "Enter a note that’s under 41 characters.")
    }

    func test_isValidPersonalMessage_givenMessageIsTooLong_thenMessageBecomeValid_thenShowMessageErrorFirst_andDismissMessageError() {
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        presenter.start(with: view)

        var result = presenter.isValidPersonalMessage(LoremIpsum.veryLong)

        XCTAssertFalse(result)
        XCTAssertEqual(view.showMessageInputErrorCallsCount, 1)
        XCTAssertEqual(view.showMessageInputErrorReceivedErrorMessage, "Enter a note that’s under 41 characters.")

        result = presenter.isValidPersonalMessage(LoremIpsum.short)

        XCTAssertTrue(result)
        XCTAssertEqual(view.dismissMessageInputErrorCallsCount, 1)
    }
}

// MARK: - Account details activation

extension CreatePaymentRequestPersonalPresenterTests {
    func testCurrencySelector_GivenEligibilities_ThenRouterReceivedTheCorrectCurrencies() {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()

        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
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
            ),
            contact: RequestMoneyContact.build(hasRequestCapability: true)
        )
        presenter = makePresenter(
            profile: personalProfile,
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

    func testCurrencySelection_GivenAccountDetailsEligibleCurrencyAndBalanceEligible_ThenBalanceActivated_andAccountDetailsActivatedForCurrency() {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)

        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
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
            ),
            contact: RequestMoneyContact.build(hasRequestCapability: true)
        )
        paymentRequestEligibilityUseCase.eligibleBalancesReturnValue = .just(
            PaymentRequestEligibleBalances.build(
                balances: [
                    PaymentRequestEligibleBalances.Balance.build(
                        currency: .USD
                    ),
                ]
            )
        )
        presenter = makePresenter(
            profile: personalProfile,
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
            paymentRequestEligibilityUseCase.eligibleBalancesCalled
        )
        XCTAssertEqual(routingDelegate.showAccountDetailsFlowReceivedCurrencyCode, .USD)
        accountdetailsSubject.send(())
        XCTAssertTrue(
            paymentRequestEligibilityUseCase.eligibleBalancesCalled
        )
        XCTAssertEqual(view.updateSelectedCurrencyReceivedCurrency, .USD)
    }

    func testCurrencySelection_GivenBalanceEligibleCurrency_ThenBalanceActivatedForCurrency() {
        let paymentMethodsAvailability = [
            PaymentMethodAvailability.build(
                paymentMethod: PaymentMethodAvailability.PaymentMethod.build(type: .payWithWise),
                availability: .available
            ),
        ]
        paymentMethodsUseCase.paymentMethodsAvailabilityReturnValue = .just(paymentMethodsAvailability)
        viewModelMapper.makeReturnValue = makeViewModelForPersonalProfile()
        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
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
            ),
            contact: RequestMoneyContact.build(hasRequestCapability: true)
        )
        paymentRequestEligibilityUseCase.eligibleBalancesReturnValue = .just(
            PaymentRequestEligibleBalances.build(
                balances: [
                    PaymentRequestEligibleBalances.Balance.build(
                        currency: .AUD
                    ),
                ]
            )
        )
        presenter = makePresenter(
            profile: personalProfile,
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
            paymentRequestEligibilityUseCase.eligibleBalancesCalled
        )
        XCTAssertEqual(view.updateSelectedCurrencyReceivedCurrency, .AUD)
    }
}

// MARK: - Helpers

private extension CreatePaymentRequestPersonalPresenterTests {
    func makePresenter(
        profile: Profile,
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo
    ) -> CreatePaymentRequestPersonalPresenter {
        CreatePaymentRequestPersonalPresenterImpl(
            paymentRequestUseCase: paymentRequestUseCase,
            paymentMethodsUseCase: paymentMethodsUseCase,
            paymentRequestEligibilityUseCase: paymentRequestEligibilityUseCase,
            payWithWiseNudgePreferenceUseCase: payWithWiseNudgePreferenceUseCase,
            balanceManager: balanceManager,
            viewModelMapper: viewModelMapper,
            profile: profile,
            paymentRequestInfo: paymentRequestInfo,
            routingDelegate: routingDelegate,
            avatarFetcher: avatarFetcher,
            eligibilityService: eligibilityService,
            scheduler: .immediate
        )
    }

    func makePaymentRequest(
        amount: Decimal,
        paymemtMethods: [AcquiringPaymentMethodType] = [.card]
    ) -> PaymentRequestV2 {
        PaymentRequestV2.build(
            id: PaymentRequestId.canned,
            amount: .build(currency: paymentRequestEligibleBalance.currency, value: amount),
            profileId: ProfileId.canned,
            balanceId: paymentRequestEligibleBalance.id,
            creator: .canned,
            message: "abc",
            description: .canned,
            status: .canned,
            reference: .canned,
            link: .canned,
            createdAt: .canned,
            publishedAt: .canned,
            dueAt: .canned,
            expirationAt: .canned,
            invalidatedAt: .canned,
            updatedAt: .canned,
            attachments: .canned,
            selectedPaymentMethods: mapPaymentMethods(types: paymemtMethods),
            completedAt: .canned,
            payerSummary: .canned,
            invoice: nil
        )
    }

    func makePaymentRequestUpdateNoPayer(
        amount: Decimal,
        paymentRequestId: PaymentRequestId? = nil,
        paymemtMethods: [AcquiringPaymentMethodType] = [.card],
        payer: PaymentRequestSingleUseBody.Payer? = PaymentRequestSingleUseBody.Payer(contactId: nil, name: nil, address: nil)
    ) -> PaymentRequestSingleUseBody {
        PaymentRequestSingleUseBody.build(
            requestType: "SINGLE_USE",
            balanceId: paymentRequestEligibleBalance.id.value,
            selectedPaymentMethods: mapPaymentMethods(types: paymemtMethods),
            amountValue: amount,
            description: .canned,
            message: "abc",
            payer: payer
        )
    }

    func makePaymentRequestUpdate(
        amount: Decimal,
        paymentRequestId: PaymentRequestId? = nil,
        paymemtMethods: [AcquiringPaymentMethodType] = [.card],
        payer: PaymentRequestSingleUseBody.Payer? = PaymentRequestSingleUseBody.Payer(
            contactId: LoremIpsum.veryShort,
            name: nil,
            address: nil
        )
    ) -> PaymentRequestSingleUseBody {
        PaymentRequestSingleUseBody.build(
            requestType: "SINGLE_USE",
            balanceId: paymentRequestEligibleBalance.id.value,
            selectedPaymentMethods: mapPaymentMethods(types: paymemtMethods),
            amountValue: amount,
            description: .canned,
            message: "abc",
            payer: payer
        )
    }

    func mapPaymentMethods(types: [AcquiringPaymentMethodType]) -> [PaymentMethodTypeV2] {
        types.map { method in
            switch method {
            case .applePay:
                PaymentMethodTypeV2.applePay
            case .bankTransfer:
                PaymentMethodTypeV2.bankTransfer
            case .card:
                PaymentMethodTypeV2.card
            case .payWithWise:
                PaymentMethodTypeV2.payWithWise
            case .payNow:
                PaymentMethodTypeV2.payNow
            case .pisp:
                PaymentMethodTypeV2.pisp
            }
        }
    }

    func makeViewModelForPersonalProfile() -> CreatePaymentRequestPersonalViewModel {
        CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(
                title: "What's your request for?",
                description: "We’ll share this with Jane Doe to pay you."
            ),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "Amount",
                amount: "0.07",
                currencyName: "NZD",
                currencyAccessibilityName: "New Zealand Dollar",
                flagImage: CurrencyCode.NZD.icon
            ),
            currencySelectorEnabled: false,
            message: "",
            alert: nil,
            nudge: CreatePaymentRequestPersonalViewModel.Nudge(
                title: "Get paid free and instantly, if your contact uses Pay with Wise.",
                icon: .wallet,
                ctaTitle: "Learn more"
            ),
            footerButtonEnabled: true,
            footerButtonTitle: "Send request"
        )
    }

    func makeViewModelForPersonalProfileWithAlert() -> CreatePaymentRequestPersonalViewModel {
        CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(
                title: "What's your request for?",
                description: "We’ll share this with Jane Doe to pay you."
            ),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "Amount",
                amount: "0.07",
                currencyName: "NZD",
                currencyAccessibilityName: "New Zealand Dollar",
                flagImage: CurrencyCode.NZD.icon
            ),
            currencySelectorEnabled: false,
            message: "",
            alert: CreatePaymentRequestPersonalViewModel.Alert(
                style: .neutral,
                viewModel: Neptune.InlineAlertViewModel(
                    message: "pending verification"
                )
            ),
            nudge: CreatePaymentRequestPersonalViewModel.Nudge(
                title: "Get paid free and instantly, if your contact uses Pay with Wise.",
                icon: .wallet,
                ctaTitle: "Learn more"
            ),
            footerButtonEnabled: false,
            footerButtonTitle: "Send request"
        )
    }

    func makeViewModelForPersonalProfileWithWarningAlert() -> CreatePaymentRequestPersonalViewModel {
        CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(
                title: "What's your request for?",
                description: "We’ll share this with Jane Doe to pay you."
            ),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "Amount",
                amount: "0.07",
                currencyName: "NZD",
                currencyAccessibilityName: "New Zealand Dollar",
                flagImage: CurrencyCode.NZD.icon
            ),
            currencySelectorEnabled: false,
            message: "",
            alert: CreatePaymentRequestPersonalViewModel.Alert(
                style: .warning,
                viewModel: Neptune.InlineAlertViewModel(
                    message: "requires action"
                )
            ),
            nudge: CreatePaymentRequestPersonalViewModel.Nudge(
                title: "Get paid free and instantly, if your contact uses Pay with Wise.",
                icon: .wallet,
                ctaTitle: "Learn more"
            ),
            footerButtonEnabled: false,
            footerButtonTitle: "Send request"
        )
    }
}
