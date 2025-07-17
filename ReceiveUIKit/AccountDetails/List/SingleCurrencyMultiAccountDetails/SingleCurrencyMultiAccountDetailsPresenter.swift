import AnalyticsKit
import BalanceKit
import Combine
import CombineSchedulers
import Neptune
import TransferResources
import TWFoundation
import UIKit
import UserKit
import WiseCore

enum SingleCurrencyMultiAccountDetailsDisplaySource {
    case currencyCode(CurrencyCode)
    case accountDetailsList([ActiveAccountDetails])
}

// Used for cases where we have multiple instances account details for a single currency
final class SingleCurrencyMultiAccountDetailsPresenterImpl {
    private weak var view: AccountDetailsListView?
    private let analyticsTracker: AnalyticsTracker
    private let router: AccountDetailsListRouter
    private let useCase: AccountDetailsUseCase
    private let profile: Profile
    private var accountDetails: [ActiveAccountDetails] = []
    private let source: SingleCurrencyMultiAccountDetailsDisplaySource
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let didDismissCompletion: (() -> Void)?

    private var accountDetailsCancellable: AnyCancellable?

    init(
        router: AccountDetailsListRouter,
        profile: Profile,
        source: SingleCurrencyMultiAccountDetailsDisplaySource,
        useCase: AccountDetailsUseCase,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main,
        didDismissCompletion: (() -> Void)?
    ) {
        self.profile = profile
        self.source = source
        self.router = router
        self.useCase = useCase
        self.scheduler = scheduler
        self.analyticsTracker = analyticsTracker
        self.didDismissCompletion = didDismissCompletion
    }

    func start(withView view: AccountDetailsListView) {
        self.view = view
        analyticsTracker.track(screen: AccountDetailsMultipleCurrencyListScreenItem(currency: accountDetails.first?.currency.value))
        setupData()
    }

    private func processAccountDetails(_ accountDetails: [ActiveAccountDetails]) {
        let details = accountDetails.sorted(by: { first, _ in
            !hasWarning(accountDetails: first)
        })
        self.accountDetails = details

        guard details.isNonEmpty else { return }
        let sections = AccountDetailListSectionModel(
            header: nil,
            items: details.map {
                AccountDetailListItemViewModel(forSingleCurrencyList: AccountDetails.active($0))
            },
            footer: nil
        )

        view?.updateList(sections: [sections])
    }

    private func setupData() {
        view?.configureHeader(viewModel: LargeTitleViewModel(
            title: L10n.AccountDetails.List.title,
            description: L10n.AccountDetails.List.Multiple.SingleCurrency.subtitle
        ))
        view?.setupNavigationLeftButton(
            buttonStyle: .arrow,
            buttonAction: { [weak self] in
                self?.router.dismiss()
            }
        )
        switch source {
        case let .currencyCode(currencyCode):
            fetchAccountDetails(
                currencyCode: currencyCode,
                onSuccess: { [weak self] details in
                    guard let self else { return }
                    processAccountDetails(details)
                }
            )
        case let .accountDetailsList(details):
            processAccountDetails(details)
        }
    }

    private func fetchAccountDetails(
        currencyCode: CurrencyCode,
        onSuccess: @escaping ([ActiveAccountDetails]) -> Void
    ) {
        accountDetailsCancellable = useCase.accountDetails
            .handleEvents(receiveOutput: { [weak self] state in
                if state == nil {
                    self?.useCase.refreshAccountDetails()
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
                    let filteredDetails = accountDetails.activeDetails().filter {
                        $0.currency == currencyCode
                    }
                    onSuccess(filteredDetails)
                case let .recoverableError(error):
                    view?.hideHud()
                    view?.presentAlert(message: error.localizedDescription, backAction: { [weak self] in
                        self?.router.dismiss()
                    })
                }
            }
    }

    private func hasWarning(accountDetails: ActiveAccountDetails) -> Bool {
        let hasWarning = accountDetails.receiveOptions.contains { receiveOption in
            switch receiveOption.alert?.type {
            case .error,
                 .warning:
                true
            case .none,
                 .info,
                 .success:
                false
            }
        }
        return hasWarning || accountDetails.isDeprecated
    }
}

// MARK: Protocol implementation

extension SingleCurrencyMultiAccountDetailsPresenterImpl: AccountDetailListPresenter {
    func cellTapped(indexPath: IndexPath) {
        guard let details = accountDetails[safe: indexPath.row] else { return }
        router.showSingleAccountDetails(details, profile: profile)
    }

    func dismissed() {
        didDismissCompletion?()
    }

    // TODO: These presenters have grown apart too much, we should split them
    func footerTapped() {}
    func updateSearchQuery(_ searchText: String) {}
    func viewDidAppear() {}
}
