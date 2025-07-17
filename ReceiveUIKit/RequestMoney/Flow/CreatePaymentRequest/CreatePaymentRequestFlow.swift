import AnalyticsKit
import ApiKit
import Combine
import CombineSchedulers
import ContactsKit
import DynamicFlow
import DynamicFlowKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UserKit
import WiseCore

final class CreatePaymentRequestFlow: Flow {
    var flowHandler: FlowHandler<CreatePaymentRequestFlowResult> = .empty
    private var dismisser: ViewControllerDismisser?
    private var paymentMethodsSheetDismisser: ViewControllerDismisser?
    private var webMethodsManagementDismisser: ViewControllerDismisser?
    private let presenterFactory: ViewControllerPresenterFactory
    private let viewControllerFactory: CreatePaymentRequestViewControllerFactory
    private let entryPoint: EntryPoint
    private let profile: Profile
    private let contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory
    private let inviteFlowFactory: ReceiveInviteFlowFactory
    private let paymentRequestUseCase: PaymentRequestUseCaseV2
    private let flowTracker: CreatePaymentRequestFlowAnalyticsTracker
    private let analyticsTracker: AnalyticsTracker
    private let userProvider: UserProvider
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let cardOnboardingFlowFactory: RequestMoneyCardOnboardingFlowFactory
    private let payWithWiseEducationFlowFactory: RequestMoneyPayWithWiseEducationFlowFactory
    private let accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory
    private let paymentMethodsDynamicFlowHandler: PaymentMethodsDynamicFlowHandler
    private let dynamicFlowFactory: TWDynamicFlowFactory
    private let findFriendsFlowFactory: FindFriendsFlowFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let defaultBalance: PaymentRequestEligibleBalances.Balance
    private let eligibleBalances: PaymentRequestEligibleBalances
    private let preSelectedBalanceCurrencyCode: CurrencyCode?
    private let bottomSheetPresenter: BottomSheetPresenter

    private var pushPresenter: NavigationViewControllerPresenter
    private var contact: RequestMoneyContact?

    private var cardOnboardingFlow: (any Flow<RequestMoneyCardOnboardingFlowResult>)?
    private var payWithWiseEducationFlow: (any Flow<RequestMoneyPayWithWiseEducationFlowResult>)?
    private var accountDetailsCreationFlow: (any Flow<ReceiveAccountDetailsCreationFlowResult>)?
    private var findFriendsFlow: (any Flow<Void>)?
    private var inviteFlow: (any Flow<Void>)?

    private var methodManagementDynamicFlow: (any Flow<Result<DynamicFormResponse?, FlowFailure>>)?
    private var dynamicFlow: (any Flow<Result<DynamicFormResponse?, FlowFailure>>)?
    private let navigationController: UINavigationController

    private var publishPaymentRequestCancellable: AnyCancellable?
    private var contactSearchCancellable: AnyCancellable?
    private var addAmountAndNoteDismisser: ViewControllerDismisser?
    private var requestFromAnyoneDismiser: ViewControllerDismisser?

