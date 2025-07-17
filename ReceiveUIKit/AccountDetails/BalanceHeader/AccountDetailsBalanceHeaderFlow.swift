import AnalyticsKit
import BalanceKit
import Combine
import CombineSchedulers
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

final class AccountDetailsBalanceHeaderFlow: Flow {
    private enum Constants {
        static let minHudLoaderDisplayTime: TimeInterval = 0.7
        static let iso3CodeForBrazil = "BRA"
    }

    var flowHandler: FlowHandler<AccountDetailsBalanceHeaderFlowResult> = .empty

    private let host: UIViewController
    private let navigationController: UINavigationController
    private let accountDetailsOrderUseCase: AccountDetailsOrderUseCase
    private let accountDetailsUseCase: AccountDetailsUseCase
    private let accountDetailsRequirementsUseCase: AccountDetailsRequirementsUseCase
    private let upsellFactory: AccountDetailsFlowUpsellFactory
    private let accountDetailsListFactory: AccountDetailsListFactory
    private let accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory
    private let accountDetailsSplitterScreenFactory: AccountDetailsSplitterScreenViewControllerFactory
    private let orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    private let multipleAccountDetailsOrderFlowFactory: MultipleAccountDetailsOrderFlowWithUpsellConfigurationFactory
    private let analyticsTracker: AnalyticsTracker
    private let featureService: FeatureService
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private let profile: Profile
    private let currencyCode: CurrencyCode
    private let canShowUpsell: Bool
    private let canOrderMultipleAccountDetails: Bool

    private var ordersCancellable: AnyCancellable?
    private var accountDetailsRequirementsCancellable: AnyCancellable?

    private var orderAccountDetailsFlow: (any Flow<OrderAccountDetailsFlowResult>)?
    private var multipleAccountDetailsOrderFlow: (any Flow<MultipleAccountDetailsOrderFlowResult>)?
    private var hudDisplayedAt: Date?

    private var dispatchTime: DispatchTime {
        if let diff = hudDisplayedAt?.timeIntervalSinceNow,
           diff < 0 {
            return .now() + TimeInterval(Constants.minHudLoaderDisplayTime + diff)
        }
        return .now()
    }

    init(
        canShowUpsell: Bool,
        canOrderMultipleAccountDetails: Bool,
        currencyCode: CurrencyCode,
        profile: Profile,
        host: UIViewController,
        accountDetailsUseCase: AccountDetailsUseCase,
        accountDetailsOrderUseCase: AccountDetailsOrderUseCase,
        accountDetailsRequirementsUseCase: AccountDetailsRequirementsUseCase,
        upsellFactory: AccountDetailsFlowUpsellFactory,
        accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory,
        accountDetailsListFactory: AccountDetailsListFactory,
        accountDetailsSplitterScreenFactory: AccountDetailsSplitterScreenViewControllerFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        multipleAccountDetailsOrderFlowFactory: MultipleAccountDetailsOrderFlowWithUpsellConfigurationFactory,
        navigationController: UINavigationController = TWNavigationController(),
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        featureService: FeatureService = GOS[FeatureServiceKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.host = host
        self.canShowUpsell = canShowUpsell
        self.canOrderMultipleAccountDetails = canOrderMultipleAccountDetails
        self.currencyCode = currencyCode
        self.profile = profile
        self.accountDetailsUseCase = accountDetailsUseCase
        self.accountDetailsOrderUseCase = accountDetailsOrderUseCase
        self.accountDetailsRequirementsUseCase = accountDetailsRequirementsUseCase
        self.upsellFactory = upsellFactory
        self.accountDetailsListFactory = accountDetailsListFactory
        self.accountDetailsInfoFactory = accountDetailsInfoFactory
        self.accountDetailsSplitterScreenFactory = accountDetailsSplitterScreenFactory
        self.orderAccountDetailsFlowFactory = orderAccountDetailsFlowFactory
        self.multipleAccountDetailsOrderFlowFactory = multipleAccountDetailsOrderFlowFactory
        self.navigationController = navigationController
        self.analyticsTracker = analyticsTracker
        self.featureService = featureService
        self.scheduler = scheduler
    }

    func start() {
        flowHandler.flowStarted()
        navigationController.modalPresentationStyle = .fullScreen
        host.present(
            navigationController,
            animated: UIView.shouldAnimate
        )
        navigationController.showHud()
        hudDisplayedAt = Date()
        loadPrerequisiteData()
    }

    func terminate() {
        host.dismiss(animated: UIView.shouldAnimate)
    }
}

// MARK: - Prerequisities Step

private extension AccountDetailsBalanceHeaderFlow {
    func loadPrerequisiteData() {
        accountDetailsOrderUseCase.orders(
            profileId: profile.id,
            status: []
        ) { [weak self] result in
            guard let self else { return }
            ordersCancellable = accountDetailsUseCase.accountDetails
                .handleEvents(receiveOutput: { [weak self] state in
                    if state == nil {
                        self?.accountDetailsUseCase.refreshAccountDetails()
                    }
                })
                .compactMap { $0 }
                .receive(on: scheduler)
                .prefix(1)
                .sink { [weak self] state in
                    guard let self else { return }
                    switch state {
                    case let .loaded(accountDetails):
                        continueFromPrerequisiteLoad(
                            allAccountDetails: accountDetails,
                            orders: result.value ?? []
                        )
                    case let .recoverableError(error):
                        trackError(
                            context: .fetchingAccountDetails(
                                error: error
                            )
                        )
                        showAccountDetailsFlowError()
                    case .loading:
                        break
                    }
                }
            // We can ignore errors returned when getting orders
            // but just log them in favor of observability
            if let error = result.error {
                trackError(
                    context: .fetchingOrders(
                        error: error
                    )
                )
            }
        }
    }

