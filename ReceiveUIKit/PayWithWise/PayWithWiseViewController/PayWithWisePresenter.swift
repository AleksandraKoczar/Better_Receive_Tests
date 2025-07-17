import AnalyticsKit
import BalanceKit
import Combine
import CombineSchedulers
import ContactsKit
import LoggingKit
import Neptune
import Prism
import ReceiveKit
import TransferResources
import TWFoundation
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PayWithWisePresenter: AnyObject {
    func start(with view: PayWithWiseView)
    func showDetails()
    func dismiss()
}

final class PayWithWisePresenterImpl {
    private let interactor: PayWithWiseInteractor
    private let router: PayWithWiseRouter
    private let viewModelFactory: PayWithWiseViewModelFactory
    private let userProvider: UserProvider
    private let payWithWiseAnalyticsTracker: PayWithWiseAnalyticsTracker
    private let notificationCenter: NotificationCenter
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private weak var flowNavigationDelegate: PayWithWiseFlowNavigationDelegate?
    private weak var view: PayWithWiseView?

    private let source: PayWithWiseFlow.PaymentInitializationSource
    private var profile: Profile
    private var paymentRequestLookup: PaymentRequestLookup?
    private var paymentKey = ""
    private var session: PaymentRequestSession?
    private var quote: PayWithWiseQuote?

    private var balances: [Balance] = []
    private var fundableBalances: [Balance] = []
    private var selectedBalance: Balance?
    private var avatarModel: AvatarModel?

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

    private var createPaymentCancellable: AnyCancellable?
    private var rejectPaymentRequestCancellable: AnyCancellable?
    private var paymentCancellable: AnyCancellable?
    private var loadAttachmentCancellable: AnyCancellable?
    private var avatarFetchingCancellable: AnyCancellable?

    init(
        source: PayWithWiseFlow.PaymentInitializationSource,
        profile: Profile,
        interactor: PayWithWiseInteractor,
        router: PayWithWiseRouter,
        flowNavigationDelegate: PayWithWiseFlowNavigationDelegate?,
        viewModelFactory: PayWithWiseViewModelFactory,
        userProvider: UserProvider = GOS[UserProviderKey.self],
        payWithWiseAnalyticsTracker: PayWithWiseAnalyticsTracker = PayWithWiseAnalyticsTrackerImpl(),
        notificationCenter: NotificationCenter = .default,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.source = source
        self.profile = profile
        self.interactor = interactor
        self.router = router
        self.flowNavigationDelegate = flowNavigationDelegate
        self.viewModelFactory = viewModelFactory
        self.userProvider = userProvider
        self.notificationCenter = notificationCenter
        self.scheduler = scheduler
        self.payWithWiseAnalyticsTracker = payWithWiseAnalyticsTracker
    }
}

// MARK: - PayWithWisePresenter

extension PayWithWisePresenterImpl: PayWithWisePresenter {
    func start(with view: PayWithWiseView) {
        self.view = view

        payWithWiseAnalyticsTracker.trackPayerScreenEvent(.startedLoggedIn)
        payWithWiseAnalyticsTracker.trackPayerScreenEvent(.started(
            context: source.isRequestFromContact ? .Contact() : .Link(),
            paymentRequestType: source.isRequestFromContact ? .personal : .business,
            currency: nil
        ))

        updateAllData()
    }

    func showDetails() {
        guard let paymentRequestLookup else { return }

        payWithWiseAnalyticsTracker.trackEvent(.viewDetailsTapped)

        let rows = viewModelFactory.type().makeItems(
            paymentRequestLookup: paymentRequestLookup
        )
        let viewModel = PayWithWiseRequestDetailsView.ViewModel(
            title: L10n.PayWithWise.Payment.RequestDetails.Screen.title,
            rows: rows,
            buttonConfiguration: {
                guard let attachmentFile = paymentRequestLookup.attachmentFiles.first else {
                    return nil
                }
                return (
                    title: L10n.PayWithWise.Payment.RequestDetails.ViewInvoice.title,
                    handler: { [weak self] in
                        guard let self else { return }
                        payWithWiseAnalyticsTracker.trackEvent(.viewAttachmentTapped)
                        downloadAttachment(
                            attachmentFile: attachmentFile,
                            paymentRequestId: paymentRequestLookup.id
                        )
                    }
                )
            }()
        )
        router.showDetails(viewModel: viewModel)
    }

