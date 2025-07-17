import BalanceKit
import Combine
import CombineSchedulers
import Neptune
import TransferResources
import TWFoundation
import WiseCore

protocol AccountDetailsMultipleSelectionPresenter {
    func start(withView view: AccountDetailsMultipleSelectionView)
    func searchQueryUpdated(_ text: String)
    func cellTapped(currencyCode: CurrencyCode)
    func continueButtonTapped()
    func secondaryActionTapped()
    func sectionHeaderTapped()
    func isCurrencySelected(_ currencyCode: CurrencyCode) -> Bool
}

final class AccountDetailsMultipleSelectionPresenterImpl: AccountDetailsMultipleSelectionPresenter {
    private let feeRequirement: AccountDetailsRequirement?
    private var preselectedCurrencies: [CurrencyCode]
    private let interactor: AccountDetailsMultipleSelectionInteractor
    private let router: AccountDetailsMultipleSelectionRouter
    private var subscriptions = Set<AnyCancellable>()
    private weak var view: AccountDetailsMultipleSelectionView?
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var accountDetails: [AvailableAccountDetails] = [] {
        didSet {
            // We need to filter unique account details because we can have more than one account details per currency
            uniqueAccountDetails = filterUniqueAccountDetails(from: accountDetails)
        }
    }

    private var uniqueAccountDetails: [AvailableAccountDetails] = [] {
        didSet {
            filteredAccountDetails = uniqueAccountDetails
        }
    }

    private var filteredAccountDetails: [AvailableAccountDetails] = [] {
        didSet {
            updateCurrenciesDisplayed(filteredAccountDetails)
        }
    }

    private var selectedAccountDetails: [AvailableAccountDetails] = [] {
        didSet {
            view?.updateButtonState(enabled: selectedAccountDetails.isNonEmpty)
            updateCurrenciesDisplayed(filteredAccountDetails)
        }
    }

    init(
        feeRequirement: AccountDetailsRequirement?,
        preselectedCurrencies: [CurrencyCode],
        interactor: AccountDetailsMultipleSelectionInteractor,
        router: AccountDetailsMultipleSelectionRouter,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.feeRequirement = feeRequirement
        self.preselectedCurrencies = preselectedCurrencies
        self.interactor = interactor
        self.router = router
        self.scheduler = scheduler
    }

    func start(withView view: AccountDetailsMultipleSelectionView) {
        self.view = view
        let subtitle = {
            if let fee = feeRequirement?.fee,
               feeRequirement?.status != .done {
                let formattedPrice = MoneyFormatter.format(fee)
                return L10n.AccountDetails.MultipleSelection.subtitleWithFee(formattedPrice)
            } else {
                return L10n.AccountDetails.MultipleSelection.subtitle
            }
        }()
        let headerModel = LargeTitleViewModel(
            title: L10n.AccountDetails.MultipleSelection.title,
            description: subtitle,
            searchFieldPlaceholder: L10n.AccountDetails.MultipleSelection.searchPlaceholder
        )
        view.configureHeader(viewModel: headerModel)
        observeAccountDetails()
    }

    func searchQueryUpdated(_ text: String) {
        filteredAccountDetails = uniqueAccountDetails.filter { accountDetails in
            accountDetails.currency.value.uppercased().hasPrefix(text.uppercased())
                || accountDetails.currencyName.containsCaseInsensitive(text.localizedUppercase)
        }
    }

    func cellTapped(currencyCode: CurrencyCode) {
        preselectedCurrencies.removeFirst { $0 == currencyCode }
        toggleSelection(for: currencyCode)
    }

    func continueButtonTapped() {
        router.route(action: .currenciesSelected(selectedAccountDetails.map { $0.currency }))
    }

    func secondaryActionTapped() {
        router.route(
            action: .wishList(
                completion: { [weak self] in
                    guard let self else { return }
                    // Add some delay for snack bar display to avoid overlap with screen refresh
                    scheduler.schedule(after: scheduler.now.advanced(by: 0.2)) {
                        self.view?.presentSnackBar(
                            message: L10n.AccountDetails.List.Request.Snack.title
                        )
                    }
                }
            )
        )
    }

