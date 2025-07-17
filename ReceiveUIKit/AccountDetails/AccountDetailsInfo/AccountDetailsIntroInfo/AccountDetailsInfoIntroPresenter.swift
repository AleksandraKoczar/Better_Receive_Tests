import AnalyticsKit
import BalanceKit
import Combine
import CombineSchedulers
import Foundation
import Neptune
import TransferResources
import TWFoundation
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsInfoIntroPresenter: AnyObject {
    func start(view: AccountDetailsInfoIntroView)
    func dismiss()
}

final class AccountDetailsInfoIntroPresenterImpl {
    private enum Constants {
        static let maxNumberOfDetailItems = 3
    }

    private let shouldShowDetailsSummary: Bool
    private let router: AccountDetailsInfoIntroRouter
    private let accountDetailsUseCase: AccountDetailsUseCase
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<AccountDetailsIntroAnalyticsView>
    private let currencyCode: CurrencyCode
    private let profile: Profile
    private let onDismiss: () -> Void
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private weak var view: AccountDetailsInfoIntroView?
    private var accountDetailsCancellable: AnyCancellable?

    init(
        shouldShowDetailsSummary: Bool,
        router: AccountDetailsInfoIntroRouter,
        accountDetailsUseCase: AccountDetailsUseCase,
        currencyCode: CurrencyCode,
        profile: Profile,
        onDismiss: @escaping () -> Void,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.shouldShowDetailsSummary = shouldShowDetailsSummary
        self.router = router
        self.accountDetailsUseCase = accountDetailsUseCase
        self.currencyCode = currencyCode
        self.profile = profile
        self.onDismiss = onDismiss
        self.scheduler = scheduler

        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: AccountDetailsIntroAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }
}

// MARK: - AccountDetailsInfoIntroPresenter

extension AccountDetailsInfoIntroPresenterImpl: AccountDetailsInfoIntroPresenter {
    func start(view: AccountDetailsInfoIntroView) {
        self.view = view
        analyticsViewTracker.trackView(.started)
        observeAccountDetails()
    }

    func dismiss() {
        onDismiss()
        analyticsViewTracker.trackView(.finished)
    }
}

// MARK: - Helpers

private extension AccountDetailsInfoIntroPresenterImpl {
    func observeAccountDetails() {
        accountDetailsCancellable?.cancel()
        accountDetailsCancellable = accountDetailsUseCase.accountDetails
            .handleEvents(receiveOutput: { [weak self] state in
                if state == nil {
                    self?.accountDetailsUseCase.refreshAccountDetails()
                }
            })
            .compactMap { $0 }
            .receive(on: scheduler)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .loading:
                    view?.showHud()

                case let .loaded(accountDetails):
                    view?.hideHud()
                    guard let accountDetail = accountDetails
                        .activeDetails()
                        .first(where: {
                            $0.currency == self.currencyCode
                                && !$0.isDeprecated
                        }) else {
                        showError(
                            message: L10n.AccountDetails.Intro.Error.No.Account.Details.For.currency
                        )
                        analyticsViewTracker.track(
                            AccountDetailsIntroAnalyticsView.ErrorShown(
                                error: .noActiveAccountDetailsForCurrency(currency: currencyCode)
                            )
                        )
                        return
                    }
                    updateView(accountDetails: accountDetail)

                case let .recoverableError(error):
                    view?.hideHud()
                    showError(message: error.localizedDescription)
                    analyticsViewTracker.track(
                        AccountDetailsIntroAnalyticsView.ErrorShown(
                            error: .fetchError(message: error.localizedDescription)
                        )
                    )
                }
            }
    }

    func updateView(accountDetails: ActiveAccountDetails) {
        guard let view else { return }
        let viewModel = AccountDetailsInfoIntroViewModelFactory.make(
            shouldShowDetailsSummary: shouldShowDetailsSummary,
            view: view,
            maxNumberOfDetailItems: Constants.maxNumberOfDetailItems,
            currencyCode: currencyCode,
            details: accountDetails.receiveOptions.first?.details ?? [],
            navigationActions: [
                AccountDetailsInfoIntroNavigationAction(
                    viewModel: OptionViewModel(
                        title: L10n.AccountDetails.Intro.Options.Section.Receive.Salary.title,
                        subtitle: L10n.AccountDetails.Intro.Options.Section.Receive.Salary.subtitle,
                        avatar: AvatarViewModel.icon(
                            Icons.requestReceive.image
                        )
                    ),
                    action: { [weak self] in
                        guard let self else { return }
                        analyticsViewTracker.track(
                            AccountDetailsIntroAnalyticsView.ThingsYouCanDoOptionSelected(
                                option: .receiveSalary
                            )
                        )
                        router.showSalarySwitch(
                            balanceId: accountDetails.balanceId,
                            currencyCode: accountDetails.currency,
                            profile: profile
                        )
                    }
                ),
                AccountDetailsInfoIntroNavigationAction(
                    viewModel: OptionViewModel(
                        title: L10n.AccountDetails.Intro.Options.Section.Receive.Money.title,
                        // Temporary title till we implement https://transferwise.atlassian.net/browse/RA-3569
                        subtitle: L10n.AccountDetails.Intro.Options.Section.Receive.Money.subtitle,
                        avatar: AvatarViewModel.icon(
                            Icons.emailAndMobile.image
                        )
                    ),
                    action: { [weak self] in
                        guard let self else { return }
                        analyticsViewTracker.track(
                            AccountDetailsIntroAnalyticsView.ThingsYouCanDoOptionSelected(
                                option: .receiveMoney
                            )
                        )
                        router.showReceiveMoney()
                    }
                ),
            ],
            footerAction: { [weak self] in
                guard let self else { return }
                analyticsViewTracker.track(
                    AccountDetailsIntroAnalyticsView.AccountDetailsExpanded()
                )
                router.showAccountDetailsInfo(
                    profile: profile,
                    accountDetails: accountDetails
                )
            }
        )
        view.configure(viewModel: viewModel)
    }

    func showError(message: String) {
        view?.showErrorAlert(
            title: L10n.Generic.Error.title,
            message: message
        )
    }
}