    init(
        entryPoint: EntryPoint,
        profile: Profile,
        contact: RequestMoneyContact?,
        preSelectedBalanceCurrencyCode: CurrencyCode?,
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances,
        contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory,
        paymentMethodsDynamicFlowHandler: PaymentMethodsDynamicFlowHandler,
        webViewControllerFactory: WebViewControllerFactory.Type,
        navController: UINavigationController,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        paymentRequestUseCase: PaymentRequestUseCaseV2 = PaymentRequestUseCaseFactoryV2.make(),
        presenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl(),
        cardOnboardingFlowFactory: RequestMoneyCardOnboardingFlowFactory = RequestMoneyCardOnboardingFlowFactoryImpl(),
        payWithWiseEducationFlowFactory: RequestMoneyPayWithWiseEducationFlowFactory = RequestMoneyPayWithWiseEducationFlowFactoryImpl(),
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        findFriendsFlowFactory: FindFriendsFlowFactory,
        viewControllerFactory: CreatePaymentRequestViewControllerFactory,
        inviteFlowFactory: ReceiveInviteFlowFactory,
        dynamicFlowFactory: TWDynamicFlowFactory = TWDynamicFlowFactory(),
        userProvider: UserProvider = GOS[UserProviderKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        navigationController = navController
        self.presenterFactory = presenterFactory
        self.entryPoint = entryPoint
        self.profile = profile
        self.contact = contact
        self.preSelectedBalanceCurrencyCode = preSelectedBalanceCurrencyCode
        self.defaultBalance = defaultBalance
        self.eligibleBalances = eligibleBalances
        self.contactSearchViewControllerFactory = contactSearchViewControllerFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.analyticsTracker = analyticsTracker
        self.paymentRequestUseCase = paymentRequestUseCase
        self.cardOnboardingFlowFactory = cardOnboardingFlowFactory
        self.payWithWiseEducationFlowFactory = payWithWiseEducationFlowFactory
        self.accountDetailsCreationFlowFactory = accountDetailsCreationFlowFactory
        self.findFriendsFlowFactory = findFriendsFlowFactory
        self.viewControllerFactory = viewControllerFactory
        self.inviteFlowFactory = inviteFlowFactory
        self.dynamicFlowFactory = dynamicFlowFactory
        self.userProvider = userProvider
        self.scheduler = scheduler
        self.paymentMethodsDynamicFlowHandler = paymentMethodsDynamicFlowHandler
        pushPresenter = presenterFactory.makePushPresenter(navigationController: navController)
        bottomSheetPresenter = presenterFactory.makeBottomSheetPresenter(parent: navController)
        flowTracker = CreatePaymentRequestFlowAnalyticsTracker(
            contextIdentity: CreatePaymentRequestFlowAnalytics.identity,
            analyticsTracker: analyticsTracker
        )
        flowTracker.register([CreatePaymentRequestFlowAnalytics.FlowVariantProperty(value: profile.type)])
    }

    func start() {
        flowHandler.flowStarted()
        let properties: [AnalyticsProperty] = {
            let initiatedWithContact = (contact != nil)
            let _prop: [AnalyticsProperty?] = [
                CreatePaymentRequestFlowAnalytics.EntryPoint(entryPoint: entryPoint),
                CreatePaymentRequestFlowAnalytics.InitiatedWithContact(value: initiatedWithContact),
                CreatePaymentRequestFlowAnalytics.IsContactRequestEligible(value: isContactRequestEligible),
                CreatePaymentRequestFlowAnalytics.InitiatedWithCurrency(currencyCode: preSelectedBalanceCurrencyCode),
                CreatePaymentRequestFlowAnalytics.CurrencyProperty(values: eligibleBalances.balances.map(\.currency)),
            ]
            return _prop
                .compactMap { $0 }
        }()
        flowTracker.trackFlow(.started, properties: properties)
        showOnboarding()
    }

    func terminate() {
        flowFinished(result: .aborted)
    }
}

// MARK: - Private

private extension CreatePaymentRequestFlow {
    func startInviteFlow() {
        let flow = inviteFlowFactory.make(navigationHost: navigationController)
        flow.onFinish { [weak self] _, _ in
            self?.inviteFlow = nil
        }

        inviteFlow = flow
        flow.start()
    }
}

// MARK: - PaymentRequestOnboardingRoutingDelegate

extension CreatePaymentRequestFlow: PaymentRequestOnboardingRoutingDelegate {
    func moveToNextStepAfterOnboarding(isOnboardingRequired: Bool) {
        let isFirstStep = !isOnboardingRequired
        if shouldShowContactPicker {
            showContactPicker(isFirstStep: isFirstStep)
        } else {
            switch profile.type {
            case .business:
                showCreatePaymentRequestBusiness(isFirstStep: isFirstStep)
            case .personal:
                showCreatePaymentRequestPersonal(isFirstStep: isFirstStep)
            }
        }
    }

    // This `dismiss` method satisfies multiple router protocols
    // Currently all of them have the same purpose
    func dismiss() {
        terminate()
    }
}

// MARK: - RequestMoneyContactPickerRouter

extension CreatePaymentRequestFlow: RequestMoneyContactPickerRouter {
    func findFriendsNudgeTapped() {
        let flow = findFriendsFlowFactory.makeFlow(navigationController: navigationController)
        flow.onFinish { [weak self] _, _ in
            self?.findFriendsFlow = nil
        }

        findFriendsFlow = flow
        flow.start()
    }