    func continueFromPrerequisiteLoad(
        allAccountDetails: [AccountDetails],
        orders: [AccountDetailsOrder]
    ) {
        let accountDetailsForCurrency = allAccountDetails.filter { $0.currency == currencyCode }
        let activeAccountDetails = accountDetailsForCurrency.activeDetails()

        if activeAccountDetails.isNonEmpty {
            showActiveAccountDetails(activeAccountDetails)
        } else if accountDetailsForCurrency.isEmpty {
            trackError(
                context: .noAccountDetailsForCurrency(
                    currency: currencyCode
                )
            )
            stopLoading()
        } else {
            showAvailableAccountDetails(accountDetails: allAccountDetails.availableDetails(), orders: orders)
        }
    }
}

// MARK: - Available Bank Details

private extension AccountDetailsBalanceHeaderFlow {
    func showAvailableAccountDetails(accountDetails: [AvailableAccountDetails], orders: [AccountDetailsOrder]) {
        let showUpsell = shouldShowUpsell(for: orders)
        if shouldShowMultipleAccountDetailsOrder(for: orders) {
            showMultipleAccountDetailsOrderFlow(showUpsell: showUpsell)
        } else if showUpsell {
            fetchAccountDetailsRequirements(allAccountDetails: accountDetails)
        } else {
            showAccountDetailsOrder()
        }
    }

    func shouldShowMultipleAccountDetailsOrder(for orders: [AccountDetailsOrder]) -> Bool {
        guard canOrderMultipleAccountDetails else {
            return false
        }
        let fees = orders.flatMap { $0.requirements }.filter {
            if case .fee = $0.type {
                return true
            }
            return false
        }
        /*
         Multiple account details order flow should only be presented when
         account details fee payment wasn't attempted. For some older profiles
         fee requirement may not be available but the flow should still be presented.
         Therefore, both scenarios need to be taken into consideration.
         */
        return fees.isEmpty || fees.contains { $0.status == .pendingUser }
    }

