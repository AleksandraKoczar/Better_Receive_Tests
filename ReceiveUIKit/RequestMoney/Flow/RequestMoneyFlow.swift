import Combine
import CombineSchedulers
import DeepLinkKit
import Foundation
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UserKit
import WiseCore

final class RequestMoneyFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private let isPaymentRequestListOnScreen: Bool // TODO: This is a tricky way to handle flow. Will re-visit it in the future
    private let entryPoint: EntryPoint
    private let profile: Profile
    private let selectedBalanceInfo: BalanceInfo?
    private let contact: RequestMoneyContact?
    private let deepLinkNavigator: DeepLinkNavigator? // Mark it as optional to avoid force unwrap in `Wise` target
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCase
    private let navigationController: UINavigationController
    private let accountDetailsFlowFactory: SingleAccountDetailsFlowFactory
    private let createPaymentRequestFlowFactory: CreatePaymentRequestFlowFactory
    private let inviteFlowFactory: ReceiveInviteFlowFactory
    private let managePaymentRequestsFlowFactory: ManagePaymentRequestsFlowFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory
    private let uriHandler: DeepLinkURIHandler
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory

    private var bottomSheetDismisser: ViewControllerDismisser?
    private var createPaymentRequestFlow: (any Flow<CreatePaymentRequestFlowResult>)?
    private var paymentRequestListFlow: (any Flow<Void>)?
    private var paymentRequestDetailsFlow: (any Flow<Void>)?
    private var accountDetailsFlow: (any Flow<AccountDetailsFlowResult>)?
    private var checkEligibilityCancellable: AnyCancellable?

    private var deepLinkFlow: (any Flow<Void>)?
    private var dismisser: ViewControllerDismisser?

    init(
        isPaymentRequestListOnScreen: Bool,
        entryPoint: EntryPoint,
        profile: Profile,
        selectedBalanceInfo: BalanceInfo?,
        contact: RequestMoneyContact?,
        deepLinkNavigator: DeepLinkNavigator?,
        inviteFlowFactory: ReceiveInviteFlowFactory,
        navigationController: UINavigationController,
        accountDetailsFlowFactory: SingleAccountDetailsFlowFactory,
        webViewControllerFactory: WebViewControllerFactory.Type,
        paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCase = PaymentRequestEligibilityUseCaseFactory.make(),
        createPaymentRequestFlowFactory: CreatePaymentRequestFlowFactory,
        managePaymentRequestsFlowFactory: ManagePaymentRequestsFlowFactory,
        contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactory,
        viewControllerPresenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl(),
        uriHandler: DeepLinkURIHandler,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.isPaymentRequestListOnScreen = isPaymentRequestListOnScreen
        self.entryPoint = entryPoint
        self.profile = profile
        self.selectedBalanceInfo = selectedBalanceInfo
        self.contact = contact
        self.deepLinkNavigator = deepLinkNavigator
        self.scheduler = scheduler
        self.paymentRequestEligibilityUseCase = paymentRequestEligibilityUseCase
        self.inviteFlowFactory = inviteFlowFactory
        self.navigationController = navigationController
        self.accountDetailsFlowFactory = accountDetailsFlowFactory
        self.contactSearchViewControllerFactory = contactSearchViewControllerFactory
        self.createPaymentRequestFlowFactory = createPaymentRequestFlowFactory
        self.managePaymentRequestsFlowFactory = managePaymentRequestsFlowFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.uriHandler = uriHandler
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
    }

    func start() {
        flowHandler.flowStarted()
        checkEligibility()
    }

    func terminate() {
        flowHandler.flowFinished(result: (), dismisser: dismisser)
    }
}

// MARK: - Check eligibility

private extension RequestMoneyFlow {
    func startFlowAccordingToEligibilityResult(_ eligibilityResult: PaymentRequestEligibilityResult) {
        switch eligibilityResult {
        case let .eligible(defaultBalance, eligibleBalances):
            startCreatePaymentRequestFlow(
                defaultBalance: defaultBalance,
                eligibleBalances: eligibleBalances
            )
        case let .unavailable(model):
            handleUnavailable(model: model)
        case .ineligible:
            startAccountDetailsFlow()
        }
    }

    func checkEligibility() {
        navigationController.showHud()
        checkEligibilityCancellable = paymentRequestEligibilityUseCase.checkEligibility(
            profile: profile,
            balanceId: selectedBalanceInfo?.id
        )
        .receive(on: scheduler)
        .asResult()
        .sink { [weak self] result in
            guard let self else {
                return
            }
            navigationController.hideHud()
            switch result {
            case let .success(eligibilityResult):
                startFlowAccordingToEligibilityResult(eligibilityResult)
            case .failure:
                flowHandler.flowFinished(result: (), dismisser: nil)
                navigationController.showDismissableAlert(
                    title: L10n.Generic.Error.title,
                    message: L10n.Generic.Error.message
                )
            }
        }
    }
}

// MARK: - Start subflows