    func inviteFriendsNudgeTapped() {
        startInviteFlow()
    }

    func createPaymentRequest(contact: Contact?) {
        self.contact = RequestMoneyContact(contact: contact)
        showCreatePaymentRequestPersonal(isFirstStep: false)
    }

    func startSearch() {
        let searchAnalyticsTracker = AnalyticsViewTrackerImpl<RequestMoneyContactPickerSearchAnalyticsView>(
            contextIdentity: RequestMoneyContactPickerSearchAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
        let makeResult = contactSearchViewControllerFactory.makeContactSearch(
            profile: profile,
            navigationController: navigationController
        )
        contactSearchCancellable = makeResult.resultPublisher
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else { return }
                searchAnalyticsTracker.track(
                    RequestMoneyContactPickerSearchAnalyticsView.SearchFinishedAction(
                        result: result
                    )
                )
                switch result {
                case let .selected(contact):
                    createPaymentRequest(contact: contact)
                case .selectedContinueWithLink:
                    createPaymentRequest(contact: nil)
                case .finishedWithoutSelection:
                    navigationController.popViewController(
                        animated: UIView.shouldAnimate
                    )
                }
            }

        searchAnalyticsTracker.trackView(.started)
        pushPresenter.keepOnlyLastViewControllerOnStack = false
        pushPresenter.present(viewController: makeResult.viewController)
    }
}

// MARK: - RequestFromAnyoneRoutingDelegate

extension CreatePaymentRequestFlow: RequestFromAnyoneRoutingDelegate {
    func endFlow() {
        requestFromAnyoneDismiser?.dismiss(animated: false, completion: { [weak self] in
            guard let self else { return }
            flowFinished(result: .aborted)
        })
    }

    func addAmountAndNote() {
        let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
            defaultBalance: defaultBalance,
            eligibleBalances: eligibleBalances,
            contact: contact
        )

        let viewController = viewControllerFactory.makeCreatePaymentRequestPersonalBottomSheet(
            paymentRequestInfo: paymentRequestInfo,
            profile: profile,
            routingDelegate: self
        )

        addAmountAndNoteDismisser = bottomSheetPresenter.present(viewController: viewController)
    }

    func useOldFlow() {
        requestFromAnyoneDismiser?.dismiss(animated: false, completion: { [weak self] in
            guard let self else { return }
            let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
                defaultBalance: defaultBalance,
                eligibleBalances: eligibleBalances,
                contact: contact
            )
            let viewController = viewControllerFactory.makeCreatePaymentRequestPersonal(
                paymentRequestInfo: paymentRequestInfo,
                profile: profile,
                routingDelegate: self
            )
            pushPresenter.keepOnlyLastViewControllerOnStack = false
            pushPresenter.present(viewController: viewController, animated: true)
        })
    }
}

// MARK: - CreatePaymentRequestRoutingDelegate for Personal and Business

extension CreatePaymentRequestFlow: CreatePaymentRequestRoutingDelegate, CreatePaymentRequestPersonalRoutingDelegate {
    func showDynamicFormsMethodManagement(
        _ dynamicForms: [PaymentMethodDynamicForm],
        delegate: PaymentMethodsDelegate?
    ) {
        paymentMethodsSheetDismisser?.dismiss()
        paymentMethodsDynamicFlowHandler.showDynamicForms(dynamicForms, delegate: delegate)
    }

    enum Constants {
        static let exitReasonFlowCompleted = "FLOW_COMPLETED"
        static let paymentMethodManagementUrlPath = "/payments/method-management"
    }

    func handleDynamicForms(
        forms dynamicForms: [PaymentMethodAvailability.DynamicForm],
        completionHandler: @escaping () -> Void
    ) {
        guard let dynamicForm = dynamicForms.first else {
            completionHandler()
            return
        }

        let flow = makeDynamicFlow(flowId: dynamicForm.flowId, url: dynamicForm.url)
        flow.onFinish { [weak self] result, dismisser in
            dismisser?.dismiss(animated: false)
            guard let self else {
                return
            }
            dynamicFlow = nil
            switch result {
            case let .success(optionalResponse):
                showNextDynamicFormIfNeeded(
                    optionalResponse: optionalResponse,
                    dynamicForms: dynamicForms,
                    completionHandler: completionHandler
                )
            case .failure:
                return
            }
        }
        dynamicFlow = flow
        flow.start()
    }