    func shouldShowUpsell(for orders: [AccountDetailsOrder]) -> Bool {
        guard canShowUpsell else {
            return false
        }
        return !orders.contains { $0.status == .pendingTW }
    }
}

// MARK: Account Details Orders

private extension AccountDetailsBalanceHeaderFlow {
    func fetchAccountDetailsRequirements(allAccountDetails: [AvailableAccountDetails]) {
        accountDetailsRequirementsCancellable = accountDetailsRequirementsUseCase
            .requirements()
            .receive(on: scheduler)
            .prefix(1)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case let .failure(error) = completion {
                        trackError(
                            context: .fetchingRequirements(
                                error: error
                            )
                        )
                        showAccountDetailsFlowError()
                    }
                },
                receiveValue: { [weak self] requirements in
                    guard let self else { return }
                    let feeAmount: Money? = requirements.compactMap {
                        if case let .fee(amount, _) = $0.type {
                            return amount
                        }
                        return nil
                    }.first
                    showAccountDetailsUpsell(
                        allAccountDetails: allAccountDetails,
                        feeAmount: feeAmount
                    )
                }
            )
    }

    func showMultipleAccountDetailsOrderFlow(showUpsell: Bool) {
        stopLoading()

        multipleAccountDetailsOrderFlow = multipleAccountDetailsOrderFlowFactory.make(
            navigationController: navigationController,
            profile: profile,
            showUpsell: showUpsell
        )
        multipleAccountDetailsOrderFlow?.onFinish { [weak self] result, dismisser in
            guard let self else {
                return
            }
            navigationController.dismiss(
                animated: UIView.shouldAnimate
            )
            flowHandler.flowFinished(
                result: {
                    switch result {
                    case .success:
                        .success
                    case .failure:
                        .abortedWithError
                    case .dismissed:
                        .dismissed
                    }
                }(),
                dismisser: dismisser
            )
            multipleAccountDetailsOrderFlow = nil
        }
        multipleAccountDetailsOrderFlow?.start()
    }

    func showAccountDetailsOrder() {
        stopLoading()

        orderAccountDetailsFlow = orderAccountDetailsFlowFactory.makeFlow(
            source: .balanceCard,
            orderSource: .other,
            navigationController: navigationController,
            profile: profile,
            currency: currencyCode
        )

        orderAccountDetailsFlow?.onFinish { [weak self] orderResult, dismisser in
            guard let self else { return }
            defer { self.orderAccountDetailsFlow = nil }
            let result: AccountDetailsBalanceHeaderFlowResult
            switch orderResult {
            case .abortedWithError:
                showAccountDetailsFlowError()
                result = .abortedWithError
            case .ordered:
                NotificationCenter.default.post(name: .balancesNeedUpdate, object: nil)
                result = .success
            case .dismissed:
                result = .dismissed
            case .accountDetailsOpen:
                result = .success
            }
            navigationController.dismiss(
                animated: UIView.shouldAnimate
            )
            flowHandler.flowFinished(result: result, dismisser: dismisser)
        }

        orderAccountDetailsFlow?.start()
    }

    func showAccountDetailsUpsell(
        allAccountDetails: [AvailableAccountDetails],
        feeAmount: Money?
    ) {
        let viewController: UIViewController
        if currencyCode == .BRL,
           profile.address.countryCode?.uppercased() == Constants.iso3CodeForBrazil {
            viewController = upsellFactory.upsellForPix(
                continueHandler: { [weak self] in
                    self?.showAccountDetailsOrder()
                }
            )
        } else {
            let currencies = allAccountDetails
                .map { $0.currency }
                .uniqued()
            let infoSheetModel = upsellFactory.upsellSheetModel(
                for: currencies,
                feeAmount: feeAmount,
                buttonAction: { [weak self] in
                    self?.dismissInfoSheet()
                }
            )
            viewController = upsellFactory.make(
                currencies: currencies,
                feeAmount: feeAmount,
                profileType: profile.type,
                infoHandler: { [weak self] in
                    self?.showInfoSheet(for: infoSheetModel)
                },
                continueHandler: { [weak self] in
                    self?.showAccountDetailsOrder()
                }
            )
        }
        showViewController(viewController)
        analyticsTracker.track(screen: AccountDetailsUpsellPersonalAnalyticsScreen())
    }
}

// MARK: - Active Account Details

private extension AccountDetailsBalanceHeaderFlow {
    func showActiveAccountDetails(_ accountDetails: [ActiveAccountDetails]) {
        if accountDetails.count > 1 {
            analyticsTracker.track(event: BalanceAccountDetailsEvent(
                currency: currencyCode.value
            ))
            showMultipleAccountDetails(accountDetails)
        } else if let accountDetails = accountDetails.first {
            analyticsTracker.track(event: BalanceAccountDetailsEvent(
                currency: currencyCode.value
            ))
            showAccountDetails(accountDetails)
        } else {
            // Since this check is done on caller side this is an impossible case
            LogWarn("We are showing the account details button when we shouldn't")
            stopLoading()
        }
    }
}

