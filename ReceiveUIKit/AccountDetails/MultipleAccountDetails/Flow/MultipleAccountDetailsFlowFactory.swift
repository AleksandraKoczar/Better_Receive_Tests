import AnalyticsKit
import BalanceKit
import DeepLinkKit
import Neptune
import TWFoundation
import TWUI
import UserKit

// sourcery: AutoMockable
public protocol MultipleAccountDetailsFlowFactory {
    func make(
        navigationController: UINavigationController,
        route: DeepLinkAccountDetailsRoute?,
        invocationContext: AccountDetailsFlowInvocationContext
    ) -> any Flow<AccountDetailsFlowResult>
}

public final class MultipleAccountDetailsFlowFactoryImpl: MultipleAccountDetailsFlowFactory {
    private let accountDetailsUseCase: AccountDetailsUseCase
    private let accountDetailsEligibilityService: MultipleAccountDetailsEligibilityService
    private let accountDetailsOrderUseCase: AccountDetailsOrderUseCase
    private let multipleAccountDetailsIneligibilityFactory: MultipleAccountDetailsIneligibilityFactory
    private let multipleAccountDetailsOrderFlowFactory: MultipleAccountDetailsOrderFlowFactory
    private let profileCreationFlowFactory: MultipleAccountDetailsProfileCreationFlowFactory
    private let singleAccountDetailsFlowFactory: SingleAccountDetailsFlowFactory
    private let userOnboardingPreferencesService: UserOnboardingPreferencesService
    private let analyticsFlowLegacyTracker: AnalyticsFlowLegacyTracker

    public init(
        accountDetailsUseCase: AccountDetailsUseCase,
        accountDetailsEligibilityService: MultipleAccountDetailsEligibilityService,
        accountDetailsOrderUseCase: AccountDetailsOrderUseCase,
        multipleAccountDetailsIneligibilityFactory: MultipleAccountDetailsIneligibilityFactory,
        multipleAccountDetailsOrderFlowFactory: MultipleAccountDetailsOrderFlowFactory,
        profileCreationFlowFactory: MultipleAccountDetailsProfileCreationFlowFactory,
        singleAccountDetailsFlowFactory: SingleAccountDetailsFlowFactory,
        userOnboardingPreferencesService: UserOnboardingPreferencesService,
        analyticsFlowLegacyTracker: AnalyticsFlowLegacyTracker
    ) {
        self.accountDetailsUseCase = accountDetailsUseCase
        self.accountDetailsEligibilityService = accountDetailsEligibilityService
        self.accountDetailsOrderUseCase = accountDetailsOrderUseCase
        self.multipleAccountDetailsIneligibilityFactory = multipleAccountDetailsIneligibilityFactory
        self.multipleAccountDetailsOrderFlowFactory = multipleAccountDetailsOrderFlowFactory
        self.profileCreationFlowFactory = profileCreationFlowFactory
        self.singleAccountDetailsFlowFactory = singleAccountDetailsFlowFactory
        self.userOnboardingPreferencesService = userOnboardingPreferencesService
        self.analyticsFlowLegacyTracker = analyticsFlowLegacyTracker
    }

    public func make(
        navigationController: UINavigationController,
        route: DeepLinkAccountDetailsRoute?,
        invocationContext: AccountDetailsFlowInvocationContext
    ) -> any Flow<AccountDetailsFlowResult> {
        MultipleAccountDetailsFlow(
            navigationController: navigationController,
            route: route,
            invocationContext: invocationContext,
            loadAccountDetailsStatusFactory: LoadAccountDetailsStatusFactoryImpl(
                useCase: accountDetailsUseCase
            ),
            loadAccountDetailsEligibilityFactory: LoadAccountDetailsEligibilityFactoryImpl(
                accountDetailsEligibilityService: accountDetailsEligibilityService,
                accountDetailsOrderUseCase: accountDetailsOrderUseCase
            ),
            multipleAccountDetailsIneligibilityFactory: multipleAccountDetailsIneligibilityFactory,
            multipleAccountDetailsOrderFlowFactory: multipleAccountDetailsOrderFlowFactory,
            profileCreationFlowFactory: profileCreationFlowFactory,
            singleAccountDetailsFlowFactory: singleAccountDetailsFlowFactory,
            viewControllerPresenterFactory: PreserveNavigationViewControllerPresenterFactory(
                navigationController: navigationController
            ),
            userOnboardingPreferencesService: userOnboardingPreferencesService,
            analyticsFlowLegacyTracker: analyticsFlowLegacyTracker
        )
    }
}