    func showCurrencySelector(
        activeCurrencies: [CurrencyCode],
        eligibleCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: @escaping (CurrencyCode) -> Void
    ) {
        func filterSearchResults(_ currencies: [CurrencyCode]) -> (_ query: String) -> CurrencyList<CurrencyCode> {
            let searchResultsFilter: ([CurrencyCode], String) -> ([CurrencyCode]) = { input, query in
                input
                    .filter { $0.value.uppercased().hasPrefix(query) || $0.localizedCurrencyName.containsCaseInsensitive(query) }
            }
            return { query in
                SearchResultsCurrenciesList(filtered: searchResultsFilter(currencies, query), searchQuery: query)
            }
        }

        let availables = Array(
            Set(eligibleCurrencies)
                .subtracting(Set(activeCurrencies))
                .sorted(by: \.value)
        )

        let currencySelector = CurrencySelectorFactoryImpl.make(
            items: SectionedCurrenciesList([
                .init(
                    title: L10n.Convertbalance.CurrencyPicker.yourBalances,
                    currencies: activeCurrencies
                ),
                .init(
                    title: L10n.PaymentRequest.Create.CurrencySelector.Eligible.Section.title,
                    currencies: availables
                ),
            ]),
            configuration: CurrencySelectorConfiguration(selectedItem: selectedCurrency),
            searchResultsFilter: filterSearchResults(activeCurrencies + availables),
            onSelect: onCurrencySelected,
            onDismiss: nil
        )
        navigationController.visibleViewController?.present(
            currencySelector,
            animated: UIView.shouldAnimate
        )
    }

    func showAccountDetailsFlow(
        currencyCode: CurrencyCode
    ) -> AnyPublisher<Void, Never> {
        let subject = PassthroughSubject<Void, Never>()
        let flow = accountDetailsCreationFlowFactory.makeForReceive(
            shouldClearNavigation: true,
            source: .requestFlow,
            currencyCode: currencyCode,
            profile: profile,
            navigationHost: navigationController
        )
        flow.onFinish { [weak self] result, dismisser in
            guard let self else {
                return
            }
            dismisser?.dismiss()
            accountDetailsCreationFlow = nil
            switch result {
            case .successful:
                subject.send(())
            case .interrupted:
                break
            }
        }
        accountDetailsCreationFlow = flow
        flow.start()
        return subject.eraseToAnyPublisher()
    }

    func showConfirmation(paymentRequest: PaymentRequestV2) {
        guard let addAmountAndNoteDismisser else {
            publishPaymentRequestIfNeeded(paymentRequestId: paymentRequest.id) { [weak self] paymentRequest in
                self?.showConfirmationScreenAfterPublishingPaymentRequest(paymentRequest: paymentRequest)
            }
            return
        }

        addAmountAndNoteDismisser.dismiss(animated: true, completion: { [weak self] in
            self?.publishPaymentRequestIfNeeded(paymentRequestId: paymentRequest.id) { [weak self] paymentRequest in
                self?.showConfirmationScreenAfterPublishingPaymentRequest(paymentRequest: paymentRequest)
            }
        })
    }

    func showPaymentMethodsSheet(
        delegate: PaymentMethodsDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        methods: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        completion: @escaping (([PaymentRequestV2PaymentMethods]) -> Void)
    ) {
        let vc = viewControllerFactory.makePaymentMethodsSelection(
            delegate: delegate,
            routingDelegate: self,
            localPreferences: localPreferences,
            paymentMethodsAvailability: methods,
            onPaymentMethodsSelected: { preferredPaymentMethods in
                completion(preferredPaymentMethods)
                self.paymentMethodsSheetDismisser?.dismiss(animated: true)
            }
        )

        paymentMethodsSheetDismisser = bottomSheetPresenter.present(viewController: vc)
    }

