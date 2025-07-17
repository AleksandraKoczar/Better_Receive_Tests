import BalanceKit
import Combine
import CombineSchedulers
import ContactsKit
import Foundation
import LoggingKit
import Neptune
import Prism
import ReceiveKit
import TransferResources
import TWFoundation
import UserKit
import WiseCore

final class PayWithWiseQuickpayPresenterImpl {
    private let interactor: PayWithWiseInteractor
    private let router: PayWithWiseRouter
    private let quickpayUseCase: QuickpayUseCase
    private let viewModelFactory: PayWithWiseViewModelFactory
    private let userProvider: UserProvider
    private let notificationCenter: NotificationCenter
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let payerData: QuickpayPayerData
    private let businessInfo: ContactSearch
    private let analyticsTracker: QuickpayTracking
    private let payWithWiseAnalyticsTracker: PayWithWiseAnalyticsTracker

    private weak var flowNavigationDelegate: PayWithWiseFlowNavigationDelegate?
    private weak var view: PayWithWiseView?

    private var profile: Profile
    private var quickpayAPLookup: QuickpayAcquiringPayment?
    private var quote: PayWithWiseQuote?
    private var balances: [Balance] = []
    private var fundableBalances: [Balance] = []
    private var selectedBalance: Balance?

    private var isLoading = false {
        didSet {
            guard oldValue != isLoading else { return }
            if isLoading {
                view?.showHud()
            } else {
                view?.hideHud()
            }
        }
    }

    private var updateDataCancellable: AnyCancellable?
    private var createQuoteCancellable: AnyCancellable?
    private var paymentCancellable: AnyCancellable?

    init(
        profile: Profile,
        payerData: QuickpayPayerData,
        businessInfo: ContactSearch,
        interactor: PayWithWiseInteractor,
        quickpayUseCase: QuickpayUseCase,
        router: PayWithWiseRouter,
        analyticsTracker: QuickpayTracking,
        payWithWiseAnalyticsTracker: PayWithWiseAnalyticsTracker = PayWithWiseAnalyticsTrackerImpl(),
        flowNavigationDelegate: PayWithWiseFlowNavigationDelegate?,
        viewModelFactory: PayWithWiseViewModelFactory,
        userProvider: UserProvider = GOS[UserProviderKey.self],
        notificationCenter: NotificationCenter = .default,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profile = profile
        self.payerData = payerData
        self.businessInfo = businessInfo
        self.interactor = interactor
        self.quickpayUseCase = quickpayUseCase
        self.router = router
        self.analyticsTracker = analyticsTracker
        self.payWithWiseAnalyticsTracker = payWithWiseAnalyticsTracker
        self.flowNavigationDelegate = flowNavigationDelegate
        self.viewModelFactory = viewModelFactory
        self.userProvider = userProvider
        self.notificationCenter = notificationCenter
        self.scheduler = scheduler
    }
}

// MARK: - PayWithWisePresenter

extension PayWithWiseQuickpayPresenterImpl: PayWithWisePresenter {
    func showDetails() {
        guard let quickpayAPLookup else { return }

        let rows = viewModelFactory.type().makeItemsForQuickpay(quickpayLookup: quickpayAPLookup)
        let viewModel = PayWithWiseRequestDetailsView.ViewModel(
            title: L10n.PayWithWise.Payment.RequestDetails.Screen.title,
            rows: rows,
            buttonConfiguration: nil
        )

        router.showDetails(viewModel: viewModel)
    }

    func start(with view: PayWithWiseView) {
        self.view = view
        updateAllData()
    }

    func dismiss() {
        flowNavigationDelegate?.dismissed(at: .singlePagePayer)
    }
}

// MARK: - Execution pipeline

