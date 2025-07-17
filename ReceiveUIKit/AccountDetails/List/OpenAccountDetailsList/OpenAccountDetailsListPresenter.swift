import AnalyticsKit
import BalanceKit
import Combine
import DeepLinkKit
import Neptune
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// For the case where we want to show all the account details for each currency (unique for currency)
final class OpenAccountDetailsListPresenterImpl {
    private weak var view: AccountDetailsListView?

    private var pendingAccountDetailsOrderRoute: DeepLinkAccountDetailsRoute?
    private let accountDetailsUseCase: AccountDetailsUseCase
    private let analyticsTracker: AnalyticsTracker
    private let receiveQueue: DispatchQueue
    private let router: AccountDetailsListRouter
    private let profile: Profile?
    private let userInfo: UserInfo
    private let country: Country?
    private let didDismissCompletion: () -> Void
    private let completion: (CurrencyCode) -> Void

    private var accountDetails: [AccountDetails] = [] {
        didSet {
            // We need to filter unique account details because we can have more than one account details per currency
            uniqueAccountDetails = filterUniqueAccountDetails(from: accountDetails)
        }
    }

    private let leftNavigationButton: OpenAccountDetailsListLeftNavigationButton

    // duplicatedCurrencies are the currencies with multiple account details
    private var duplicatedCurrencies: [CurrencyCode] = []
    private var uniqueAccountDetails: [AccountDetails] = [] {
        didSet {
            filteredAccountDetails = uniqueAccountDetails
        }
    }

    private var filteredAccountDetails: [AccountDetails] = [] {
        didSet {
            configureView(filteredAccountDetails)
        }
    }

    private var accountDetailsCancellable: AnyCancellable?

    private var listedAccountDetails: [Int: [AccountDetails]] = [:]

    private var leftNavigationButtonStyle: UIBarButtonItem.BackButtonType {
        switch leftNavigationButton {
        case .dismissButton:
            .cross
        case .backButton:
            .arrow
        }
    }

    init(
        accountDetailsUseCase: AccountDetailsUseCase,
        pendingAccountDetailsOrderRoute: DeepLinkAccountDetailsRoute?,
        router: AccountDetailsListRouter,
        profile: Profile?,
        userInfo: UserInfo,
        country: Country?,
        leftNavigationButton: OpenAccountDetailsListLeftNavigationButton,
        receiveQueue: DispatchQueue = .main,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        completion: @escaping (CurrencyCode) -> Void,
        didDismissCompletion: @escaping () -> Void
    ) {
        self.accountDetailsUseCase = accountDetailsUseCase
        self.router = router
        self.profile = profile
        self.userInfo = userInfo
        self.pendingAccountDetailsOrderRoute = pendingAccountDetailsOrderRoute
        self.analyticsTracker = analyticsTracker
        self.leftNavigationButton = leftNavigationButton
        self.receiveQueue = receiveQueue
        self.country = country
        self.completion = completion
        self.didDismissCompletion = didDismissCompletion
    }

    private func handleError() {
        let message = L10n.AccountDetails.Error.AccountDetailsListMessage.fetchAccountDetails
        view?.presentAlert(message: message, backAction: { [weak self] in
            self?.router.dismiss()
        })
    }

    private func filterUniqueAccountDetails(from accountDetails: [AccountDetails]) -> [AccountDetails] {
        var uniqueCurrencies: [String] = []
        let userCanManageBalances = profile?.has(privilege: BalancePrivilege.manage) ?? true
        return accountDetails.compactMap { accountDetails -> AccountDetails? in
            if uniqueCurrencies.contains(where:
                { $0 == accountDetails.currency.value }) {
                self.duplicatedCurrencies.append(accountDetails.currency)
                return nil
            }

            // If the profile doesn't have permissions to open balance account,
            // Then only append open balances.
            if !userCanManageBalances,
               !accountDetails.isActive {
                return nil
            }

            uniqueCurrencies.append(accountDetails.currency.value)
            return accountDetails
        }
    }