    func dismiss() {
        flowNavigationDelegate?.dismissed(at: .singlePagePayer)
    }
}

// MARK: - Execution pipeline

private extension PayWithWisePresenterImpl {
    func updateAllData(
        needsBalanceRefresh: Bool = false
    ) {
        isLoading = true

        let publisher =
            gatherPaymentKey()
                .flatMap { [unowned self] paymentKey in
                    updatePaymentRequestInfoPublisher(paymentKey: paymentKey)
                }
                .flatMap { [unowned self] paymentRequestLookup in
                    updateBalancesPublisher(
                        paymentRequestLookup: paymentRequestLookup,
                        needsRefresh: needsBalanceRefresh
                    )
                }
                .eraseToAnyPublisher()
        createPayment(publisher: publisher)
    }

    func createPayment(
        publisher: AnyPublisher<(PaymentRequestId, BalanceId), PayWithWiseV2Error>
    ) {
        isLoading = true
        createPaymentCancellable = publisher
            .flatMap { [unowned self] paymentRequestId, balanceId in
                interactor.createPayment(
                    paymentKey: paymentKey,
                    paymentRequestId: paymentRequestId,
                    balanceId: balanceId,
                    profileId: profile.id
                )
            }
            .flatMap { [unowned self] session, quote -> AnyPublisher<(PaymentRequestSession, PayWithWiseQuote, UIImage?), Never> in

                guard let urlString = paymentRequestLookup?.requester.avatarUrl,
                      let url = URL(string: urlString) else {
                    return .just((session, quote, nil))
                }
                return interactor.loadImage(url: url)
                    .map { image in
                        (session, quote, image)
                    }
                    .eraseToAnyPublisher()
            }
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else { return }
                isLoading = false
                switch result {
                case let .success((session, quote, image)):
                    if let image {
                        avatarModel = AvatarModel.image(image)
                    }
                    self.session = session
                    self.quote = quote
                    updateScreen(alert: nil)
                    trackOnLoadedSuccess()
                case let .failure(error):
                    handleError(error)
                    trackOnLoadedFailure(error: error)
                    trackOnLoadedWithError(error: error)
                }
            }
    }
}

// MARK: - Data

private extension PayWithWisePresenterImpl {
    func gatherPaymentKey() -> AnyPublisher<String, PayWithWiseV2Error> {
        guard paymentKey.isEmpty else {
            return .just(paymentKey)
        }
        return interactor.gatherPaymentKey(profileId: profile.id)
            .handleEvents(receiveOutput: { [unowned self] paymentKey in
                self.paymentKey = paymentKey
            })
            .eraseToAnyPublisher()
    }

    func updatePaymentRequestInfoPublisher(
        paymentKey: String
    ) -> AnyPublisher<PaymentRequestLookup, PayWithWiseV2Error> {
        if let paymentRequestLookup {
            return .just(paymentRequestLookup)
        }

        return interactor.paymentRequestLookup(
            paymentKey: paymentKey
        )
        .handleEvents(receiveOutput: { [unowned self] paymentRequestLookup in
            self.paymentRequestLookup = paymentRequestLookup
        })
        .flatMap { paymentRequestLookup -> AnyPublisher<PaymentRequestLookup, PayWithWiseV2Error> in
            guard Self.supportedPaymentMethods(paymentRequestLookup: paymentRequestLookup).contains(.payWithWise) else {
                return .fail(
                    with: PayWithWiseV2Error.payWithWisePaymentMethodNotAvailable(
                        paymentRequestLookup: paymentRequestLookup
                    )
                )
            }
            return .just(paymentRequestLookup)
        }
        .eraseToAnyPublisher()
    }