// MARK: Multiple Account Details

private extension AccountDetailsBalanceHeaderFlow {
    func showMultipleAccountDetails(_ accountDetails: [ActiveAccountDetails]) {
        guard featureService.isOn(ReceiveKitFeatures.accountDetailsIAEnabled),
              featureService.isOn(ReceiveKitFeatures.accountDetailsIAReworkEnabled),
              featureService.isOn(ReceiveKitFeatures.accountDetailsM2Enabled),
              let currency = accountDetails.first?.currency else {
            let viewController = accountDetailsListFactory.makeMultiAccountDetailSameCurrencyViewController(
                navigationHost: navigationController,
                profile: profile,
                activeAccountDetailsList: accountDetails,
                didDismissCompletion: { [weak self] in
                    self?.flowHandler.flowFinished(result: .success, dismisser: nil)
                }
            )
            showViewController(viewController)
            return
        }

        let viewController = accountDetailsSplitterScreenFactory.make(
            profile: profile,
            currency: currency,
            source: .balanceHeaderAction,
            host: navigationController
        )
        showViewController(viewController)
    }
}

// MARK: Single Account Details

private extension AccountDetailsBalanceHeaderFlow {
    func showAccountDetails(_ accountDetails: ActiveAccountDetails) {
        guard featureService.isOn(ReceiveKitFeatures.accountDetailsIAEnabled),
              featureService.isOn(ReceiveKitFeatures.accountDetailsIAReworkEnabled) else {
            let viewController = accountDetailsInfoFactory.makeInfoViewController(
                navigationHost: navigationController,
                invocationSource: .balanceHeaderAction,
                profile: profile,
                activeAccountDetails: accountDetails,
                completion: { [weak self] in
                    self?.flowHandler.flowFinished(result: .success, dismisser: nil)
                }
            )
            showViewController(viewController)
            return
        }

        let viewController = accountDetailsInfoFactory.makeAccountDetailsV3ViewController(
            profile: profile,
            navigationHost: navigationController,
            invocationSource: .balanceHeaderAction,
            accountDetailsId: accountDetails.id
        )
        showViewController(viewController)
    }
}

// MARK: - Inner Routes

private extension AccountDetailsBalanceHeaderFlow {
    func showInfoSheet(for viewModel: InfoSheetViewModel) {
        navigationController.presentInfoSheet(viewModel: viewModel)
    }

    func dismissInfoSheet() {
        navigationController.presentedViewController?.dismiss(
            animated: UIView.shouldAnimate
        )
    }
}

// MARK: - Display helpers

/// All routing paths in this class should end up here.
/// Since multiple execution paths exist
/// we are putting navigation and hud dismissing logic onto a single point
/// to manage them as a pipe.

private extension AccountDetailsBalanceHeaderFlow {
    func showViewController(_ viewController: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            self.navigationController.setViewControllers([viewController], animated: UIView.shouldAnimate) { [weak self] in
                self?.navigationController.hideHud()
            }
        }
    }

    func showAccountDetailsFlowError() {
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            self.navigationController.hideHud()
            let dismiss = UIAlertAction(
                title: NeptuneLocalization.Button.Title.ok,
                style: .default,
                handler: { [weak self] _ in
                    self?.navigationController.dismiss(animated: UIView.shouldAnimate)
                }
            )

            let alert = UIAlertController.makeAlert(
                title: L10n.Generic.Error.title,
                message: L10n.Generic.Error.message,
                actions: [dismiss]
            )
            self.navigationController.present(alert, animated: UIView.shouldAnimate)
        }
    }

    func stopLoading() {
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            self.navigationController.hideHud()
        }
    }
}

// MARK: - Analytics Helpers

private extension AccountDetailsBalanceHeaderFlow {
    func trackError(context: AccountDetailsBalanceHeaderFlowErrorContext) {
        analyticsTracker.track(
            event: AccountDetailsBalanceHeaderFlowErrorAnalyticsEvent(
                context: context
            )
        )
    }
}