private extension PayWithWiseQuickpayPresenterImpl {
    func updateAllData(
        needsBalanceRefresh: Bool = false
    ) {
        isLoading = true

        payWithWiseAnalyticsTracker.trackPayerScreenEvent(.startedLoggedIn)
        payWithWiseAnalyticsTracker.trackPayerScreenEvent(.started(
            context: .QuickPay(),
            paymentRequestType: .business,
            currency: payerData.currency
        ))

        updateDataCancellable = quickpayUseCase.createAcquiringPayment(
            wisetag: payerData.businessQuickpay,
            body: .init(amount: .init(value: payerData.value, currency: payerData.currency), description: payerData.description)
        )
        .mapError { error in
            PayWithWiseV2Error.creatingAcquiringPaymentFailed(error: error)
        }
        .flatMap { [unowned self] key -> AnyPublisher<QuickpayAcquiringPayment, PayWithWiseV2Error> in
            updateQuickpayLookupPublisher(paymentKey: key)
        }
        .flatMap { [unowned self] quickpayAPLookup -> AnyPublisher<
            (QuickpayAcquiringPayment, PayWithWiseInteractorImpl.BalanceFetchingResult),
            PayWithWiseV2Error
        > in
            updateBalancesPublisher(
                quickpayAPLookup: quickpayAPLookup,
                needsRefresh: needsBalanceRefresh
            )
        }
        .flatMap { [unowned self] quickpayAPLookup, balances -> AnyPublisher<
            PayWithWiseQuote,
            PayWithWiseV2Error
        > in
            self.balances = balances.balances
            fundableBalances = balances.fundableBalances
            selectedBalance = balances.autoSelectionResult.balance

            analyticsTracker.onBalanceAutoSelected(
                currencyBalanceExists: requestCurrencyBalanceExists(),
                hasEnoughFunds: requestCurrencyBalanceHasEnough()
            )

            return interactor.createQuickpayQuote(
                session: PaymentRequestSession(id: quickpayAPLookup.paymentSessionId.id),
                balanceId: balances.autoSelectionResult.balance.id,
                profileId: profile.id
            )
            .eraseToAnyPublisher()
        }
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else { return }
            isLoading = false
            switch result {
            case let .success(quote):
                self.quote = quote
                updateScreen(alert: nil)
                analyticsTracker.onPaymentMethodStarted(paymentMethod: .balance)
                trackOnLoadedSuccess()
            case let .failure(error):
                trackOnLoadedFailure(error: error)
                trackOnLoadedWithError(error: error)
                handleError(error)
            }
        }
    }
}

// MARK: - Data

private extension PayWithWiseQuickpayPresenterImpl {
    func updateQuickpayLookupPublisher(
        paymentKey: QuickpayAcquiringPaymentKey
    ) -> AnyPublisher<QuickpayAcquiringPayment, PayWithWiseV2Error> {
        if let quickpayAPLookup {
            return .just(quickpayAPLookup)
        }

        return interactor.acquiringPaymentLookup(
            paymentSession: paymentKey.clientSecret,
            acquiringPaymentId: paymentKey.acquiringPaymentId
        )
        .tryMap { [weak self] lookup in
            self?.quickpayAPLookup = lookup
            guard lookup.paymentMethods.contains(where: { $0.type == .payWithWise && $0.available == true }) else {
                throw PayWithWiseV2Error.payWithWiseNotAvailableOnQuickpay
            }
            return lookup
        }
        .mapError {
            $0 as? PayWithWiseV2Error ?? .fetchingAcquiringPaymentFailed
        }
        .eraseToAnyPublisher()
    }