    func updateBalancesPublisher(
        paymentRequestLookup: PaymentRequestLookup,
        needsRefresh: Bool
    ) -> AnyPublisher<(PaymentRequestId, BalanceId), PayWithWiseV2Error> {
        interactor.balances(
            amount: paymentRequestLookup.amount,
            profileId: profile.id,
            needsRefresh: needsRefresh
        )
        .handleEvents(receiveOutput: { [unowned self] fetchResult in
            balances = fetchResult.balances
            fundableBalances = fetchResult.fundableBalances
            selectedBalance = fetchResult.autoSelectionResult.balance
        })
        .map { fetchResult in
            (paymentRequestLookup.id, fetchResult.autoSelectionResult.balance.id)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Actions

private extension PayWithWisePresenterImpl {
    func pay() {
        guard let paymentRequestLookup,
              let session,
              let selectedBalance else {
            softFailure("[REC]: Tried to make payment without session or balance")
            return
        }

        payWithWiseAnalyticsTracker.trackPayerScreenEvent(.paymentMethodSelected(method: .PayWithWise()))

        payWithWiseAnalyticsTracker.trackEvent(.payTapped(
            requestCurrency: paymentRequestLookup.amount.currency.value,
            paymentCurrency: selectedBalance.currency.value,
            profileType: mapProfileType(profile.type)
        ))

        makePayment(session: session, balance: selectedBalance)
    }

    func handleSecondaryAction() {
        guard let paymentRequestLookup else { return }
        if source.isRequestFromContact {
            showRejectConfirmation(paymentRequestLookup: paymentRequestLookup)
        } else {
            showAlternativePaymentMethods(paymentRequestLookup: paymentRequestLookup)
        }
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
            case let .failure(error):
                if let lookup = paymentRequestLookup {
                    let errorMessage = {
                        if case let PayWithWiseV2Error.paymentFailed(err) = error {
                            return err.localizedDescription
                        }
                        return error.localizedDescription
                    }()

                    payWithWiseAnalyticsTracker.trackEvent(.payFailed(paymentRequestId: lookup.id.value, message: errorMessage))
                }

                handleError(error)
            }
        }
    }

    func rejectPaymentRequest(paymentRequestLookup: PaymentRequestLookup) {
        isLoading = true
        rejectPaymentRequestCancellable = interactor.rejectRequest(
            paymentRequestId: paymentRequestLookup.id,
            profileId: profile.id
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else { return }
            isLoading = false
            switch result {
            case .success:
                router.showRejectSuccess(profileId: profile.id)
            case let .failure(error):
                handleError(error)
            }
        }
    }

    func downloadAttachment(
        attachmentFile: PayerAttachmentFile,
        paymentRequestId: PaymentRequestId
    ) {
        isLoading = true
        loadAttachmentCancellable = interactor.loadAttachment(
            paymentKey: paymentKey,
            attachmentFile: attachmentFile,
            paymentRequestId: paymentRequestId
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else { return }
            isLoading = false
            switch result {
            case let .success(url):
                if let delegate = view?.documentDelegate {
                    router.showAttachment(
                        url: url,
                        delegate: delegate
                    )
                }
            case let .failure(error):
                payWithWiseAnalyticsTracker.trackEvent(.attachmentLoadingFailed(message: mapErrorCode(error)))
                handleError(error)
            }
        }
    }

    func showRejectConfirmation(paymentRequestLookup: PaymentRequestLookup) {
        payWithWiseAnalyticsTracker.trackEvent(.declineTapped(requestCurrencyBalanceExists: requestCurrencyBalanceExists()))

        let viewModel = viewModelFactory.type().makeRejectConfirmationModel(
            confirmAction: { [weak self] in
                guard let self else { return }
                payWithWiseAnalyticsTracker.trackEvent(.declineConfirmed)
                rejectPaymentRequest(
                    paymentRequestLookup: paymentRequestLookup
                )
            },
            cancelAction: {}
        )
        router.showRejectConfirmation(viewModel: viewModel)
    }

    func showAlternativePaymentMethods(paymentRequestLookup: PaymentRequestLookup) {
        guard paymentRequestLookup.availablePaymentMethods.isNonEmpty else {
            return
        }

        payWithWiseAnalyticsTracker.trackEvent(.payAnotherWayTapped(
            requestCurrency: paymentRequestLookup.amount.currency.value,
            requestCurrencyBalanceExists: requestCurrencyBalanceExists(),
            requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough()
        ))

        if paymentRequestLookup.availablePaymentMethods.count == 1,
           let method = paymentRequestLookup.availablePaymentMethods.first {
            showPaymentMethod(method: method)
        } else {
            router.showPaymentMethodsBottomSheet(
                paymentMethods: paymentRequestLookup.availablePaymentMethods,
                requesterName: paymentRequestLookup.requester.fullName,
                completion: { [weak self] method in
                    self?.showPaymentMethod(method: method)
                }
            )
        }
    }

    func showPaymentMethod(method: PayerAcquiringPaymentMethod) {
        payWithWiseAnalyticsTracker.trackPayerScreenEvent(.paymentMethodSelected(method: mapMethodType(method.type)))

        router.showPaymentMethod(
            profileId: profile.id,
            paymentMethod: method,
            paymentKey: paymentKey
        )
    }
}

// MARK: - Action handlers

private extension PayWithWisePresenterImpl {
    func startBalanceSelection(
        container: PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer
    ) {
        let sections = viewModelFactory.makeBalanceSections(
            container: container
        )

        payWithWiseAnalyticsTracker.trackEvent(.balanceSelectorOpened(noOfBalances: Int64(container.fundables.count + container.nonFundables.count)))

        router.showBalanceSelector(
            viewModel: PayWithWiseBalanceSelectorViewModel(
                title: L10n.PayWithWise.Payment.Balance.Selector.title,
                sections: sections,
                selectAction: { [weak self] indexPath in
                    guard let self else { return }
                    // Only available balances section should be selectable
                    if indexPath.section == 0 {
                        router.dismissBalanceSelector()
                        guard let lookup = paymentRequestLookup,
                              let balance = balances.first(where: {
                                  $0.id == container.fundables[safe: indexPath.row]?.id
                              }) else {
                            return
                        }

                        payWithWiseAnalyticsTracker
                            .trackEvent(
                                .balanceSelected(
                                    requestCurrency: lookup.amount.currency.value,
                                    paymentCurrency: balance.currency.value,
                                    isSameCurrency: lookup.amount.currency.value == balance.currency.value,
                                    requestCurrencyBalanceExists: requestCurrencyBalanceExists(),
                                    requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough()
                                )
                            )
                        setSelectedBalance(balance)
                    }
                }
            )
        )
    }