    func sectionHeaderTapped() {
        router.route(action: .learnMore)
    }

    func isCurrencySelected(_ currencyCode: CurrencyCode) -> Bool {
        selectedAccountDetails.contains {
            $0.currency == currencyCode
        }
    }

    // MARK: - Private

    private func observeAccountDetails() {
        guard subscriptions.isEmpty else { return }
        interactor.accountDetails
            .handleEvents(receiveOutput: { [weak self] state in
                if state == nil {
                    self?.interactor.refreshAccountDetails()
                }
            })
            .compactMap { $0 }
            .receive(on: scheduler)
            .sink { [weak self] state in
                guard let self else {
                    return
                }
                switch state {
                case .loading:
                    view?.showHud()
                case let .loaded(accountDetails):
                    view?.hideHud()
                    setup(for: accountDetails)
                case .recoverableError:
                    view?.hideHud()
                }
            }
            .store(in: &subscriptions)
    }

    private func setup(for accountDetails: [AccountDetails]) {
        self.accountDetails = accountDetails.availableDetails()
        preselectCurrencies()
    }

    private func filterUniqueAccountDetails(from accountDetails: [AvailableAccountDetails]) -> [AvailableAccountDetails] {
        var uniqueCurrencies: Set<String> = []
        return accountDetails.compactMap { accountDetails -> AvailableAccountDetails? in
            if uniqueCurrencies.contains(accountDetails.currency.value) {
                return nil
            }
            uniqueCurrencies.insert(accountDetails.currency.value)
            return accountDetails
        }
    }

    private func toggleSelection(for currencyCode: CurrencyCode) {
        let selectionPredicate: (AvailableAccountDetails) -> Bool = { accountDetails -> Bool in
            accountDetails.currency == currencyCode
        }
        let selection = filteredAccountDetails.filter(selectionPredicate)
        if selectedAccountDetails.contains(where: selectionPredicate) {
            selectedAccountDetails.removeAll(where: selectionPredicate)
        } else {
            selectedAccountDetails.append(contentsOf: selection)
        }
    }

    private func updateCurrenciesDisplayed(_ accountDetails: [AvailableAccountDetails]) {
        let viewModel = AccountDetailsMultipleSelectionViewModel(sections: [
            .init(
                title: L10n.AccountDetails.MultipleSelection.sectionTitle,
                actionTitle: L10n.AccountDetails.MultipleSelection.sectionActionTitle,
                items: accountDetails.map {
                    .init(
                        currencyCode: $0.currency,
                        image: $0.currency.squareIcon,
                        title: $0.currencyName,
                        description: $0.subtitle
                    )
                }
            ),
        ])
        view?.updateList(viewModel: viewModel)
    }
}

// MARK: - Account details preselection

private extension AccountDetailsMultipleSelectionPresenterImpl {
    func preselectCurrencies() {
        guard preselectedCurrencies.isNonEmpty else {
            return
        }
        reorderAccountDetails(for: preselectedCurrencies)
        applyPreselection(for: preselectedCurrencies)
    }

    func reorderAccountDetails(for currencies: [CurrencyCode]) {
        let indexes = currencies.reduce(into: [Int]()) { result, currency in
            if let index = uniqueAccountDetails.firstIndex(where: { $0.currency == currency }) {
                result.append(index)
            }
        }
        if indexes.isNonEmpty {
            uniqueAccountDetails.move(fromOffsets: IndexSet(indexes), toOffset: 0)
        }
    }

    func applyPreselection(for currencies: [CurrencyCode]) {
        currencies.forEach { currency in
            let matchingCurrency: (AvailableAccountDetails) -> Bool = { $0.currency == currency }
            let selection = filteredAccountDetails.filter(matchingCurrency)
            if !selectedAccountDetails.contains(where: matchingCurrency) {
                selectedAccountDetails.append(contentsOf: selection)
            }
        }
    }
}
