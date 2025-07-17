import BalanceKit
import Combine
import CombineSchedulers
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol CreatePaymentRequestPersonalPresenter: AnyObject {
    func start(with view: CreatePaymentRequestPersonalView)
    func moneyValueUpdated(_ value: String?)
    func moneyInputCurrencyTapped()
    func nudgeSelected()
    func nudgeCloseTapped()
    func sendRequestTapped(note: String)
    func dismiss()
    func isValidPersonalMessage(_ message: String) -> Bool
}

final class CreatePaymentRequestPersonalPresenterImpl {
    private weak var view: CreatePaymentRequestPersonalView?
    private weak var routingDelegate: CreatePaymentRequestPersonalRoutingDelegate?
    private let paymentRequestUseCase: PaymentRequestUseCaseV2
    private let paymentMethodsUseCase: PaymentMethodsUseCase
    private let paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCase
    private let balanceManager: BalanceManager
    private let payWithWiseNudgePreferenceUseCase: PayWithWiseNudgePreferenceUseCase
    private let avatarFetcher: CancellableAvatarFetcher
    private let viewModelMapper: CreatePaymentRequestPersonalViewModelMapper
    private let eligibilityService: ReceiveEligibilityService
    private let profile: Profile
    private var paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo
    private let contact: RequestMoneyContact?
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var continuePaymentRequestCreationCancellable: AnyCancellable?
    private var balanceCreationCancellable: AnyCancellable?
    private var checkPWWAvailabilityCancellable: AnyCancellable?

    init(
        paymentRequestUseCase: PaymentRequestUseCaseV2,
        paymentMethodsUseCase: PaymentMethodsUseCase,
        paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCase,
        payWithWiseNudgePreferenceUseCase: PayWithWiseNudgePreferenceUseCase,
        balanceManager: BalanceManager = BalanceManagerFactory.makeBalanceManager(),
        viewModelMapper: CreatePaymentRequestPersonalViewModelMapper,
        profile: Profile,
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate,
        avatarFetcher: CancellableAvatarFetcher,
        eligibilityService: ReceiveEligibilityService,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.paymentRequestUseCase = paymentRequestUseCase
        self.paymentMethodsUseCase = paymentMethodsUseCase
        self.paymentRequestEligibilityUseCase = paymentRequestEligibilityUseCase
        self.payWithWiseNudgePreferenceUseCase = payWithWiseNudgePreferenceUseCase
        self.balanceManager = balanceManager
        self.viewModelMapper = viewModelMapper
        self.profile = profile
        self.paymentRequestInfo = paymentRequestInfo
        self.routingDelegate = routingDelegate
        self.avatarFetcher = avatarFetcher
        self.eligibilityService = eligibilityService
        self.scheduler = scheduler
        contact = {
            guard paymentRequestInfo.contact?.hasRequestCapability == true else {
                return nil
            }
            return paymentRequestInfo.contact
        }()
    }
}

// MARK: - Select payment methods

private extension CreatePaymentRequestPersonalPresenterImpl {
    private enum PaymentMethodSelectionError: LocalizedError {
        case payWithWiseNotFound
        case payWithWiseNotAvailable(localizedMessage: String)
        case noAvailablePaymentMethod

        var errorDescription: String? {
            switch self {
            case .payWithWiseNotFound:
                L10n.PaymentRequest.Create.PaymentMethodSelection.Error.Message.payWithWiseNotFound
            case let .payWithWiseNotAvailable(localizedMessage):
                localizedMessage
            case .noAvailablePaymentMethod:
                L10n.PaymentRequest.Create.PaymentMethodSelection.Error.Message.noAvailablePaymentMethod
            }
        }
    }

    private enum BalanceSelectionError: Error {
        case eligibleBalanceNotFound
        case currencyIsNotEligible
    }

