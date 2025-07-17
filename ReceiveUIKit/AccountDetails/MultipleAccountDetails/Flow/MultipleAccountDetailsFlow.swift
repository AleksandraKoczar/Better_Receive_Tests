import AnalyticsKit
import BalanceKit
import DeepLinkKit
import Neptune
import TWFoundation
import UIKit
import UserKit

final class MultipleAccountDetailsFlow: Flow {
    var flowHandler: FlowHandler<AccountDetailsFlowResult> = .empty
    private let navigationController: UINavigationController
    private let userProvider: UserProvider
    private let route: DeepLinkAccountDetailsRoute?
    private let invocationContext: AccountDetailsFlowInvocationContext
    private let loadAccountDetailsStatusFactory: LoadAccountDetailsStatusFactory
    private let loadAccountDetailsEligibilityFactory: LoadAccountDetailsEligibilityFactory
    private let multipleAccountDetailsIneligibilityFactory: MultipleAccountDetailsIneligibilityFactory
    private let multipleAccountDetailsOrderFlowFactory: MultipleAccountDetailsOrderFlowFactory
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory
    private let profileCreationFlowFactory: MultipleAccountDetailsProfileCreationFlowFactory
    private let singleAccountDetailsFlowFactory: SingleAccountDetailsFlowFactory
    private let userOnboardingPreferencesService: UserOnboardingPreferencesService

    private let flowPresenter: FlowPresenter
    private let analytics: AnalyticsFlowLegacyTracker

    private var loadAccountDetailsStatusDismisser: ViewControllerDismisser?
    private var loadAccountDetailsEligibilityDismisser: ViewControllerDismisser?
    private var multipleAccountDetailsIneligibilityDismisser: ViewControllerDismisser?
    private var multipleAccountDetailsOrderFlowDismisser: ViewControllerDismisser?
    private var profileCreationFlowDismisser: ViewControllerDismisser?
    private var singleAccountDetailsFlowDismisser: ViewControllerDismisser?
    private var multipleAccountDetailsOrderFlow: (any Flow<MultipleAccountDetailsOrderFlowResult>)?
    private var profileCreationFlow: (any Flow<MultipleAccountDetailsProfileCreationFlowResult>)?
    private var singleAccountDetailsFlow: (any Flow<AccountDetailsFlowResult>)?

    private var flowDismisser: ViewControllerDismisser? {
        [
            profileCreationFlowDismisser,
            loadAccountDetailsStatusDismisser,
            loadAccountDetailsEligibilityDismisser,
            multipleAccountDetailsIneligibilityDismisser,
            multipleAccountDetailsOrderFlowDismisser,
            singleAccountDetailsFlowDismisser,
        ].compactMap { $0 }.first
    }

    init(
        navigationController: UINavigationController,
        route: DeepLinkAccountDetailsRoute?,
        invocationContext: AccountDetailsFlowInvocationContext,
        loadAccountDetailsStatusFactory: LoadAccountDetailsStatusFactory,
        loadAccountDetailsEligibilityFactory: LoadAccountDetailsEligibilityFactory,
        multipleAccountDetailsIneligibilityFactory: MultipleAccountDetailsIneligibilityFactory,
        multipleAccountDetailsOrderFlowFactory: MultipleAccountDetailsOrderFlowFactory,
        profileCreationFlowFactory: MultipleAccountDetailsProfileCreationFlowFactory,
        singleAccountDetailsFlowFactory: SingleAccountDetailsFlowFactory,
        viewControllerPresenterFactory: ViewControllerPresenterFactory,
        userOnboardingPreferencesService: UserOnboardingPreferencesService,
        flowPresenter: FlowPresenter = .current,
        analyticsFlowLegacyTracker: AnalyticsFlowLegacyTracker,
        userProvider: UserProvider = GOS[UserProviderKey.self],
    ) {
        self.navigationController = navigationController
        self.userProvider = userProvider
        self.route = route
        self.invocationContext = invocationContext
        self.loadAccountDetailsStatusFactory = loadAccountDetailsStatusFactory
        self.loadAccountDetailsEligibilityFactory = loadAccountDetailsEligibilityFactory
        self.multipleAccountDetailsIneligibilityFactory = multipleAccountDetailsIneligibilityFactory
        self.multipleAccountDetailsOrderFlowFactory = multipleAccountDetailsOrderFlowFactory
        self.profileCreationFlowFactory = profileCreationFlowFactory
        self.singleAccountDetailsFlowFactory = singleAccountDetailsFlowFactory
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
        self.userOnboardingPreferencesService = userOnboardingPreferencesService

        self.flowPresenter = flowPresenter
        analytics = analyticsFlowLegacyTracker
    }

