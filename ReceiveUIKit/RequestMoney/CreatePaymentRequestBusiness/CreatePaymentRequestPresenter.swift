import AnalyticsKit
import BalanceKit
import Combine
import CombineSchedulers
import LoggingKit
import Neptune
import Prism
import ReceiveKit
import TransferResources
import TWFoundation
import UserKit
import WiseCore

enum RequestType {
    case singleUse
    case reusable
}

enum PaymentMethodManagementResult {
    case success
    case error
    case exited
}

typealias PaymentMethodDynamicForm = PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm

// sourcery: AutoMockable
protocol CreatePaymentRequestPresenter: AnyObject {
    var isReusableLinksEnabled: Bool { get }
    func start(with view: CreatePaymentRequestView)
    func togglePaymentLimit()
    func moneyValueUpdated(_ value: String?)
    func moneyInputCurrencyTapped()
    func continueTapped(inputs: CreatePaymentRequestInputs)
    func dismiss()
}

final class CreatePaymentRequestPresenterImpl {
    private weak var view: CreatePaymentRequestView?
    private weak var routingDelegate: CreatePaymentRequestRoutingDelegate?

    private let interactor: CreatePaymentRequestInteractor
    private let balanceManager: BalanceManager
    private let viewModelMapper: CreatePaymentRequestViewModelMapper
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<CreatePaymentRequestAnalyticsView>
    private let prismAnalyticsTracker: PaymentRequestTracking
    private let profile: Profile
    private let featureService: FeatureService
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var continuePaymentRequestCreationCancellable: AnyCancellable?
    private var fetchProductEligibilityCancellable: AnyCancellable?
    private var fetchReceiverPaymentMethodsCancellable: AnyCancellable?
    private var balanceCreationCancellable: AnyCancellable?

    private var productEligibility: RequestMoneyProductEligibility = .singleUseAndReusable
    private var paymentLimitToggle = false
    private lazy var currentRequestType: RequestType =
        if paymentLimitToggle {
            .singleUse
        } else {
            .reusable
        }

    private var localRequest = CurrentValueSubject<CreatePaymentRequestPresenterInfo?, Never>(nil)
    private var allPaymentMethods: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability?
    private var paymentRequestInfo: CreatePaymentRequestPresenterInfo
    private var isFirstLoad: Bool

    init(
        interactor: CreatePaymentRequestInteractor,
        balanceManager: BalanceManager = BalanceManagerFactory.makeBalanceManager(),
        viewModelMapper: CreatePaymentRequestViewModelMapper,
        profile: Profile,
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        featureService: FeatureService,
        routingDelegate: CreatePaymentRequestRoutingDelegate,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        prismAnalyticsTracker: PaymentRequestTracking,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.interactor = interactor
        self.balanceManager = balanceManager
        self.viewModelMapper = viewModelMapper
        self.profile = profile
        self.paymentRequestInfo = paymentRequestInfo
        self.featureService = featureService
        self.routingDelegate = routingDelegate
        self.scheduler = scheduler
        isFirstLoad = true
        self.prismAnalyticsTracker = prismAnalyticsTracker
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: CreatePaymentRequestAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }
}

// MARK: - Select payment methods

private extension CreatePaymentRequestPresenterImpl {
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
}

// MARK: - CreatePaymentRequestPresenter

extension CreatePaymentRequestPresenterImpl: CreatePaymentRequestPresenter {
    var isReusableLinksEnabled: Bool {
        featureService.isOn(ReceiveKitFeatures.reusablePaymentLinksEnabled)
    }