    func setSelectedBalance(_ balance: Balance) {
        selectedBalance = balance
        guard let paymentRequestId = paymentRequestLookup?.id else { return }
        createPayment(
            publisher: .just((paymentRequestId, balance.id))
        )
    }

    func makeInstantSuccessPromptViewModel(
        completion: @escaping () -> Void
    ) -> PayWithWiseSuccessPromptViewModel {
        let title = source.isRequestFromContact
            ? L10n.PayWithWise.Payment.PaymentSuccess.ForContact.title
            : L10n.PayWithWise.Payment.PaymentSuccess.title
        let linkText = L10n.PayWithWise.Payment.PaymentSuccess.Subtitle.PromoteRequestMoney.link
        let message = PromptConfiguration.MessageConfiguration.textWithLink(
            text: L10n.PayWithWise.Payment.PaymentSuccess.Subtitle.promoteRequestMoney(linkText),
            linkText: linkText,
            action: { [weak self] in
                guard let self else {
                    return
                }
                router.showRequestMoney(profile: profile)
            }
        )
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
        guard let paymentRequestLookup else { return }

        payWithWiseAnalyticsTracker.trackEvent(.paySucceed(
            requestType: mapRequestType(request: source),
            requestCurrency: paymentRequestLookup.amount.currency.value,
            paymentCurrency: balance.currency.value
        ))

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
        quote = nil
        selectedBalance = nil
        profile = selectedProfile
        updateAllData()
    }