    func updateBalancesPublisher(
        quickpayAPLookup: QuickpayAcquiringPayment,
        needsRefresh: Bool
    ) -> AnyPublisher<(QuickpayAcquiringPayment, PayWithWiseInteractorImpl.BalanceFetchingResult), PayWithWiseV2Error> {
        interactor.balances(
            amount: quickpayAPLookup.amount,
            profileId: profile.id,
            needsRefresh: needsRefresh
        )
        .map { balances in
            (quickpayAPLookup, balances)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Actions

private extension PayWithWiseQuickpayPresenterImpl {
    func pay() {
        payWithWiseAnalyticsTracker.trackPayerScreenEvent(.paymentMethodSelected(method: .PayWithWise()))
        payWithWiseAnalyticsTracker.trackEvent(.payTapped(
            requestCurrency: quickpayAPLookup?.amount.currency.value ?? "null",
            paymentCurrency: selectedBalance?.currency.value ?? "null",
            profileType: mapProfileType(profile.type)
        ))

        guard let quickpayAPLookup,
              let selectedBalance else {
            softFailure("[REC]: Tried to make payment without session or balance")
            return
        }
        let session = PaymentRequestSession(id: quickpayAPLookup.paymentSessionId.id)
        makePayment(session: session, balance: selectedBalance)
    }

    func makePayment(
        session: PaymentRequestSession,
        balance: Balance
    ) {
        isLoading = true
        paymentCancellable = interactor.pay(
            session: session,
            profileId: profile.id,
            balanceId: balance.id
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else { return }
            isLoading = false
            switch result {
            case let .success(payment):
                handleSuccessfulPayment(
                    balance: balance,
                    payment: payment
                )
                payWithWiseAnalyticsTracker.trackEvent(.paySucceed(
                    requestType: .QuickPay(),
                    requestCurrency: quickpayAPLookup?.amount.currency.value ?? "null",
                    paymentCurrency: selectedBalance?.currency.value ?? ""
                ))
            case let .failure(error):
                handleError(error)
                payWithWiseAnalyticsTracker.trackEvent(.payFailed(
                    paymentRequestId: quickpayAPLookup?.id.value ?? "null",
                    message: error.message
                ))
            }
        }
    }

    func showAlternativePaymentMethods(quickpayAPLookup: QuickpayAcquiringPayment) {
        guard quickpayAPLookup.paymentMethods.isNonEmpty else {
            return
        }
        payWithWiseAnalyticsTracker.trackEvent(.payAnotherWayTapped(
            requestCurrency: quickpayAPLookup.amount.currency.value,
            requestCurrencyBalanceExists: requestCurrencyBalanceExists(),
            requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough()
        ))

        if quickpayAPLookup.paymentMethods.count == 1,
           let method = quickpayAPLookup.paymentMethods.first {
            showPaymentMethod(method: method)
        } else {
            router.showPaymentMethodsBottomSheetQuickpay(
                paymentMethods: quickpayAPLookup.paymentMethods,
                businessName: businessInfo.contact.title,
                completion: { [weak self] method in
                    self?.showPaymentMethod(method: method)
                    if let method = self?.mapMethodType(method.type) {
                        self?.payWithWiseAnalyticsTracker.trackPayerScreenEvent(.paymentMethodSelected(method: method))
                    }
                }
            )
        }
    }

    func showPaymentMethod(method: QuickpayAcquiringPayment.PaymentMethodAvailability) {
        guard let quickpayAPLookup else { return }
        router.showPaymentMethodQuickpay(
            profileId: profile.id,
            paymentMethod: method,
            quickpayLookup: quickpayAPLookup,
            quickpay: payerData.businessQuickpay
        )
    }
}

// MARK: - Action handlers

private extension PayWithWiseQuickpayPresenterImpl {
    func startBalanceSelection(
        container: PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer
    ) {
        payWithWiseAnalyticsTracker.trackEvent(.balanceSelectorOpened(noOfBalances: Int64(balances.count)))

        let sections = viewModelFactory.makeBalanceSections(
            container: container
        )
        router.showBalanceSelector(
            viewModel: PayWithWiseBalanceSelectorViewModel(
                title: L10n.PayWithWise.Payment.Balance.Selector.title,
                sections: sections,
                selectAction: { [weak self] indexPath in
                    guard let self else { return }
                    // Only available balances section should be selectable
                    if indexPath.section == 0 {
                        router.dismissBalanceSelector()
                        guard let balance = balances.first(where: {
                            $0.id == container.fundables[safe: indexPath.row]?.id
                        }) else {
                            return
                        }
                        analyticsTracker.onBalanceSelected()
                        payWithWiseAnalyticsTracker.trackEvent(.balanceSelected(
                            requestCurrency: quickpayAPLookup?.amount.currency.value ?? "null",
                            paymentCurrency: balance.currency.value,
                            isSameCurrency: balance.currency.value == quickpayAPLookup?.amount.currency.value,
                            requestCurrencyBalanceExists: requestCurrencyBalanceExists(),
                            requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough()
                        ))
                        setSelectedBalance(balance)
                    }
                }
            )
        )
    }

    func makeInstantSuccessPromptViewModel(
        completion: @escaping () -> Void
    ) -> PayWithWiseSuccessPromptViewModel {
        let title = L10n.PayWithWise.Payment.PaymentSuccess.title
        let businessName = businessInfo.contact.title
        let message = PromptConfiguration.MessageConfiguration.text(L10n.PayWithWise.Payment.PaymentSuccess.newSubtitle(businessName))
        return PayWithWiseSuccessPromptViewModel(
            asset: .scene3D(.confetti),
            title: title,
            message: message,
            primaryButtonTitle: L10n.PayWithWise.Payment.PaymentSuccess.Button.title,
            completion: completion
        )
    }

    func makeNonInstantSuccessPromptViewModel(
        completion: @escaping () -> Void
    ) -> PayWithWiseSuccessPromptViewModel {
        PayWithWiseSuccessPromptViewModel(
            asset: .scene3D(.globe),
            title: L10n.PayWithWise.Payment.PaymentSuccess.NonInstant.title,
            message: .text(
                L10n.PayWithWise.Payment.PaymentSuccess.NonInstant.subtitle
            ),
            primaryButtonTitle: L10n.PayWithWise.Payment.PaymentSuccess.NonInstant.Button.title,
            completion: completion
        )
    }

    func handleSuccessfulPayment(
        balance: Balance,
        payment: PayWithWisePayment
    ) {
        let refreshHandler = { [weak self] in
            [
                NSNotification.Name.balancesNeedUpdate,
                NSNotification.Name.needsActivityListUpdate,
            ].forEach {
                self?.notificationCenter.post(
                    name: $0,
                    object: nil
                )
            }
        }
        let viewModel = {
            let completion = { [weak self] in
                guard let self else { return }
                refreshHandler()
                // We are gonna do a double tap here for refreshing activities
                // For the payments to the contacts it takes longer to update owed activity request status
                // Till BE founds a proper fix we will apply this hack
                scheduler.schedule(after: scheduler.now.advanced(by: 5)) {
                    refreshHandler()
                }
            }
            switch payment.resource.type {
            case .transfer:
                return makeInstantSuccessPromptViewModel(completion: completion)
            case .other:
                return makeNonInstantSuccessPromptViewModel(completion: completion)
            }
        }()
        router.showSuccess(viewModel: viewModel)
    }

    func updateProfile() {
        guard let selectedProfile = userProvider.activeProfile,
              profile.id != selectedProfile.id else {
            return
        }
        payWithWiseAnalyticsTracker.trackEvent(.profileChanged(profileType: mapProfileType(selectedProfile.type)))
        analyticsTracker.onProfileSelected()
        quote = nil
        selectedBalance = nil
        profile = selectedProfile
        quickpayAPLookup = nil
        updateAllData()
    }

    func handleTopupResult(_ result: TopUpBalanceFlowResult) {
        switch result {
        case .completed:
            isLoading = true
            // Added because of a delay between top-up service and balance amount
            payWithWiseAnalyticsTracker.trackEvent(.topUpCompleted(success: true))
            scheduler.schedule(after: scheduler.now.advanced(by: 9)) { [weak self] in
                self?.notificationCenter.post(
                    name: NSNotification.Name.balancesNeedUpdate,
                    object: nil
                )
                self?.updateAllData(needsBalanceRefresh: true)
            }
        case .aborted:
            payWithWiseAnalyticsTracker.trackEvent(.topUpCompleted(success: false))
        }
    }
}

// MARK: - Screen

private extension PayWithWiseQuickpayPresenterImpl {
    func updateScreen(alert: PayWithWiseViewModel.Alert?) {
        guard let quickpayAPLookup else {
            softFailure("[REC]: Tried to update PwW screen without lookup info")
            return
        }
        let inlineAlert: PayWithWiseViewModel.Alert? = {
            guard isEligible() else {
                return PayWithWiseViewModel.Alert(
                    viewModel: InlineAlertViewModel(
                        message: L10n.PayWithWise.Payment.Error.Message.ineligible
                    ),
                    style: .negative
                )
            }
            return alert
        }()

        let supportsProfileChange = userProvider.profiles.count > 1
        let balanceOptionsContainer = viewModelFactory.makeBalanceOptionsContainer(
            fundableBalances: fundableBalances,
            balances: balances
        )

        let viewModel = viewModelFactory.makeQuickpay(
            inlineAlert: inlineAlert,
            supportsProfileChange: supportsProfileChange,
            supportedPaymentMethods: quickpayAPLookup.paymentMethods,
            profile: profile,
            businessInfo: businessInfo,
            quickpayLookup: quickpayAPLookup,
            quote: quote,
            selectedBalance: selectedBalance,
            selectProfileAction: { [weak self] in
                self?.router.showProfileSwitcher {
                    self?.updateProfile()
                }
            },
            selectBalanceAction: { [weak self] in
                self?.startBalanceSelection(
                    container: balanceOptionsContainer
                )
            },
            firstButtonAction: { [weak self] in
                self?.pay()

            },
            secondButtonAction: { [weak self] in
                self?.showAlternativePaymentMethods(quickpayAPLookup: quickpayAPLookup)
            }
        )

        view?.configure(viewModel: viewModel)
    }
}

// MARK: - Error handling

private extension PayWithWiseQuickpayPresenterImpl {
    // swiftlint:disable:next cyclomatic_complexity
    func handleError(_ error: PayWithWiseV2Error) {
        switch error {
        // These are payment-request specific errors. Should never occur here. Use a generic error model.
        case .fetchingPaymentKeyFailed,
             .fetchingPaymentRequestInfoFailed,
             .downloadingAttachmentFailed,
             .savingAttachmentFailed,
             .fetchingSessionFailed,
             .payWithWisePaymentMethodNotAvailable,
             .rejectingPaymentFailed:
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        case .fetchingBalancesFailed,
             .fetchingFundableBalancesFailed:
            // these have no good error messages, so we throw generic as well
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        case let .creatingAcquiringPaymentFailed(error: error):
            // these can be specific error messages related to payment methods / amounts
            let viewModel = makeGenericErrorViewModel(message: error.message)
            view?.configure(viewModel: viewModel)
        case .noBalancesAvailable:
            let message = {
                guard let quickpayAPLookup else {
                    return L10n.Generic.Error.message
                }
                return L10n.PayWithWise.Payment.Error.Message.noOpenBalances(
                    quickpayAPLookup.amount.currency.value
                )
            }()
            updateScreen(
                alert: viewModelFactory.makeAlertViewModel(
                    message: message,
                    style: .negative,
                    action: nil
                )
            )
        case let .fetchingQuoteFailed(error: error):
            // retry
            handlePaymentError(error)
        case let .paymentFailed(error: error):
            handlePaymentError(error)
        case .fetchingAcquiringPaymentFailed:
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        case .payWithWiseNotAvailableOnQuickpay:
            let message = L10n.PayWithWise.Payment.Error.Message.payWithWiseNotAvailable
            updateScreen(
                alert: viewModelFactory.makeAlertViewModel(
                    message: message,
                    style: .negative,
                    action: nil
                )
            )
        }
    }

    func handlePaymentError(_ error: PayWithWisePaymentError) {
        switch error {
        case .targetIsSelf,
             .customError:
            updateScreen(
                alert: viewModelFactory.makeAlertViewModel(
                    message: error.localizedDescription,
                    style: .negative,
                    action: nil
                )
            )
        case let .sourceUnavailable(message):
            guard let presentationRoot = view?.presentationRootViewController else {
                return
            }
            updateScreen(
                alert: viewModelFactory.makeAlertViewModel(
                    message: message ?? error.localizedDescription,
                    style: .negative,
                    action: Action(
                        title: L10n.PayWithWise.Payment.TopUp.Action.title,
                        handler: { [weak self] in
                            guard let self else { return }

                            router.showTopUpFlow(
                                profile: profile,
                                targetAmount: quickpayAPLookup?.amount,
                                rootViewController: presentationRoot,
                                completion: { [weak self] result in
                                    self?.handleTopupResult(result)
                                }
                            )
                        }
                    )
                )
            )
        case .cancelledByUser:
            // Do nothing
            break
        case .other,
             .alreadyPaid:
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        }
    }

    var emptyErrorScreenButtonAction: Action {
        Action(
            title: L10n.PayWithWise.Payment.EmptyScreen.Action.title,
            handler: { [weak self] in
                self?.router.dismiss()
            }
        )
    }

    func makeGenericErrorViewModel(message: String? = nil) -> PayWithWiseViewModel {
        viewModelFactory.makeEmptyStateViewModel(
            image: Illustrations.exclamationMark.image,
            title: L10n.PayWithWise.Payment.Error.Title.generic,
            message: message ?? L10n.PayWithWise.Payment.Error.Message.generic,
            buttonAction: emptyErrorScreenButtonAction
        )
    }
}

// MARK: - Tracking

private extension PayWithWiseQuickpayPresenterImpl {
    func trackOnLoadedSuccess() {
        payWithWiseAnalyticsTracker
            .trackEvent(
                .loaded(
                    requestCurrency: quickpayAPLookup?.amount.currency.value ?? "null",
                    paymentCurrency: selectedBalance?.currency.value ?? "null",
                    isSameCurrency: quickpayAPLookup?.amount.currency.value == selectedBalance?.currency.value,
                    requestCurrencyBalanceExists: requestCurrencyBalanceExists(),
                    requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough(),
                    errorCode: nil,
                    errorMessage: nil
                )
            )
        payWithWiseAnalyticsTracker
            .trackEvent(
                .quoteCreated(
                    success: true,
                    requestCurrency: quote?.sourceAmount.currency.value ?? "null",
                    paymentCurrency: quote?.targetAmount.currency.value ?? "null",
                    amount: quote?.sourceAmount.value.doubleValue ?? -1.0
                )
            )
    }

    func trackOnLoadedFailure(error: PayWithWiseV2Error) {
        payWithWiseAnalyticsTracker
            .trackEvent(
                .loaded(
                    requestCurrency: quickpayAPLookup?.amount.currency.value ?? "null",
                    paymentCurrency: selectedBalance?.currency.value ?? "null",
                    isSameCurrency: quickpayAPLookup?.amount.currency.value == selectedBalance?.currency.value,
                    requestCurrencyBalanceExists: requestCurrencyBalanceExists(),
                    requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough(),
                    errorCode: mapErrorCode(error),
                    errorMessage: mapErrorMessage(error: error)
                )
            )

        if case .fetchingQuoteFailed = error {
            payWithWiseAnalyticsTracker
                .trackEvent(
                    .quoteCreated(
                        success: false,
                        requestCurrency: quote?.sourceAmount.currency.value ?? "null",
                        paymentCurrency: quote?.targetAmount.currency.value ?? "null",
                        amount: quote?.sourceAmount.value.doubleValue ?? -1.0
                    )
                )
        }
    }

    func trackOnLoadedWithError(error: PayWithWiseV2Error) {
        if let errorKey = mapErrorKey(error: error) {
            payWithWiseAnalyticsTracker
                .trackEvent(
                    .loadedWithError(errorCode: mapErrorMessage(error: error), errorKey: errorKey)
                )
        }
    }

    func mapErrorKey(error: PayWithWiseV2Error) -> PayWithWiseErrorKey? {
        switch error {
        case .fetchingPaymentKeyFailed:
            .FetchingPaymentKey()
        case .fetchingPaymentRequestInfoFailed:
            .FetchingPaymentRequest()
        case .fetchingAcquiringPaymentFailed:
            .FetchingPaymentKey()
        case .creatingAcquiringPaymentFailed:
            .FetchingPaymentKey()
        case .fetchingBalancesFailed:
            .FetchingBalances()
        case .fetchingFundableBalancesFailed:
            .FetchingBalances()
        case .noBalancesAvailable:
            .FetchingBalances()
        case .fetchingSessionFailed:
            .CreatingSession()
        case .fetchingQuoteFailed:
            .CreatingQuote()
        case .rejectingPaymentFailed:
            nil
        case .paymentFailed:
            nil
        case .payWithWisePaymentMethodNotAvailable:
            .FetchingPaymentRequest()
        case .downloadingAttachmentFailed,
             .savingAttachmentFailed:
            nil
        case .payWithWiseNotAvailableOnQuickpay:
            .FetchingPaymentRequest()
        }
    }

    func mapErrorMessage(error: PayWithWiseV2Error) -> String? {
        switch error {
        case let .fetchingPaymentKeyFailed(error):
            error.localizedDescription
        case let .fetchingPaymentRequestInfoFailed(error):
            error.errorDescription
        case .fetchingAcquiringPaymentFailed:
            "Fetching Acquiring Payment Failed"
        case let .creatingAcquiringPaymentFailed(error):
            error.message
        case .downloadingAttachmentFailed:
            "Downloading attachment Failed"
        case .savingAttachmentFailed:
            "Saving Attachement Failed"
        case .fetchingBalancesFailed:
            "Fetching Balanaces Failed"
        case .fetchingFundableBalancesFailed:
            "Fetching Fundable Balances Failed"
        case .noBalancesAvailable:
            "No balances available"
        case .fetchingSessionFailed:
            "Fetching Session Failed"
        case let .fetchingQuoteFailed(error):
            error.errorDescription
        case let .rejectingPaymentFailed(error):
            error.localizedDescription
        case let .paymentFailed(error):
            error.errorDescription
        case .payWithWisePaymentMethodNotAvailable:
            "Pay With Wise is not available on this quickpay link"
        case .payWithWiseNotAvailableOnQuickpay:
            "Pay With Wise is not available on this quickpay link"
        }
    }

    func mapMethodType(_ method: QuickpayAcquiringPayment.PaymentMethodType) -> PayerScreenPayerScreenMethod {
        switch method {
        case .card:
            .Card()
        case .payWithWise:
            .PayWithWise()
        case .pisp:
            .Pisp()
        }
    }

    func mapProfileType(_ profileType: ProfileType) -> PayWithWiseProfileType {
        switch profileType {
        case .business:
            .business
        case .personal:
            .personal
        }
    }

    func mapErrorCode(_ error: PayWithWiseV2Error) -> String {
        // swiftlint:disable:next cyclomatic_complexity
        switch error {
        case .fetchingPaymentKeyFailed:
            "Fetching Payment Key Failed"
        case .fetchingPaymentRequestInfoFailed:
            "Fetching Payment Request Info Failed"
        case .fetchingAcquiringPaymentFailed:
            "Fetching Acquiring Payment Failed"
        case .creatingAcquiringPaymentFailed:
            "Fetching Create Acquiring Payment Failed"
        case .downloadingAttachmentFailed:
            "Downloading Attachment Failed"
        case .savingAttachmentFailed:
            "Saving Attachment Failed"
        case .fetchingBalancesFailed:
            "Fetching Balances Failed"
        case .fetchingFundableBalancesFailed:
            "Fetching Fundable Balances Failed"
        case .noBalancesAvailable:
            "No Balances Available"
        case .fetchingSessionFailed:
            "Fetching Session Failed"
        case .fetchingQuoteFailed:
            "Fetching Quote Failed"
        case .rejectingPaymentFailed:
            "Rejecting Payment Failed"
        case .paymentFailed:
            "Payment Failed"
        case .payWithWisePaymentMethodNotAvailable:
            "Pay With Wise Not Available"
        case .payWithWiseNotAvailableOnQuickpay:
            "Pay With Wise Not Available On Quickpay"
        }
    }
}

// MARK: - Helpers

private extension PayWithWiseQuickpayPresenterImpl {
    func setSelectedBalance(_ balance: Balance) {
        selectedBalance = balance
        guard let quickpayAPLookup else { return }

        createQuoteCancellable = interactor.createQuickpayQuote(
            session: PaymentRequestSession(id: quickpayAPLookup.paymentSessionId.id),
            balanceId: balance.id,
            profileId: profile.id
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else { return }
            isLoading = false
            switch result {
            case let .success(quote):
                self.quote = quote
                updateScreen(alert: nil)
                payWithWiseAnalyticsTracker.trackEvent(.quoteCreated(
                    success: true,
                    requestCurrency: quickpayAPLookup.amount.currency.value,
                    paymentCurrency: selectedBalance?.currency.value ?? "null",
                    amount: NSDecimalNumber(decimal: quickpayAPLookup.amount.value).doubleValue
                ))
            case let .failure(error):
                handleError(error)
                payWithWiseAnalyticsTracker.trackEvent(.quoteCreated(
                    success: false,
                    requestCurrency: quickpayAPLookup.amount.currency.value,
                    paymentCurrency: selectedBalance?.currency.value ?? "null",
                    amount: NSDecimalNumber(decimal: quickpayAPLookup.amount.value).doubleValue
                ))
            }
        }
    }

    func isEligible() -> Bool {
        if profile.type == .business,
           !profile.has(privilege: TransferPrivilege.create) {
            return false
        }
        return true
    }

    func requestCurrencyBalanceExists() -> Bool {
        balances.contains {
            $0.currency == quickpayAPLookup?.amount.currency
        }
    }

    func requestCurrencyBalanceHasEnough() -> Bool {
        guard let quickpayAPLookup else { return false }
        let availableAmount = balances.first {
            $0.currency == quickpayAPLookup.amount.currency
        }?.availableAmount ?? 0

        return availableAmount >= quickpayAPLookup.amount.value
    }
}