    func start() {
        analytics.track(event: MultipleAccountDetailsFlowStartedEvent())
        if let profile = userProvider.activeProfile {
            route(with: profile)
        } else {
            switch userOnboardingPreferencesService.registrationPreferences.profileType {
            case .business:
                showCreateProfileFlow()
            case .personal:
                showSingleAccountDetailsFlow()
            }
        }
        flowHandler.flowStarted()
    }

    func terminate() {
        flowDismisser?.dismiss(animated: false)
    }

    private func finishFlow(with result: AccountDetailsFlowResult) {
        analytics.track(event: MultipleAccountDetailsFlowFinishedEvent(
            result: {
                switch result {
                case .completed:
                    .completed
                case .interrupted:
                    .interrupted
                }
            }()
        ))
        flowHandler.flowFinished(
            result: result,
            dismisser: flowDismisser
        )
    }

    private func makePushPresenter(keepOnlyLastViewControllerOnStack: Bool = false) -> ViewControllerPresenter {
        var presenter = viewControllerPresenterFactory.makePushPresenter(
            navigationController: navigationController
        )
        presenter.keepOnlyLastViewControllerOnStack = keepOnlyLastViewControllerOnStack
        return presenter
    }
}

// MARK: - Profile routing

private extension MultipleAccountDetailsFlow {
    func route(with profile: Profile) {
        switch profile.type {
        case .business:
            if profile.has(privilege: BalancePrivilege.manage) {
                loadAccountDetailsStatus(profile: profile)
            } else {
                showSingleAccountDetailsFlow()
            }
        case .personal:
            showSingleAccountDetailsFlow()
        }
    }
}

// MARK: - Account details status

private extension MultipleAccountDetailsFlow {
    func loadAccountDetailsStatus(profile: Profile) {
        let presenter = makePushPresenter()
        loadAccountDetailsStatusDismisser = presenter.present(
            viewController: loadAccountDetailsStatusFactory.make(
                router: self,
                profile: profile
            ),
            animated: false
        )
        analytics.track(event: MultipleAccountDetailsFlowLoadAccountDetailsStatusEvent())
    }
}

extension MultipleAccountDetailsFlow: LoadAccountDetailsStatusRouter {
    func route(action: LoadAccountDetailsStatusRouterAction) {
        switch action {
        case let .loaded(info):
            loadAccountDetailsStatusDismisser.dismiss(animated: false) { [weak self] in
                guard let self else {
                    return
                }
                loadAccountDetailsStatusDismisser = nil
                switch info.status {
                case .active:
                    showSingleAccountDetailsFlow()
                case .inactive:
                    loadAccountDetailsEligibility(profile: info.profile)
                }
            }
        case .dismissed:
            finishFlow(with: .interrupted)
        }
    }
}

// MARK: - Account details eligibility

private extension MultipleAccountDetailsFlow {
    func loadAccountDetailsEligibility(profile: Profile) {
        let presenter = makePushPresenter()
        loadAccountDetailsEligibilityDismisser = presenter.present(
            viewController: loadAccountDetailsEligibilityFactory.make(
                router: self,
                profile: profile
            ),
            animated: false
        )
        analytics.track(event: MultipleAccountDetailsFlowLoadEligibilityEvent())
    }

    func shouldShowMultipleAccountDetailsOrderFlow(for requirements: [AccountDetailsRequirement]) -> Bool {
        let fees = requirements.filter {
            if case .fee = $0.type {
                return true
            }
            return false
        }
        return fees.isEmpty || fees.contains { $0.status == .pendingUser }
    }
}