    func handleTopupResult(_ result: TopUpBalanceFlowResult) {
        switch result {
        case .completed:
            isLoading = true

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

private extension PayWithWisePresenterImpl {
    func updateScreen(alert: PayWithWiseViewModel.Alert?) {
        guard let paymentRequestLookup else {
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

        let supportsProfileChange = userProvider.profiles.count > 1 && !source.isRequestFromContact
        let balanceOptionsContainer = viewModelFactory.makeBalanceOptionsContainer(
            fundableBalances: fundableBalances,
            balances: balances
        )

        let viewModel = viewModelFactory.make(
            source: source,
            inlineAlert: inlineAlert,
            supportsProfileChange: supportsProfileChange,
            supportedPaymentMethods: Self.supportedPaymentMethods(
                paymentRequestLookup: paymentRequestLookup
            ),
            profile: profile,
            paymentRequestLookup: paymentRequestLookup,
            avatar: avatarModel,
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
                self?.handleSecondaryAction()
            }
        )
        view?.configure(viewModel: viewModel)
    }
}

// MARK: - Error handling

private extension PayWithWisePresenterImpl {
    // swiftlint:disable:next cyclomatic_complexity
    func handleError(_ error: PayWithWiseV2Error) {
        switch error {
        case .fetchingPaymentKeyFailed:
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        case let .fetchingPaymentRequestInfoFailed(err):
            handleFetchingPaymentRequestInfoError(err)
        case .downloadingAttachmentFailed,
             .savingAttachmentFailed:
            view?.showErrorAlert(
                title: L10n.PaymentRequest.Detail.Error.title,
                message: L10n.PaymentRequest.Detail.Error.Download.subtitle
            )
        case .fetchingBalancesFailed,
             .fetchingFundableBalancesFailed:
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        case .noBalancesAvailable:
            let message = {
                guard let paymentRequestLookup else {
                    return L10n.Generic.Error.message
                }
                return L10n.PayWithWise.Payment.Error.Message.noOpenBalances(
                    paymentRequestLookup.amount.currency.value
                )
            }()
            guard let presentationRoot = view?.presentationRootViewController else {
                return
            }
            updateScreen(
                alert: viewModelFactory.makeAlertViewModel(
                    message: message,
                    style: .negative,
                    action: Action(
                        title: L10n.PayWithWise.Payment.TopUp.Action.title,
                        handler: { [weak self] in
                            guard let self else { return }

                            payWithWiseAnalyticsTracker.trackEvent(.topUpTapped)
                            router.showTopUpFlow(
                                profile: profile,
                                targetAmount: paymentRequestLookup?.amount,
                                rootViewController: presentationRoot,
                                completion: { [weak self] result in
                                    self?.handleTopupResult(result)
                                }
                            )
                        }
                    )
                )
            )
        case .fetchingSessionFailed:
            // Retryable
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        case let .fetchingQuoteFailed(error: error):
            // Retryable
            handlePaymentError(error)
        case .rejectingPaymentFailed:
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        case let .paymentFailed(error: error):
            handlePaymentError(error)
        case let .payWithWisePaymentMethodNotAvailable(lookup):
            paymentRequestLookup = lookup
            updateScreen(alert: nil)
        case .fetchingAcquiringPaymentFailed:
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        case .payWithWiseNotAvailableOnQuickpay:
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        case .creatingAcquiringPaymentFailed:
            let viewModel = makeGenericErrorViewModel()
            view?.configure(viewModel: viewModel)
        }
    }

    func handleFetchingPaymentRequestInfoError(
        _ error: PayWithWisePaymentRequestInfoError
    ) {
        switch error {
        case .alreadyPaid:
            let viewModel = makeAlreadyPaidErrorViewModel(
                message: error.localizedDescription
            )
            view?.configure(viewModel: viewModel)
        case let .expired(message):
            let viewModel = viewModelFactory.makeEmptyStateViewModel(
                image: Illustrations.electricPlug.image,
                title: L10n.PayWithWise.Payment.Error.Title.expired,
                message: message ?? L10n.PayWithWise.Payment.Error.Message.expired,
                buttonAction: emptyErrorScreenButtonAction
            )
            view?.configure(viewModel: viewModel)
        case let .invalidated(message):
            let viewModel = makeGenericErrorViewModel(message: message)
            view?.configure(viewModel: viewModel)
        case let .other(error):
            let viewModel = makeGenericErrorViewModel(
                message: error.localizedDescription
            )
            view?.configure(viewModel: viewModel)
        case let .unknown(message):
            let viewModel = makeGenericErrorViewModel(message: message)
            view?.configure(viewModel: viewModel)
        case let .notFound(message):
            let viewModel = makeGenericErrorViewModel(message: message)
            view?.configure(viewModel: viewModel)
        case .rejectingPaymentRequestFailed,
             .fetchingPaymentKeyFailed:
            // Irrelevant to this case and will be removed with old screen
            break
        }
    }

    func handlePaymentError(_ error: PayWithWisePaymentError) {
        switch error {
        case .alreadyPaid:
            let viewModel = makeAlreadyPaidErrorViewModel(
                message: error.localizedDescription
            )
            view?.configure(viewModel: viewModel)
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
                            payWithWiseAnalyticsTracker.trackEvent(.topUpTapped)
                            router.showTopUpFlow(
                                profile: profile,
                                targetAmount: paymentRequestLookup?.amount,
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
        case .other:
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

    func makeAlreadyPaidErrorViewModel(message: String?) -> PayWithWiseViewModel {
        viewModelFactory.makeEmptyStateViewModel(
            image: Illustrations.receive.image,
            title: L10n.PayWithWise.Payment.Error.Title.alreadyPaid,
            message: message ?? L10n.PayWithWise.Payment.Error.Message.alreadyPaid,
            buttonAction: emptyErrorScreenButtonAction
        )
    }
}

// MARK: - Analytics

private extension PayWithWisePresenterImpl {
    func trackOnLoadedSuccess() {
        payWithWiseAnalyticsTracker
            .trackEvent(
                .loaded(
                    requestCurrency: paymentRequestLookup?.amount.currency.value ?? "null",
                    paymentCurrency: quote?.sourceAmount.currency.value ?? "null",
                    isSameCurrency: paymentRequestLookup?.amount.currency.value == quote?.sourceAmount.currency.value,
                    requestCurrencyBalanceExists: requestCurrencyBalanceExists(),
                    requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough(),
                    errorCode: nil,
                    errorMessage: nil
                )
            )
    }

    func trackOnLoadedFailure(error: PayWithWiseV2Error) {
        payWithWiseAnalyticsTracker
            .trackEvent(
                .loaded(
                    requestCurrency: paymentRequestLookup?.amount.currency.value ?? "null",
                    paymentCurrency: quote?.sourceAmount.currency.value ?? "null",
                    isSameCurrency: paymentRequestLookup?.amount.currency.value == quote?.sourceAmount.currency.value,
                    requestCurrencyBalanceExists: requestCurrencyBalanceExists(),
                    requestCurrencyBalanceHasEnough: requestCurrencyBalanceHasEnough(),
                    errorCode: mapErrorCode(error),
                    errorMessage: mapErrorMessage(error: error)
                )
            )
    }

    func mapErrorMessage(error: PayWithWiseV2Error) -> String? {
        switch error {
        case let .fetchingPaymentKeyFailed(error):
            error.localizedDescription
        case let .fetchingPaymentRequestInfoFailed(error):
            error.errorDescription
        case .fetchingAcquiringPaymentFailed:
            "Fetching Acquiring Payment Failed"
        case .creatingAcquiringPaymentFailed:
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
            "Pay With Wise is not available on this request link"
        case .payWithWiseNotAvailableOnQuickpay:
            "Pay With Wise is not available on this request link"
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

    func mapRequestType(request: PayWithWiseFlow.PaymentInitializationSource) -> PayWithWiseRequestType {
        switch source {
        case .quickpay: .QuickPay()
        case .paymentKey(.contact): .Contact()
        case .paymentKey(.request): .Link()
        case .paymentRequestId: .Contact()
        }
    }

    func mapMethodType(_ method: AcquiringPaymentMethodType) -> PayerScreenPayerScreenMethod {
        switch method {
        case .applePay:
            .ApplePay()
        case .bankTransfer:
            .BankTransfer()
        case .card:
            .Card()
        case .payWithWise:
            .PayWithWise()
        case .payNow:
            .PayNow()
        case .pisp:
            .Pisp()
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

private extension PayWithWisePresenterImpl {
    func isEligible() -> Bool {
        if profile.type == .business,
           !profile.has(privilege: TransferPrivilege.create) {
            return false
        }
        return true
    }

    static func supportedPaymentMethods(paymentRequestLookup: PaymentRequestLookup) -> [AcquiringPaymentMethodType] {
        paymentRequestLookup.availablePaymentMethods
            .map { $0.type }
    }

    func requestCurrencyBalanceExists() -> Bool {
        balances.contains {
            $0.currency == paymentRequestLookup?.amount.currency
        }
    }

    func requestCurrencyBalanceHasEnough() -> Bool {
        guard let paymentRequestLookup else { return false }
        let availableAmount = balances.first {
            $0.currency == paymentRequestLookup.amount.currency
        }?.availableAmount ?? -1

        return availableAmount >= paymentRequestLookup.amount.value
    }
}

private typealias AnalyticsView = PayWithWisePayerAnalyticsView
