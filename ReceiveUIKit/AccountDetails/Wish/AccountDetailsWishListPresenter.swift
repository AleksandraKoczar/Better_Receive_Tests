import BalanceKit
import Combine
import CombineSchedulers
import Foundation
import HttpClientKit
import Neptune
import TransferResources
import TWFoundation
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsWishListPresenter {
    func start(with view: AccountDetailsWishView)
    func toggleSelection(at index: Int)
    func updateSearchQuery(_ query: String)
    func reload()
}

final class AccountDetailsWishListPresenterImpl {
    private weak var view: AccountDetailsWishView?

    private let userProvider: UserProvider
    private let country: Country?
    private let interactor: AccountDetailsWishListInteractor
    private let wishUseCase: BalanceWishUseCase
    private let completion: () -> Void

    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var balanceCurrencyCancellable: AnyCancellable?
    private var wishCancellable: AnyCancellable?

    private var nonSupportedCurrencies: [AccountDetailsWishListBalanceCurrency] = [] {
        didSet {
            filteredCurrencies = nonSupportedCurrencies
        }
    }

    private var filteredCurrencies: [AccountDetailsWishListBalanceCurrency] = [] {
        didSet {
            configureView(with: filteredCurrencies)
        }
    }

    private var searchQuery: String? {
        didSet {
            searchQueryChanged()
        }
    }

    init(
        country: Country?,
        interactor: AccountDetailsWishListInteractor,
        wishUseCase: BalanceWishUseCase,
        userProvider: UserProvider = GOS[UserProviderKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main,
        completion: @escaping () -> Void
    ) {
        self.interactor = interactor
        self.wishUseCase = wishUseCase
        self.userProvider = userProvider
        self.country = country
        self.scheduler = scheduler
        self.completion = completion
    }

    private func getBalanceCurrencies() {
        view?.showHud()

        balanceCurrencyCancellable = interactor.currencies(for: userProvider.activeProfile?.id)
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else { return }

                switch result {
                case let .success(currencies):
                    view?.hideHud()
                    nonSupportedCurrencies = currencies.filter { $0.hasAccountDetails == false }
                case let .failure(error):
                    handleError(error) { [weak self] in
                        self?.getBalanceCurrencies()
                    }
                }
            }
    }

    private func searchQueryChanged() {
        guard let query = searchQuery else {
            return
        }

        filteredCurrencies = nonSupportedCurrencies.filter { balance in
            balance.code.value.uppercased().hasPrefix(query.uppercased())
                || balance.code.localizedCurrencyName.containsCaseInsensitive(query)
        }
    }

    private func configureView(with currencies: [AccountDetailsWishListBalanceCurrency]) {
        view?.configure(options: currencies.map {
            OptionViewModel(
                title: $0.code.localizedCurrencyName,
                subtitle: $0.code.value,
                leadingView: .avatar(.image(
                    $0.code.squareIcon
                )),
                isEnabled: true
            )
        })
    }

    private func sendWish(currency: AccountDetailsWishListBalanceCurrency) {
        view?.showHud()

        wishCancellable?.cancel()

        wishCancellable = wishUseCase.createWish(
            BalanceWish(type: .accountDetails, currency: currency.code, country: country, reason: nil)
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else { return }
            view?.hideHud()

            switch result {
            case .success:
                showSuccess()
            case let .failure(error):
                guard case .alreadyVoted = error else {
                    return handleError(error) { [weak self] in
                        self?.sendWish(currency: currency)
                    }
                }
                showSuccess()
            }
        }
    }

    private func showSuccess() {
        view?.dismiss()
        completion()
    }

    private func handleError(_ error: Error, retry: @escaping () -> Void) {
        view?.showRetryAlert(
            withTitle: L10n.Generic.Error.title,
            message: error.localizedDescription,
            action: retry,
            cancelAction: { [weak self] in
                self?.view?.dismiss()
            }
        )
    }
}

extension AccountDetailsWishListPresenterImpl: AccountDetailsWishListPresenter {
    func start(with view: AccountDetailsWishView) {
        self.view = view
        getBalanceCurrencies()
    }

    func toggleSelection(at index: Int) {
        guard let selectedBalance = filteredCurrencies[safe: index] else {
            return
        }
        // TODO: multi select
        sendWish(currency: selectedBalance)
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
    }

    func reload() {
        getBalanceCurrencies()
    }
}