    func continueTapped(inputs: CreatePaymentRequestInputs) {
        updateFields(
            newReference: inputs.reference,
            productDescription: inputs.productDescription
        )
        guard let validatedRequest = makeValidatedRequest() else {
            return
        }
        view?.showHud()

        continuePaymentRequestCreationCancellable = interactor.createPaymentRequest(
            body: validatedRequest
        )
        .eraseToAnyPublisher()
        .receive(on: scheduler)
        .asResult()
        .sink { [weak self] result in
            guard let self else {
                return
            }
            view?.hideHud()
            switch result {
            case let .success(paymentRequest):
                paymentRequestInfo.update(request: paymentRequest)
                routingDelegate?.showConfirmation(paymentRequest: paymentRequest)
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
              let amount = MoneyFormatter.number(value)?.decimalValue else {
            paymentRequestInfo.value = nil
            localRequest.send(paymentRequestInfo)
            return
        }
        paymentRequestInfo.value = amount
        localRequest.send(paymentRequestInfo)
    }

    func togglePaymentLimit() {
        paymentLimitToggle.toggle()
        updateView()
        let action = CreatePaymentRequestAnalyticsView.TypeSelectionChanged(tab: currentRequestType)
        analyticsViewTracker.track(action)
    }

    func dismiss() {
        routingDelegate?.dismiss()
    }

    func start(with view: CreatePaymentRequestView) {
        self.view = view
        fetchProductEligibilityCancellable = interactor.fetchEligibilityAndDefaultRequestType()
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                switch result {
                case let .success((eligibility, defaultRequestType)):
                    productEligibility = eligibility
                    paymentLimitToggle = defaultRequestType == .singleUse ? true : false
                    updateView()
                case .failure:
                    showError()
                }
            }

        subscribeToLocalRequest()
        localRequest.send(paymentRequestInfo)
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

// MARK: - PaymentMethodManagement

private extension CreatePaymentRequestPresenterImpl {
    func generatePaymentMethodOptionSubtitle(methods: [PaymentRequestV2PaymentMethods]) -> String {
        switch methods.count {
        case 0:
            return L10n.PaymentRequest.Create.PaymentMethodsOption.noPaymentMethods
        case 1:
            return getMethodName(type: methods[0])
        default:
            let method = getMethodName(type: methods[0])
            let number = String(methods.count - 1)
            return L10n.PaymentRequest.Create.PaymentMethodsOption.multiplePaymentMethods(method, number)
        }
    }

    func getMethodName(type: PaymentRequestV2PaymentMethods) -> String {
        let method = allPaymentMethods?.paymentMethods.filter { $0.type == type }
        return method?.first?.name ?? ""
    }

    func makePaymentMethodsOption(subtitle: String) -> CreatePaymentRequestViewModel.PaymentMethodsOption {
        .init(viewModel: .init(
            title: L10n.PaymentRequest.Create.PaymentMethodsManagement.title,
            subtitle: subtitle,
            avatar: ._double(
                primary: .icon(Icons.fastFlag.image, colors: nil),
                secondary: .icon(Icons.card.image, colors: nil)
            )
        ), onTap: { [weak self] in
            guard let self else { return }
            guard let methods = allPaymentMethods else { return }
            trackMethodManagementModalOpened()
            routingDelegate?.showPaymentMethodsSheet(
                delegate: self,
                localPreferences: paymentRequestInfo.fetchPaymentMethods(),
                methods: methods
            ) { [weak self] newPreferences in
                guard let self else { return }
                let result: PaymentMethodManagementResult =
                    Set(newPreferences) == Set(paymentRequestInfo.fetchPaymentMethods()) ? .exited : .success
                paymentRequestInfo.updatePaymentMethods(methods: newPreferences)
                let subtitle = generatePaymentMethodOptionSubtitle(methods: paymentRequestInfo.fetchPaymentMethods())
                view?.updatePaymentMethodOption(option: makePaymentMethodsOption(subtitle: subtitle))
                trackMethodManagementModalClosed(result: result)
            }
        })
    }

    func getPaymentMethods(
        _ requestData: CreatePaymentRequestPresenterInfo
    ) -> AnyPublisher<
        PaymentRequestV2ReceiverAvailability,
        Error
    > {
        interactor.fetchReceiverCurrencyAvailability(
            amount: requestData.value ?? 1.0,
            currencies: [requestData.selectedCurrency],
            paymentMethods: PaymentRequestV2PaymentMethods.allCases.filter { $0 != .unknown },
            onlyPreferredPaymentMethods: false
        ).eraseToAnyPublisher()
    }

    func subscribeToLocalRequest() {
        fetchReceiverPaymentMethodsCancellable = localRequest
            .compactMap { $0 }
            .flatMap { [weak self] requestData -> AnyPublisher<PaymentRequestV2ReceiverAvailability, Error> in
                guard let self else {
                    return .fail(with: GenericError("[REC] Presenter deallocated"))
                }
                return getPaymentMethods(requestData)
            }
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in

                guard let self else { return }
                switch result {
                case let .success(availability):

                    if isFirstLoad {
                        allPaymentMethods = availability.currencies[0]
                        let availableAndPreferredMethods = allPaymentMethods?.paymentMethods.filter { $0.available && $0.preferred }.map { $0.type }
                        paymentRequestInfo.updatePaymentMethods(methods: availableAndPreferredMethods ?? [])
                        isFirstLoad = false
                    } else {
                        allPaymentMethods = availability.currencies[0]
                        let allMethods = allPaymentMethods?.paymentMethods.map { $0.type }
                        let unavailableMethods = allPaymentMethods?.paymentMethods.filter { $0.available == false }.map { $0.type }

                        var newLocalMethods: [PaymentRequestV2PaymentMethods] = []
                        // remove all methods that are not returned anymore (because they are not supported by the currency)
                        newLocalMethods = paymentRequestInfo.fetchPaymentMethods().filter { allMethods?.contains($0) == true }
                        // remove all unavailable methods (because they are technically supported by the currency, but unavailable
                        // due to reasons like verification)
                        if let unavailableMethods {
                            newLocalMethods = newLocalMethods.filter { !unavailableMethods.contains($0) == true }
                        }
                        paymentRequestInfo.updatePaymentMethods(methods: newLocalMethods)
                    }

                    let isAtLeastOneSelected = paymentRequestInfo.fetchPaymentMethods().isNonEmpty
                    view?.footerButtonState(enabled: isAtLeastOneSelected && paymentRequestInfo.value.isNonNil)
                    let subtitle = generatePaymentMethodOptionSubtitle(methods: paymentRequestInfo.fetchPaymentMethods())
                    view?.updatePaymentMethodOption(option: makePaymentMethodsOption(subtitle: subtitle))
                    view?.updateNudge(makeNudge())
                case .failure:
                    showError()
                }
            }
    }

    func trackMethodManagementModalOpened() {
        let methodsSelected: [AcquiringMethodType] = paymentRequestInfo.fetchPaymentMethods().map { method in
            switch method {
            case .applePay:
                .applePay
            case .bankTransfer:
                .bankTransfer
            case .card:
                .card
            case .payNow:
                .paynow
            case .payWithWise:
                .payWithWise
            case .pisp:
                .pisp
            case .unknown:
                nil
            }
        }.compactMap { $0 }

        prismAnalyticsTracker.onPaymentMethodsOpened(methodsSelected: methodsSelected)
    }

    func trackMethodManagementModalClosed(result: PaymentMethodManagementResult) {
        let methodsSelected: [AcquiringMethodType] = paymentRequestInfo.fetchPaymentMethods().map { method in
            switch method {
            case .applePay:
                .applePay
            case .bankTransfer:
                .bankTransfer
            case .card:
                .card
            case .payNow:
                .paynow
            case .payWithWise:
                .payWithWise
            case .pisp:
                .pisp
            case .unknown:
                nil
            }
        }.compactMap { $0 }

        switch result {
        case .success:
            prismAnalyticsTracker.onPaymentMethodsClosed(methodsSelected: methodsSelected, result: .success)
        case .error:
            prismAnalyticsTracker.onPaymentMethodsClosed(methodsSelected: methodsSelected, result: .error)
        case .exited:
            prismAnalyticsTracker.onPaymentMethodsClosed(methodsSelected: methodsSelected, result: .exited)
        }
    }
}

// MARK: - Helpers

private extension CreatePaymentRequestPresenterImpl {
    func updateFields(
        newReference: String?,
        productDescription: String?
    ) {
        if let newReference, newReference.isNonEmpty {
            paymentRequestInfo.reference = newReference
        }
        if let productDescription {
            paymentRequestInfo.productDescription = productDescription
        }
    }

    func makeValidatedRequest() -> PaymentRequestBodyV2? {
        do {
            return try CreatePaymentRequestBodyBuilder.make(
                requestType: currentRequestType,
                paymentRequestInfo: paymentRequestInfo
            )
        } catch let error as CreatePaymentRequestBodyBuilderError {
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
        let errorViewModel = ErrorViewModel(
            illustrationConfiguration: .warning,
            title: title,
            message: .text(message),
            primaryViewModel: .done { [weak self] in
                self?.dismiss()
            }
        )
        view?.configureWithError(with: errorViewModel)
    }

    private func showPaymentMethodSelectionError(_ error: PaymentMethodSelectionError) {
        showError(message: error.errorDescription ?? L10n.Generic.Error.message)
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

    func updateView() {
        let shouldShowPaymentLimitsCheckbox = isReusableLinksEnabled && productEligibility == .singleUseAndReusable
        let paymentMethodsSubtitle: String = {
            guard allPaymentMethods.isNonNil else {
                return ""
            }
            return generatePaymentMethodOptionSubtitle(methods: paymentRequestInfo.fetchPaymentMethods())
        }()

        let viewModel = viewModelMapper.make(
            shouldShowPaymentLimitsCheckbox: shouldShowPaymentLimitsCheckbox,
            isLimitPaymentsSelected: paymentLimitToggle,
            paymentRequestInfo: paymentRequestInfo,
            paymentMethodsOption: makePaymentMethodsOption(subtitle: paymentMethodsSubtitle),
            nudge: makeNudge()
        )
        view?.configure(with: viewModel)
    }
}

// MARK: - Get Paid with Card Nudge

private extension CreatePaymentRequestPresenterImpl {
    func onNudgeDismissed(type: CardNudgeType) {
        interactor.setShouldShowNudge(false, profileId: profile.id, nudgeType: type)
        view?.updateNudge(nil)
        prismAnalyticsTracker.onCardSetupNudgeDismiss()
    }

    func onNudgeSelected(forms: [PaymentMethodDynamicForm], type: CardNudgeType) {
        routingDelegate?.showDynamicFormsMethodManagement(forms, delegate: self)
        prismAnalyticsTracker.onCardSetupNudgeOpened()
    }

    func makeNudge() -> NudgeViewModel? {
        var forms: [PaymentMethodDynamicForm]?

        allPaymentMethods?.paymentMethods.forEach { paymentMethod in
            guard paymentMethod.type == .card,
                  case let .requiresUserAction(dynamicForms: dynamicForms) = paymentMethod.unavailabilityReason else {
                return
            }
            forms = dynamicForms
        }

        guard let forms, let flowId = PaymentMethodsDynamicFormId(rawValue: forms.first?.flowId) else {
            return nil
        }

        switch flowId {
        case .acquiringOnboardingConsentFormId,
             .acquiringEvidenceCollectionFormId:
            if interactor.shouldShowNudge(profileId: profile.id, nudgeType: .onboarding) {
                prismAnalyticsTracker.onCardSetupNudgeViewed()
                return NudgeViewModel(
                    title: L10n.PaymentRequest.Create.Business.CardOnboardingNudge.title,
                    asset: .globe,
                    ctaTitle: L10n.PaymentRequest.Create.Business.CardOnboardingNudge.ctaTitle,
                    onSelect: { self.onNudgeSelected(forms: forms, type: .onboarding) },
                    onDismiss: { self.onNudgeDismissed(type: .onboarding) }
                )
            }
        case .waitlistFormId:
            if interactor.shouldShowNudge(profileId: profile.id, nudgeType: .waitlist) {
                return NudgeViewModel(
                    title: L10n.PaymentRequest.Create.Business.CardWaitlistNudge.title,
                    asset: .globe,
                    ctaTitle: L10n.PaymentRequest.Create.Business.CardWaitlistNudge.ctaTitle,
                    onSelect: { self.onNudgeSelected(forms: forms, type: .waitlist) },
                    onDismiss: { self.onNudgeDismissed(type: .waitlist) }
                )
            }
        }
        return nil
    }
}

// MARK: - PaymentMethodsDelegate

extension CreatePaymentRequestPresenterImpl: PaymentMethodsDelegate {
    func refreshPaymentMethods() {
        localRequest.send(paymentRequestInfo)
    }

    func trackDynamicFlowFailed() {
        trackMethodManagementModalClosed(result: .error)
    }
}

// MARK: - Account details activation

private extension CreatePaymentRequestPresenterImpl {
    func createBalance(_ balance: PaymentRequestEligibleBalances.Eligibility) {
        let publisher: AnyPublisher<BalanceId?, Error> = {
            if let routingDelegate, balance.eligibleForAccountDetails {
                if balance.eligibleForBalance {
                    // need to activate the balance first if not activated (not automatic anymore)
                    view?.showHud()
                    return self.activateBalance(
                        currencyCode: balance.currency
                    ).flatMap { _ -> AnyPublisher<BalanceId?, Error> in
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
                ).eraseToAnyPublisher()
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
                )
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

    func selectBalance(
        id: BalanceId,
        currencyCode: CurrencyCode
    ) {
        paymentRequestInfo.selectedCurrency = currencyCode
        paymentRequestInfo.selectedBalanceId = id
        localRequest.send(paymentRequestInfo)
        view?.updateSelectedCurrency(currency: currencyCode)
    }

    func updateEligibleBalances() -> AnyPublisher<Void, Error> {
        interactor.fetchEligibleBalances()
            .receive(on: scheduler)
            .map { [weak self] eligibleBalances in
                self?.paymentRequestInfo.eligibleBalances = eligibleBalances
                return ()
            }
            .eraseToAnyPublisher()
    }

    func findEligibleBalance(
        currencyCode: CurrencyCode
    ) -> AnyPublisher<BalanceId, Error> {
        guard let eligibleBalance = paymentRequestInfo
            .eligibleBalances
            .balances
            .first(where: {
                $0.currency == currencyCode
            }) else {
            softFailure("[REC]: Eligible balance not found despite activated")
            return .fail(with: BalanceSelectionError.eligibleBalanceNotFound)
        }
        return .just(eligibleBalance.id)
    }

    func activateBalance(
        currencyCode: CurrencyCode
    ) -> AnyPublisher<BalanceId?, Error> {
        let subject = PassthroughSubject<BalanceId?, Error>()
        balanceManager.activate(
            balance: .standard(currency: currencyCode),
            completion: {
                switch $0 {
                case let .success(balance):
                    subject.send(balance.id)
                case let .failure(error):
                    subject.send(completion: .failure(error as Error))
                }
            }
        )
        return subject.eraseToAnyPublisher()
    }
}