    func showPaymentMethodManagementOnWeb(delegate: PaymentMethodsDelegate?) {
        paymentMethodsSheetDismisser?.dismiss(animated: true, completion: { [weak self] in
            guard let self else { return }
            let url = Branding.current.url.appendingPathComponent(Constants.paymentMethodManagementUrlPath)
            let viewController = webViewControllerFactory.make(
                with: url,
                userInfoForAuthentication: (userProvider.user.userId, profile.id),
                popDismissalHandler: nil,
                modalDismissalHandler: { [weak self, weak delegate] in
                    guard let self else { return }
                    webMethodsManagementDismisser?.dismiss(animated: true, completion: {
                        delegate?.refreshPaymentMethods()
                    })
                }
            ).navigationWrapped()
            viewController.modalPresentationStyle = .fullScreen
            let presenter = presenterFactory
                .makeModalPresenter(parent: navigationController)
            webMethodsManagementDismisser = presenter.present(viewController: viewController)
        })
    }

    // This method satisfies `CreatePaymentRequestRoutingDelegate` and `CreatePaymentRequestPaymentMethodRoutingDelegate`
    // and they are doing the same behaviours
    func showPayWithWiseEducation() {
        let flow = payWithWiseEducationFlowFactory.makeBottomSheetFlow(parentViewController: navigationController)
        flow.onFinish { [weak self] result, dismisser in
            guard let self else {
                return
            }
            payWithWiseEducationFlow = nil
            switch result {
            case .inviteFriendsSelected:
                dismisser?.dismiss {
                    self.showInviteFriends()
                }
            case .cancelled:
                dismisser?.dismiss()
            }
        }
        payWithWiseEducationFlow = flow
        flow.start()
    }

    func showRequestFromContactsSuccess(
        contact: RequestMoneyContact,
        paymentRequest: PaymentRequestV2
    ) {
        publishPaymentRequestIfNeeded(paymentRequestId: paymentRequest.id) { [weak self] paymentRequest in
            self?.showContactRequestSuccessScreenAfterPublishingPaymentRequest(
                contact: contact,
                paymentRequest: paymentRequest
            )
        }
    }
}

// MARK: - Dynamic Flow Helpers

extension CreatePaymentRequestFlow {
    func makeDynamicFlow(
        flowId: String,
        url: String
    ) -> any Flow<Result<DynamicFormResponse?, FlowFailure>> {
        let resource = RestGwResource<DynamicFlowHTTPResponse>(
            path: url,
            method: .get,
            parser: DynamicFlowHTTPResponse.parser
        )
        let analyticsFlowTracker = AnalyticsFlowLegacyTrackerImpl(
            analyticsTracker: analyticsTracker,
            flowId: flowId
        )
        return dynamicFlowFactory.makeFlow(
            resource: resource,
            presentationStyle: .push(navigationController: navigationController),
            analyticsFlowTracker: analyticsFlowTracker,
            resultParser: OptionalDecodableParser<DynamicFormResponse>()
        )
    }

    func showNextDynamicFormIfNeeded(
        optionalResponse: DynamicFormResponse?,
        dynamicForms: [PaymentMethodAvailability.DynamicForm],
        completionHandler: @escaping () -> Void
    ) {
        var remindedDynamicForms = dynamicForms
        remindedDynamicForms.removeFirst()
        guard let response = optionalResponse else {
            handleDynamicForms(
                forms: remindedDynamicForms,
                completionHandler: completionHandler
            )
            return
        }
        if response.completed == true || response.exited?.reason == Constants.exitReasonFlowCompleted {
            handleDynamicForms(
                forms: remindedDynamicForms,
                completionHandler: completionHandler
            )
        } else {
            return
        }
    }
}

// MARK: - Flow helpers

private extension CreatePaymentRequestFlow {
    func trackFlowFinished(result: CreatePaymentRequestFlowResult) {
        let resultAnalytics =
            switch result {
            case .success:
                "Success"
            case .aborted:
                "Dismissed"
            }
        let properties: [AnalyticsProperty] = [
            CreatePaymentRequestFlowAnalytics.CurrencyProperty(values: eligibleBalances.balances.map(\.currency)),
            CreatePaymentRequestFlowAnalytics.RequestFlowResult(value: resultAnalytics),
        ]
        flowTracker.trackFlow(.finished, properties: properties)
    }

    func flowFinished(result: CreatePaymentRequestFlowResult) {
        trackFlowFinished(result: result)
        flowHandler.flowFinished(result: result, dismisser: dismisser)
    }