    private func setupData() {
        view?.configureHeader(viewModel: LargeTitleViewModel(
            title: L10n.AccountDetails.List.title,
            description: L10n.AccountDetails.List.Subtitle.active,
            searchFieldPlaceholder: L10n.AccountDetails.List.Search.placeholder
        ))

        setupNavigationLeftButton()
        observeAccountDetails()
    }

    func viewDidAppear() {
        observeAccountDetails()
    }

    private func setupNavigationLeftButton() {
        view?.setupNavigationLeftButton(
            buttonStyle: leftNavigationButtonStyle,
            buttonAction: { [weak self] in
                self?.router.dismiss()
            }
        )
    }

    private func configureView(_ accountDetails: [AccountDetails]) {
        let footer = country == nil ? nil : L10n.AccountDetails.List.Footer.title
        guard accountDetails.isNonEmpty else {
            listedAccountDetails = [:]
            view?.updateList(
                sections: [
                    AccountDetailListSectionModel(
                        header: nil,
                        items: [],
                        footer: footer
                    ),
                ]
            )
            return
        }

        let activeDetails = accountDetails.filter { $0.isActive }
        let availableDetails = accountDetails.filter { !$0.isActive }

        ///  When we have both active and deprecated details for a currency
        ///  We already merge them under the active group
        ///  So they shouldn't be repeated on both active and deprecated list
        let activeDetailCurrencies = Set(activeDetails.map { $0.currency })
        let deprecatedDetails: [AccountDetails] = accountDetails
            .lazy
            .filter { $0.isDeprecated }
            .filter { !activeDetailCurrencies.contains($0.currency) }

        var sectionIndex = 0
        var listedAccountDetails: [Int: [AccountDetails]] = [:]
        var sections: [AccountDetailListSectionModel] = []
        if activeDetails.isNonEmpty {
            let hasFooter = availableDetails.isEmpty && deprecatedDetails.isEmpty
            sections.append(
                AccountDetailListSectionModel(
                    header: SectionHeaderViewModel(
                        title: L10n.AccountDetails.List.Header.Active.title
                    ),
                    items: activeDetails.map { createListItemViewModel($0) },
                    footer: hasFooter ? footer : nil
                )
            )
            listedAccountDetails[sectionIndex] = activeDetails
            sectionIndex += 1
        }

        if availableDetails.isNonEmpty {
            let hasFooter = deprecatedDetails.isEmpty
            sections.append(
                AccountDetailListSectionModel(
                    header: SectionHeaderViewModel(
                        title: L10n.AccountDetails.List.Header.Available.title
                    ),
                    items: availableDetails.map {
                        createListItemViewModel($0)
                    },
                    footer: hasFooter ? footer : nil
                )
            )
            listedAccountDetails[sectionIndex] = availableDetails
            sectionIndex += 1
        }

        if deprecatedDetails.isNonEmpty {
            sections.append(
                AccountDetailListSectionModel(
                    header: SectionHeaderViewModel(
                        title: L10n.AccountDetails.List.Header.Deprecated.title
                    ),
                    items: deprecatedDetails.map {
                        createListItemViewModel($0)
                    },
                    footer: footer
                )
            )
            listedAccountDetails[sectionIndex] = deprecatedDetails
        }
        self.listedAccountDetails = listedAccountDetails
        view?.updateList(sections: sections)
    }

    private func openAccountDetails(for currency: CurrencyCode) {
        // stop observing
        accountDetailsCancellable = nil
        completion(currency)
    }

    private func showAccountDetails(_ selectedAccountDetails: ActiveAccountDetails) {
        // If account details exist then a profile must exist too.
        guard let profile else {
            return
        }
        if duplicatedCurrencies.contains(selectedAccountDetails.currency) {
            let allAccountDetailsFromSelectedCurrency = accountDetails
                .activeDetails()
                .filter { $0.currency == selectedAccountDetails.currency }
            router.showMultipleAccountDetails(allAccountDetailsFromSelectedCurrency, profile: profile)
        } else {
            router.showSingleAccountDetails(selectedAccountDetails, profile: profile)
        }
    }