    private func selectPaymentMethodIfPWWIsAvailable(
        paymentMethodsAvailability: [PaymentMethodAvailability],
        validatedRequest: PaymentRequestSingleUseBody
    ) throws -> PaymentRequestSingleUseBody {
        guard let payWithWiseAvailability = paymentMethodsAvailability.first(where: { availability in
            availability.paymentMethod.type == .payWithWise
        }) else {
            throw PaymentMethodSelectionError.payWithWiseNotFound
        }

        switch payWithWiseAvailability.availability {
        case .available:
            var availablePaymentMethods = [payWithWiseAvailability.paymentMethod.type]
            if contact.isNil {
                let otherPaymentMethods = paymentMethodsAvailability
                    .filter { $0.isAvailable() && $0.paymentMethod.type != .payWithWise }
                    .map { $0.paymentMethod.type }
                availablePaymentMethods.append(contentsOf: otherPaymentMethods)
            }

            paymentRequestInfo.paymentMethods = CreatePaymentRequestPaymentMethodMapper.mapPaymentMethod(types: availablePaymentMethods)
            paymentRequestInfo.PWWAlert = nil
            return validatedRequest.applied(paymentMethods: CreatePaymentRequestPaymentMethodMapper.mapPaymentMethod(types: availablePaymentMethods))
        case .unavailable:
            throw PaymentMethodSelectionError.noAvailablePaymentMethod
        case let .requiresUserAction(forms):
            paymentRequestInfo.PWWAlert = PWWAlert(
                message: payWithWiseAvailability.paymentMethod.summary,
                type: .warning,
                action: Action(
                    title: L10n.PaymentRequest.Create.PWWAlert.cta,
                    isEnabled: true,
                    handler: { [weak self] in self?.handleDynamicForms(forms: forms) }
                )
            )
        case .pendingVerification:
            paymentRequestInfo.PWWAlert = PWWAlert(
                message: payWithWiseAvailability.paymentMethod.summary,
                type: .neutral,
                action: nil
            )
        }

        throw PaymentMethodSelectionError.payWithWiseNotAvailable(
            localizedMessage: payWithWiseAvailability.paymentMethod.summary // `summary` is the unavailable reason
        )
    }