    func trackCreatePaymentRequestStarted() {
        let step = CreatePaymentRequestFlowAnalytics.CreateRequestDetails(profileType: profile.type)
        flowTracker.trackStep(
            step,
            .started,
            properties: step.properties
        )
    }
}

// MARK: - Present steps

private extension CreatePaymentRequestFlow {
    func showOnboarding() {
        let viewController = viewControllerFactory.makeOnboardingViewController(
            profile: profile,
            routingDelegate: self
        )
        pushPresenter.keepOnlyLastViewControllerOnStack = true // Onboarding should always be the first step
        dismisser = pushPresenter.present(viewController: viewController)
    }

    func showContactPicker(isFirstStep: Bool) {
        let viewController = viewControllerFactory.makeContactPicker(
            profile: profile,
            router: self,
            navigationController: navigationController
        )
        pushPresenter.keepOnlyLastViewControllerOnStack = isFirstStep
        let animated = isFirstStep ? false : UIView.shouldAnimate
        pushPresenter.present(viewController: viewController, animated: animated)
    }

    func showCreatePaymentRequestBusiness(isFirstStep: Bool) {
        trackCreatePaymentRequestStarted()
        let paymentRequestInfo = CreatePaymentRequestPresenterInfo(
            defaultBalance: defaultBalance,
            eligibleBalances: eligibleBalances
        )
        let viewController = viewControllerFactory.makeCreatePaymentRequestBusiness(
            paymentRequestInfo: paymentRequestInfo,
            profile: profile,
            routingDelegate: self
        )
        pushPresenter.keepOnlyLastViewControllerOnStack = isFirstStep
        let animated = isFirstStep ? false : UIView.shouldAnimate
        pushPresenter.present(viewController: viewController, animated: animated)
    }

    func showCreatePaymentRequestPersonal(isFirstStep: Bool) {
        trackCreatePaymentRequestStarted()

        if contact.isNil {
            showRequestFromAnyone(isFirstStep: isFirstStep)
        } else {
            let paymentRequestInfo = CreatePaymentRequestPersonalPresenterInfo(
                defaultBalance: defaultBalance,
                eligibleBalances: eligibleBalances,
                contact: contact
            )
            let viewController = viewControllerFactory.makeCreatePaymentRequestPersonal(
                paymentRequestInfo: paymentRequestInfo,
                profile: profile,
                routingDelegate: self
            )
            pushPresenter.keepOnlyLastViewControllerOnStack = isFirstStep
            let animated = isFirstStep ? false : UIView.shouldAnimate
            pushPresenter.present(viewController: viewController, animated: animated)
        }
    }

    func showRequestFromAnyone(isFirstStep: Bool) {
        let viewController = viewControllerFactory.makeRequestFromAnyoneViewController(
            profile: profile,
            routingDelegate: self
        )
        pushPresenter.keepOnlyLastViewControllerOnStack = isFirstStep
        let animated = isFirstStep ? false : UIView.shouldAnimate
        requestFromAnyoneDismiser = pushPresenter.present(viewController: viewController, animated: animated)
    }

    func showConfirmationScreenAfterPublishingPaymentRequest(paymentRequest: PaymentRequestV2) {
        let step = CreatePaymentRequestFlowAnalytics.ShareRequestDetails(profileType: profile.type)
        flowTracker.trackStep(
            step,
            .started,
            properties: step.properties
        )
        let viewController = viewControllerFactory.makeConfirmation(
            paymentRequest: paymentRequest,
            profile: profile,
            onSuccess: { [weak self] result in
                self?.flowFinished(result: result)
            }
        )
        pushPresenter.keepOnlyLastViewControllerOnStack = true
        // Assign `dismisser` to clean the navigation stack
        dismisser = pushPresenter.present(viewController: viewController)
    }