extension MultipleAccountDetailsFlow: LoadAccountDetailsEligibilityRouter {
    func route(action: LoadAccountDetailsEligibilityRouterAction) {
        switch action {
        case let .loaded(result):
            switch result {
            case let .eligible(info):
                loadAccountDetailsEligibilityDismisser.dismiss(animated: false) { [weak self] in
                    guard let self else {
                        return
                    }
                    loadAccountDetailsEligibilityDismisser = nil
                    if shouldShowMultipleAccountDetailsOrderFlow(for: info.requirements) {
                        showMultipleAccountDetailsOrderFlow(profile: info.profile)
                    } else {
                        showSingleAccountDetailsFlow()
                    }
                }
            case let .ineligible(profile):
                loadAccountDetailsEligibilityDismisser.dismiss(animated: false) { [weak self] in
                    guard let self else {
                        return
                    }
                    loadAccountDetailsEligibilityDismisser = nil
                    let presenter = makePushPresenter(keepOnlyLastViewControllerOnStack: true)
                    multipleAccountDetailsIneligibilityDismisser = presenter.present(
                        viewController: multipleAccountDetailsIneligibilityFactory.makeView(
                            router: self,
                            profile: profile
                        )
                    )
                    analytics.track(event: MultipleAccountDetailsFlowIneligibleEvent())
                }
            }
        case .dismissed:
            finishFlow(with: .interrupted)
        }
    }
}

extension MultipleAccountDetailsFlow: MultipleAccountDetailsIneligibilityRouter {
    func route(action: MultipleAccountDetailsIneligibilityRouterAction) {
        switch action {
        case let .proceed(profile):
            finishFlow(with: .completed(profile))
        }
    }
}

// MARK: - Single account details

private extension MultipleAccountDetailsFlow {
    func showSingleAccountDetailsFlow() {
        let flow = singleAccountDetailsFlowFactory.make(
            hostViewController: navigationController,
            route: route,
            invocationContext: invocationContext
        )
        flow.onFinish { [weak self] result, dismisser in
            guard let self else {
                return
            }
            singleAccountDetailsFlowDismisser = dismisser
            finishFlow(with: result)
            singleAccountDetailsFlow = nil
        }
        singleAccountDetailsFlow = flow
        flowPresenter.start(flow: flow)
        analytics.track(event: MultipleAccountDetailsFlowSingleDetailsEvent())
    }
}

// MARK: - Multiple account details

private extension MultipleAccountDetailsFlow {
    func showMultipleAccountDetailsOrderFlow(profile: Profile) {
        let flow = multipleAccountDetailsOrderFlowFactory.make(
            navigationController: navigationController,
            profile: profile
        )
        flow.onFinish { [weak self] result, dismisser in
            guard let self else {
                return
            }
            multipleAccountDetailsOrderFlowDismisser = dismisser
            finishFlow(
                with: {
                    switch result {
                    case .success:
                        .completed(profile)
                    case .failure,
                         .dismissed:
                        .interrupted
                    }
                }()
            )
            multipleAccountDetailsOrderFlow = nil
        }
        multipleAccountDetailsOrderFlow = flow
        flowPresenter.start(flow: flow)
        analytics.track(event: MultipleAccountDetailsFlowOrderEvent())
    }
}

// MARK: - Profile creation

private extension MultipleAccountDetailsFlow {
    func showCreateProfileFlow() {
        let flow = profileCreationFlowFactory.make(
            navigationController: navigationController,
            clearNavigation: false
        )
        flow.onFinish { [weak self] result, dismisser in
            guard let self else {
                return
            }
            switch result {
            case let .completed(profile):
                dismisser.dismiss(animated: false) {
                    self.route(with: profile)
                }
            case .interrupted:
                profileCreationFlowDismisser = dismisser
                finishFlow(with: .interrupted)
            }
            profileCreationFlow = nil
        }
        profileCreationFlow = flow
        flowPresenter.start(flow: flow)
        analytics.track(event: MultipleAccountDetailsFlowCreateProfileEvent())
    }
}