    private func selectAvailablePaymentMethods(validatedRequest: PaymentRequestSingleUseBody) -> AnyPublisher<
        PaymentRequestSingleUseBody,
        Error
    > {
        paymentMethodsUseCase.paymentMethodsAvailability(
            profileId: profile.id,
            currency: paymentRequestInfo.selectedCurrency,
            amount: validatedRequest.amountValue
        )
        .tryMap { [weak self] paymentMethodsAvailability in
            guard let self else {
                throw GenericError("[REC] Attempt to select payment methods but presenter is empty.")
            }
            return try selectPaymentMethodIfPWWIsAvailable(
                paymentMethodsAvailability: paymentMethodsAvailability,
                validatedRequest: validatedRequest
            )
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - CreatePaymentRequestPresenter

@MainActor
extension CreatePaymentRequestPersonalPresenterImpl: CreatePaymentRequestPersonalPresenter {
    private enum Constants {
        static let analyticsModeValue = "create"
    }

    func sendRequestTapped(note: String) {
        updateFields(
            newMessage: note
        )
        guard let validatedRequest = makeValidatedRequest(paymentRequestInfo) else {
            return
        }
        continuePaymentRequestCreationCancellable = selectAvailablePaymentMethods(validatedRequest: validatedRequest)
            .mapError { error in PaymentRequestUseCaseError.other(error: error) }
            .flatMap { [weak self] request -> AnyPublisher<PaymentRequestV2, PaymentRequestUseCaseError> in
                guard let self else {
                    return .fail(with: PaymentRequestUseCaseError.other(error: GenericError(L10n.Generic.Error.message)))
                }
                return paymentRequestUseCase.createPaymentRequest(
                    profileId: profile.id,
                    body: PaymentRequestBodyV2.singleUse(request)
                )
                .eraseToAnyPublisher()
            }
            .receive(on: scheduler)
            .asResult()
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                switch result {
                case let .success(paymentRequest):
                    paymentRequestInfo.update(request: paymentRequest)
                    proceedToNextStep(paymentRequest: paymentRequest)
                case let .failure(error):
                    switch error {
                    case let .customError(message: message):
                        showError(title: "", message: message ?? L10n.Generic.Error.message)
                    case let .other(error as ReceiveError):
                        showError(title: "", message: error.customErrorMessage ?? L10n.Generic.Error.message)
                    case let .other(error as PaymentMethodSelectionError):
                        showPaymentMethodSelectionError(error)
                    case .other:
                        showError()
                    }
                }
            }
    }

    func moneyValueUpdated(_ value: String?) {
        guard let value,
              let amount = MoneyFormatter.number(value)?.decimalValue,
              paymentRequestInfo.PWWAlert == nil else {
            view?.footerButtonState(enabled: false)
            paymentRequestInfo.value = nil
            return
        }
        paymentRequestInfo.value = amount
        view?.footerButtonState(enabled: true)
    }

    func handleDynamicForms(forms: [PaymentMethodAvailability.DynamicForm]) {
        routingDelegate?.handleDynamicForms(
            forms: forms, completionHandler: { [weak self] in
                guard let self else { return }
                checkPWWVerification(isFirstValidation: true)
            }
        )
    }

    func nudgeSelected() {
        routingDelegate?.showPayWithWiseEducation()
    }

    func nudgeCloseTapped() {
        view?.hideNudge()
        payWithWiseNudgePreferenceUseCase.setPayWithWiseNudgePreference(false, for: profile.id)
    }

    func dismiss() {
        routingDelegate?.dismiss()
    }

    func isValidPersonalMessage(_ message: String) -> Bool {
        if case let .invalid(reason) = CreatePaymentRequestPersonalValidator.validPersonalMessage(message) {
            view?.showMessageInputError(reason.description)
            return false
        } else {
            view?.dismissMessageInputError()
            return true
        }
    }

    func start(with view: CreatePaymentRequestPersonalView) {
        self.view = view
        checkPWWVerification(isFirstValidation: true)
    }

    func moneyInputCurrencyTapped() {
        let availableCurrencies = paymentRequestInfo.eligibleBalances.eligibilities
            .lazy
            .filter {
                if $0.eligibleForBalance || $0.eligibleForAccountDetails {
                    true
                } else {
                    false
                }
            }
            .map {
                $0.currency
            }

        let activeCurrencies = paymentRequestInfo.eligibleBalances.balances
            .lazy
            .map(\.currency)
            .sorted(by: \.value)
        routingDelegate?.showCurrencySelector(
            activeCurrencies: activeCurrencies,
            eligibleCurrencies: Array(availableCurrencies),
            selectedCurrency: paymentRequestInfo.selectedCurrency
        ) { [weak self] currency in
            self?.moneyInputCurrencySelected(currency)
        }
    }
}

// MARK: - Helpers

@MainActor
private extension CreatePaymentRequestPersonalPresenterImpl {
    func updateFields(
        newMessage: String?
    ) {
        if let newMessage, newMessage.isNonEmpty {
            paymentRequestInfo.message = newMessage
        }
    }

    func makeValidatedRequest(_ paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo) -> PaymentRequestSingleUseBody? {
        do {
            return try CreatePaymentRequestPersonalBodyBuilder.make(
                paymentRequestInfo: paymentRequestInfo
            )
        } catch let error as CreatePaymentRequestPersonalBodyBuilderError {
            switch error {
            case let .invalidAmount(reason):
                view?.calculatorError(reason)
            }
        } catch {
            softFailure("[REC] Catch unexpected error from payment request creation validation: \(error.localizedDescription).")
            showError()
        }
        return nil
    }

    func showError(
        title: String = L10n.Generic.Error.title,
        message: String = L10n.Generic.Error.message
    ) {
        view?.showDismissableAlert(
            title: title,
            message: message
        )
    }

    private func showPaymentMethodSelectionError(_ error: PaymentMethodSelectionError) {
        view?.showDismissableAlert(
            title: L10n.Generic.Error.title,
            message: error.errorDescription ?? L10n.Generic.Error.message
        )
    }

    func moneyInputCurrencySelected(_ currency: CurrencyCode) {
        if let availableBalance = paymentRequestInfo
            .eligibleBalances.balances
            .first(where: { $0.currency == currency }) {
            selectBalance(
                id: availableBalance.id,
                currencyCode: currency
            )
        } else if let eligibleBalance = paymentRequestInfo
            .eligibleBalances.eligibilities
            .first(where: { $0.currency == currency }) {
            createBalance(eligibleBalance)
        } else {
            softFailure("[REC]: Invalid currency chosen")
        }
    }

    func proceedToNextStep(paymentRequest: PaymentRequestV2) {
        guard let contact else {
            routingDelegate?.showConfirmation(paymentRequest: paymentRequest)
            return
        }
        routingDelegate?.showRequestFromContactsSuccess(
            contact: contact,
            paymentRequest: paymentRequest
        )
    }

    func makeContactListItemViewModel(completion: @escaping (OptionViewModel?) -> Void) {
        guard let contact else {
            completion(nil)
            return
        }
        avatarFetcher.fetch(
            publisher: contact.avatarPublisher,
            completion: { avatarModel in
                completion(
                    OptionViewModel(
                        title: contact.title,
                        subtitle: contact.subtitle.text,
                        avatar: avatarModel.asAvatarViewModel()
                    )
                )
            }
        )
    }

    func updateView() {
        let showNudge = payWithWiseNudgePreferenceUseCase.payWithWiseNudgeShouldShow(for: profile.id)
        let viewModel = viewModelMapper.make(
            contactName: contact?.title,
            paymentRequestInfo: paymentRequestInfo,
            shouldShowNudge: showNudge
        )

        view?.configure(with: viewModel)

        makeContactListItemViewModel(
            completion: { [weak self] contactOptionViewModel in
                self?.view?.configureContact(with: contactOptionViewModel)
            }
        )
    }
}

// MARK: - Account details activation

@MainActor
private extension CreatePaymentRequestPersonalPresenterImpl {
    func createBalance(_ balance: PaymentRequestEligibleBalances.Eligibility) {
        let publisher: AnyPublisher<BalanceId?, Error> = {
            if let routingDelegate, balance.eligibleForAccountDetails {
                if balance.eligibleForBalance {
                    // need to activate the balance first if not activated (not automatic anymore)
                    view?.showHud()
                    return self.activateBalance(
                        currencyCode: balance.currency
                    ).map { balance in
                        balance.id
                    }.flatMap { _ -> AnyPublisher<BalanceId?, Error> in
                        return routingDelegate.showAccountDetailsFlow(
                            currencyCode: balance.currency
                        ).flatMap { _ -> AnyPublisher<BalanceId?, Error> in
                            .just(nil)
                        }
                        .eraseToAnyPublisher()
                    }.eraseToAnyPublisher()
                } else {
                    // balance already activated
                    return routingDelegate.showAccountDetailsFlow(
                        currencyCode: balance.currency
                    ).flatMap { _ -> AnyPublisher<BalanceId?, Error> in
                        .just(nil)
                    }
                    .eraseToAnyPublisher()
                }
            } else if balance.eligibleForBalance {
                view?.showHud()
                return self.activateBalance(
                    currencyCode: balance.currency
                ).map { balance in
                    balance.id
                }.eraseToAnyPublisher()
            } else {
                softFailure("[REC]: Currency is not eligible for anything")
                return .fail(with: BalanceSelectionError.currencyIsNotEligible)
            }
        }()

        balanceCreationCancellable = publisher
            .flatMap { [unowned self] balanceId -> AnyPublisher<BalanceId?, Error> in
                view?.showHud()
                return updateEligibleBalances()
                    .map { _ in balanceId }
                    .eraseToAnyPublisher()
            }.flatMap { [unowned self] balanceId -> AnyPublisher<BalanceId, Error> in
                if let balanceId {
                    return .just(balanceId)
                }
                return findEligibleBalance(
                    currencyCode: balance.currency
                ).map {
                    $0.id
                }
                .eraseToAnyPublisher()
            }
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else { return }
                view?.hideHud()
                switch result {
                case let .success(createdBalanceId):
                    selectBalance(
                        id: createdBalanceId,
                        currencyCode: balance.currency
                    )
                case .failure:
                    showError()
                }
            }
    }

    func checkPWWVerification(isFirstValidation: Bool) {
        var tempPaymentRequest = paymentRequestInfo

        /* we pass 1 to check for payment methods availability here */
        if isFirstValidation {
            tempPaymentRequest.value = 1
        }

        guard let validatedRequest = makeValidatedRequest(tempPaymentRequest),
              let view else {
            return
        }

        view.loadingStateChanged(state: ModelState<PaymentRequestSingleUseBody, Error>.loading(nil))

        let publisher = selectAvailablePaymentMethods(validatedRequest: validatedRequest)
            .map {
                .content($0)
            }
            .catch { Just(ModelState<PaymentRequestSingleUseBody, Error>.error($0)) }
            .eraseToAnyPublisher()

        checkPWWAvailabilityCancellable = publisher
            .receive(on: scheduler)
            .handleLoading(view)
            .sink { [weak self] model in
                guard let self else { return }
                if let error = model.error {
                    handleError(error: error)
                } else {
                    updateView()
                }
            }
    }

    private func handleError(error: Error) {
        guard let error = error as? PaymentMethodSelectionError else {
            view?.configureWithError(with: .networkError(primaryViewModel: .retry { [weak self] in
                guard let self else {
                    return
                }
                routingDelegate?.dismiss()
            }))
            return
        }

        switch error {
        case .payWithWiseNotFound,
             .noAvailablePaymentMethod:
            view?.configureWithError(with: .networkError(primaryViewModel: .retry { [weak self] in
                guard let self else {
                    return
                }
                routingDelegate?.dismiss()
            }))
        case .payWithWiseNotAvailable:
            // alert is shown
            updateView()
        }
    }

    func selectBalance(
        id: BalanceId,
        currencyCode: CurrencyCode
    ) {
        paymentRequestInfo.selectedCurrency = currencyCode
        paymentRequestInfo.selectedBalanceId = id
        view?.updateSelectedCurrency(currency: currencyCode)
        checkPWWVerification(isFirstValidation: paymentRequestInfo.value.isNil ? true : false)
    }

    func updateEligibleBalances() -> AnyPublisher<Void, Error> {
        paymentRequestEligibilityUseCase.eligibleBalances(
            profile: profile
        )
        .receive(on: scheduler)
        .map { [weak self] eligibleBalances in
            self?.paymentRequestInfo.eligibleBalances = eligibleBalances
            return ()
        }
        .eraseToAnyPublisher()
    }

    func findEligibleBalance(
        currencyCode: CurrencyCode
    ) -> AnyPublisher<PaymentRequestEligibleBalances.Balance, Error> {
        guard let eligibleBalance = paymentRequestInfo
            .eligibleBalances
            .balances
            .first(where: {
                $0.currency == currencyCode
            }) else {
            softFailure("[REC]: Eligible balance not found despite activated")
            return .fail(with: BalanceSelectionError.eligibleBalanceNotFound)
        }
        return .just(eligibleBalance)
    }

    func activateBalance(
        currencyCode: CurrencyCode
    ) -> AnyPublisher<Balance, Error> {
        let subject = PassthroughSubject<Balance, Error>()
        balanceManager.activate(
            balance: .standard(currency: currencyCode),
            completion: {
                switch $0 {
                case let .success(balance):
                    subject.send(balance)
                case let .failure(error):
                    subject.send(completion: .failure(error as Error))
                }
            }
        )
        return subject.eraseToAnyPublisher()
    }
}