    func showContactRequestSuccessScreenAfterPublishingPaymentRequest(
        contact: RequestMoneyContact,
        paymentRequest: PaymentRequestV2
    ) {
        let analyticsViewTracker = AnalyticsViewTrackerImpl<RequestMoneyContactPickerSuccessAnalyticsView>(
            contextIdentity: RequestMoneyContactPickerSuccessAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
        let viewModel = CreatePaymentRequestFromContactSuccessViewModel.make(
            contact: contact,
            paymentRequest: paymentRequest,
            primaryButtonAction: { [weak self] _ in
                guard let self else { return }
                analyticsViewTracker.track(
                    RequestMoneyContactPickerSuccessAnalyticsView.DoneTapped()
                )
                flowFinished(
                    result: .success(
                        paymentRequestId: paymentRequest.id,
                        context: .completed
                    )
                )
            }, secondaryButtonAction: { [weak self] _ in
                guard let self else { return }
                analyticsViewTracker.track(
                    RequestMoneyContactPickerSuccessAnalyticsView.ViewRequestTapped()
                )
                flowFinished(
                    result: .success(
                        paymentRequestId: paymentRequest.id,
                        context: .requestFromContact
                    )
                )
            }
        )
        let viewController = viewControllerFactory.makeCreatePaymentRequestFromContactSuccess(
            with: viewModel
        )
        pushPresenter.keepOnlyLastViewControllerOnStack = true
        // Assign `dismisser` to clean the navigation stack
        dismisser = pushPresenter.present(viewController: viewController)
    }

    func showInviteFriends() {
        startInviteFlow()
    }
}

// MARK: - Publish payment request

private extension CreatePaymentRequestFlow {
    private func publishPaymentRequest(paymentRequestId: PaymentRequestId) -> AnyPublisher<PaymentRequestV2, Error> {
        paymentRequestUseCase.updatePaymentRequestStatus(
            profileId: profile.id,
            paymentRequestId: paymentRequestId,
            body: UpdatePaymentRequestStatusBodyV2(status: .published)
        )
        .map { [weak self] paymentRequest in
            guard let self else {
                return paymentRequest
            }
            let flowVariant = CreatePaymentRequestFlowAnalytics.FlowVariantProperty(value: profile.type)
            flowTracker.trackFlow(CreatePaymentRequestFlowAnalytics.RequestPublished(flowVariant: flowVariant))
            return paymentRequest
        }
        .eraseError()
        .eraseToAnyPublisher()
    }

    private func publishPaymentRequestIfNeeded(
        paymentRequestId: PaymentRequestId,
        _ completion: @escaping (PaymentRequestV2) -> Void
    ) {
        navigationController.showHud()
        publishPaymentRequestCancellable = publishPaymentRequest(paymentRequestId: paymentRequestId)
            .receive(on: scheduler)
            .asResult()
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                navigationController.hideHud()
                switch result {
                case let .success(paymentRequest):
                    completion(paymentRequest)
                case .failure:
                    navigationController.showDismissableAlert(
                        title: L10n.Generic.Error.title,
                        message: L10n.Generic.Error.message
                    )
                }
            }
    }
}

// MARK: - State helpers

private extension CreatePaymentRequestFlow {
    var shouldShowContactPicker: Bool {
        profile.type == .personal
            // If a contact given previously we should skip contact picker
            && contact == nil
    }

    var isContactRequestEligible: Bool {
        contact?.hasRequestCapability == true
    }
}

// MARK: - Subtypes

extension CreatePaymentRequestFlow {
    // sourcery: Buildable
    enum EntryPoint {
        case deeplink
        case balance
        case cardOnboardingDeeplink
        case paymentRequestList
        case launchpad
        case recipients
        case contactList
        case recentContact
        case payWithWiseSuccess
    }
}

// MARK: - RequestMoneyFlowEntryPoint

extension CreatePaymentRequestFlow.EntryPoint {
    init(requestMoneyFlowEntryPoint: RequestMoneyFlow.EntryPoint) {
        switch requestMoneyFlowEntryPoint {
        case .deeplink: self = .deeplink
        case .launchpad: self = .launchpad
        case .balance: self = .balance
        case .cardOnboardingDeeplink: self = .cardOnboardingDeeplink
        case .contactList: self = .contactList
        case .recentContact: self = .recentContact
        case .paymentRequestList: self = .paymentRequestList
        case .payWithWiseSuccess: self = .payWithWiseSuccess
        }
    }
}

private extension RequestMoneyContact {
    init?(contact: Contact?) {
        guard let contact,
              let contactId = contact.id.contactId else {
            return nil
        }

        self.init(
            id: contactId,
            title: contact.title,
            subtitle: contact.subtitle,
            // Always true since we fetch with filtering
            hasRequestCapability: true,
            avatarPublisher: contact.avatarPublisher
        )
    }
}