    private func observeAccountDetails() {
        accountDetailsCancellable = accountDetailsUseCase.accountDetails
            .handleEvents(receiveOutput: { [weak self] state in
                if state == nil {
                    self?.accountDetailsUseCase.refreshAccountDetails()
                }
            })
            .compactMap { $0 }
            .receive(on: receiveQueue)
            .sink { [weak self] state in
                switch state {
                case .loading:
                    self?.view?.showHud()
                case let .loaded(accountDetails):
                    self?.view?.hideHud()
                    self?.accountDetails = accountDetails
                    self?.handleDeeplink()
                case .recoverableError:
                    self?.view?.hideHud()
                    self?.handleError()
                }
            }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func handleDeeplink() {
        guard let route = pendingAccountDetailsOrderRoute else { return }
        pendingAccountDetailsOrderRoute = nil

        var selectedAccountDetails: AccountDetails?

        switch route.state {
        case let .view(detailsId):
            selectedAccountDetails = accountDetails
                .first(where: { details in
                    switch details {
                    case let .active(activeAccountDetails):
                        activeAccountDetails.id == detailsId
                    case .available:
                        false
                    }
                })
        case let .viewOrCreate(currencyCode),
             let .create(currencyCode, _):
            selectedAccountDetails = accountDetails.first(where: { $0.currency == currencyCode })
        case .createAny,
             .viewList,
             .viewListForCurrency:
            return
        }

        guard let selectedAccountDetails else { return }

        switch selectedAccountDetails {
        case let .active(activeAccountDetails):
            showAccountDetails(activeAccountDetails)
        case let .available(availableAccountDetails):
            openAccountDetails(for: availableAccountDetails.currency)
        }
    }

    private func createListItemViewModel(
        _ accountDetails: AccountDetails
    ) -> AccountDetailListItemViewModel {
        if duplicatedCurrencies.contains(accountDetails.currency) {
            let allAccountDetails = self.accountDetails.filter {
                $0.currency == accountDetails.currency
            }
            return AccountDetailListItemViewModel(
                forDuplicateCurrenciesList: accountDetails,
                allAcountDetails: allAccountDetails
            )
        } else {
            return AccountDetailListItemViewModel(
                forMultipleCurrencyList: accountDetails
            )
        }
    }
}

// MARK: Protocol implementation

extension OpenAccountDetailsListPresenterImpl: AccountDetailListPresenter {
    func footerTapped() {
        router.requestAccountDetails(
            country: country,
            completion: { [weak self] in
                guard let self else { return }
                // Add some delay for snack bar display to avoid overlap with screen refresh
                receiveQueue.asyncAfter(
                    deadline: .now() + 0.2,
                    execute: {
                        self.view?.presentSnackBar(
                            message: L10n.AccountDetails.List.Request.Snack.title
                        )
                    }
                )
            }
        )
    }

    func updateSearchQuery(_ searchText: String) {
        filteredAccountDetails = uniqueAccountDetails.filter { accountDetails in
            accountDetails.currency.value.uppercased().hasPrefix(searchText.uppercased())
                || accountDetails.currencyName.containsCaseInsensitive(searchText.localizedUppercase)
        }
    }

    func start(withView view: AccountDetailsListView) {
        self.view = view
        analyticsTracker.track(screen: AccountDetailsListScreenItem())
        setupData()
    }

    func cellTapped(indexPath: IndexPath) {
        guard let accountDetails = listedAccountDetails[indexPath.section]?[safe: indexPath.row] else {
            return
        }
        switch accountDetails {
        case let .active(activeAccountDetails):
            showAccountDetails(activeAccountDetails)
        case let .available(availableAccountDetails):
            openAccountDetails(for: availableAccountDetails.currency)
        }
    }

    func dismissed() {
        didDismissCompletion()
    }
}