private extension RequestMoneyFlow {
    func startPaymentRequestListFlow() {
        let flow = managePaymentRequestsFlowFactory.makePaymentRequestListWithMostRecentlyRequestedVisible(
            profile: profile,
            navigationController: navigationController
        )
        flow.onFinish { [weak self] _, dismisser in
            guard let self else {
                return
            }
            dismisser?.dismiss()
            paymentRequestListFlow = nil
            switchToPaymentsTab()
            flowHandler.flowFinished(result: (), dismisser: nil)
        }
        paymentRequestListFlow = flow
        flow.start()
    }

    func startPaymentRequestDetailsFlow(paymentRequestId: PaymentRequestId) {
        let flow = managePaymentRequestsFlowFactory.makePaymentRequestDetailsFlow(
            profile: profile,
            paymentRequestId: paymentRequestId,
            navigationController: navigationController
        )
        flow.onFinish { [weak self] _, dismisser in
            guard let self else {
                return
            }
            dismisser?.dismiss()
            paymentRequestDetailsFlow = nil
            switchToPaymentsTab()
            flowHandler.flowFinished(result: (), dismisser: nil)
        }
        paymentRequestDetailsFlow = flow
        flow.start()
    }

    func startAnotherFlowOrFinishFlowAccordingTo(
        paymentRequestId: PaymentRequestId,
        context: CreatePaymentRequestFlowResult.Context
    ) {
        switch context {
        case .linkCreation:
            if isPaymentRequestListOnScreen {
                flowHandler.flowFinished(result: (), dismisser: nil)
            } else {
                startPaymentRequestListFlow()
            }
        case .requestFromContact:
            startPaymentRequestDetailsFlow(paymentRequestId: paymentRequestId)
        case .completed:
            flowHandler.flowFinished(result: (), dismisser: nil)
        }
    }

    func startCreatePaymentRequestFlow(
        defaultBalance: PaymentRequestEligibleBalances.Balance,
        eligibleBalances: PaymentRequestEligibleBalances
    ) {
        let flow = createPaymentRequestFlowFactory.makeForRequestMoneyFlow(
            entryPoint: entryPoint,
            profile: profile,
            contact: contact,
            preSelectedBalanceCurrencyCode: selectedBalanceInfo?.currencyCode,
            defaultBalance: defaultBalance,
            eligibleBalances: eligibleBalances,
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            navigationController: navigationController
        )
        flow.onFinish { [weak self] result, dismisser in
            guard let self else {
                return
            }
            createPaymentRequestFlow = nil
            switch result {
            case let .success(paymentRequestId, context):
                // Clean up navigation stack to show a close button
                // Be careful about assigning `dismisser` in `CreatePaymentRequestFlow`
                dismisser?.dismiss(animated: false)
                startAnotherFlowOrFinishFlowAccordingTo(
                    paymentRequestId: paymentRequestId,
                    context: context
                )
            case .aborted:
                dismisser?.dismiss()
                flowHandler.flowFinished(result: (), dismisser: nil)
            }
        }
        createPaymentRequestFlow = flow
        flow.start()
    }

    func startAccountDetailsFlow() {
        let flow = accountDetailsFlowFactory.make(
            hostViewController: navigationController,
            route: nil,
            invocationContext: .requestMoney
        )
        flow.onFinish { [weak self] _, dismisser in
            guard let self else {
                return
            }
            dismisser?.dismiss()
            accountDetailsFlow = nil
            flowHandler.flowFinished(result: (), dismisser: nil)
        }
        accountDetailsFlow = flow
        flow.start()
    }

    func handleUnavailable(model: PaymentRequestEligibilityResult.Unavailable) {
        if let uri = model.uri,
           let flow = uriHandler.makeFlow(
               uri: uri,
               deepLinkContext: .receiveURIHandler,
               hostController: navigationController
           ) {
            flow.onFinish { [weak self] _, dismisser in
                dismisser?.dismiss()
                self?.deepLinkFlow = nil
                self?.terminate()
            }
            deepLinkFlow = flow
            flow.start()
        } else {
            let errorViewController = TemplateLayoutViewController(
                errorViewModel: ErrorViewModel(
                    message: .text(model.reasonMessage ?? L10n.Generic.Error.message),
                    primaryViewModel: .ok { [weak self] in
                        self?.terminate()
                    }
                )
            )
            let presenter = viewControllerPresenterFactory.makeModalPresenter(
                parent: navigationController
            )
            dismisser = presenter.present(viewController: errorViewController)
        }
    }
}

// MARK: - Helpers

private extension RequestMoneyFlow {
    func switchToPaymentsTab() {
        guard let deepLinkNavigator else {
            softFailure("[REC] Unable to get deep link navigator. This is probably because casting in `DefaultRequestMoneyFlowFactory` fails.")
            return
        }
        let route = DeepLinkRequestMoneyCompletedRouteImpl()
        deepLinkNavigator.performNavigation(route: route)
    }
}

// MARK: - Subtypes

extension RequestMoneyFlow {
    // sourcery: Buildable
    enum EntryPoint {
        case deeplink
        case launchpad
        case balance
        case cardOnboardingDeeplink
        case contactList
        case recentContact
        case paymentRequestList
        case payWithWiseSuccess
    }

    // sourcery: Buildable
    struct BalanceInfo {
        let id: BalanceId
        let currencyCode: CurrencyCode?
    }
}
