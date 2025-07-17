import Combine
import CombineSchedulers
import ContactsKit
import LoggingKit
import Neptune
import Prism
import ReceiveKit
import RecipientsKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

final class QuickpayPayerFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private let profile: Profile
    private let nickname: String
    private let amount: String?
    private let currency: CurrencyCode?
    private let description: String?
    private weak var navigationController: UINavigationController?
    private weak var lookupContactFailureBottomSheet: UIViewController?

    private let viewControllerFactory: QuickpayPayerViewControllerFactory
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory
    private let wisetagContactInteractor: WisetagContactInteractor
    private let payWithWiseFlowFactory: PayWithWiseFlowFactory
    private let analyticsTracker: QuickpayTracking
    private let userProvider: UserProvider
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let urlOpener: UrlOpener

    private var fetchProfileCancellable: AnyCancellable?
    private var bottomSheetDismisser: BottomSheetDismisser?
    private var payWithWiseFlow: (any Flow<Void>)?
    private var businessInfo: ContactSearch?

    init(
        profile: Profile,
        nickname: String,
        amount: String?,
        currency: CurrencyCode?,
        description: String?,
        navigationController: UINavigationController,
        viewControllerFactory: QuickpayPayerViewControllerFactory,
        viewControllerPresenterFactory: ViewControllerPresenterFactory,
        wisetagContactInteractor: WisetagContactInteractor,
        payWithWiseFlowFactory: PayWithWiseFlowFactory,
        userProvider: UserProvider,
        analyticsTracker: QuickpayTracking,
        urlOpener: UrlOpener,
        scheduler: AnySchedulerOf<DispatchQueue>
    ) {
        self.profile = profile
        self.nickname = nickname
        self.amount = amount
        self.currency = currency
        self.description = description
        self.navigationController = navigationController
        self.viewControllerFactory = viewControllerFactory
        self.wisetagContactInteractor = wisetagContactInteractor
        self.payWithWiseFlowFactory = payWithWiseFlowFactory
        self.userProvider = userProvider
        self.analyticsTracker = analyticsTracker
        self.urlOpener = urlOpener
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
        self.scheduler = scheduler
    }

    func start() {
        flowHandler.flowStarted()
        fetchProfileCancellable = wisetagContactInteractor.lookupContact(profileId: profile.id, nickname: nickname)
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                switch result {
                case let .success(contactSearch):
                    if contactSearch.isSelf {
                        analyticsTracker.onLoaded(isMatchFound: true, isSelf: true, hasAvatar: contactSearch.contact.hasAvatar)
                    }

                    switch contactSearch.pageType {
                    case .business:
                        businessInfo = contactSearch
                        startPayerFlow(businessInfo: contactSearch)
                        analyticsTracker.onLoaded(
                            isMatchFound: true,
                            isSelf: false,
                            hasAvatar: contactSearch.contact.hasAvatar
                        )
                    case .personal,
                         .unknown,
                         .none:
                        showFailureBottomsheet(
                            title: L10n.Quickpay.Error.UserNotFound.title,
                            message: L10n.Quickpay.Error.UserNotFound.subtitle
                        )
                        analyticsTracker.onLoaded(
                            isMatchFound: false,
                            isSelf: false,
                            hasAvatar: contactSearch.contact.hasAvatar
                        )
                    }

                case .failure:
                    showFailureBottomsheet(
                        title: L10n.Quickpay.Error.UserNotFound.title,
                        message: L10n.Quickpay.Error.UserNotFound.subtitle
                    )
                    analyticsTracker.onLoaded(isMatchFound: false, isSelf: false, hasAvatar: false)
                }
            }
    }

    func terminate() {
        flowHandler.flowFinished(result: (), dismisser: bottomSheetDismisser)
    }
}

// MARK: - QuickpayPayerRouter

extension QuickpayPayerFlow: QuickpayPayerRouter {
    func showCurrencySelector(
        activeCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: @escaping (CurrencyCode) -> Void
    ) {
        guard let navigationController else {
            softFailure("[REC] Attempt to show currency selector when the primary navigation controller is empty.")
            return
        }

        func filterSearchResults(_ currencies: [CurrencyCode]) -> (_ query: String) -> CurrencyList<CurrencyCode> {
            let searchResultsFilter: ([CurrencyCode], String) -> ([CurrencyCode]) = { input, query in
                input
                    .filter { $0.value.uppercased().hasPrefix(query) || $0.localizedCurrencyName.containsCaseInsensitive(query) }
            }
            return { query in
                SearchResultsCurrenciesList(filtered: searchResultsFilter(currencies, query), searchQuery: query)
            }
        }

        let currencySelectorViewController = CurrencySelectorFactoryImpl.make(
            items: SectionedCurrenciesList([
                .init(
                    title: L10n.Convertbalance.CurrencyPicker.yourBalances,
                    currencies: activeCurrencies
                ),
            ]),
            configuration: CurrencySelectorConfiguration(selectedItem: selectedCurrency),
            searchResultsFilter: filterSearchResults(activeCurrencies),
            onSelect: onCurrencySelected,
            onDismiss: nil
        )

        navigationController.visibleViewController?.present(
            currencySelectorViewController,
            animated: UIView.shouldAnimate
        )
    }

    func navigateToPayWithWise(payerData: QuickpayPayerData) {
        guard let bottomSheetDismisser else {
            makePayWithWiseFlow(payerData: payerData)
            return
        }

        bottomSheetDismisser.dismiss { [weak self] in
            guard let self else {
                return
            }
            makePayWithWiseFlow(payerData: payerData)
        }
    }

    func dismiss() {
        terminate()
    }
}

private extension QuickpayPayerFlow {
    private enum Constants {
        static let quickpayPath = "/pay/business"
    }

    func startPayerFlow(businessInfo: ContactSearch) {
        guard let navigationController else {
            softFailure("[REC] Attempt to start quickpay payer flow when the primary navigation controller is empty.")
            return
        }
        let payerInputs = getPayerInputs()
        let viewController = viewControllerFactory.makePayerBottomsheet(
            profile: profile,
            quickpay: nickname,
            payerInputs: payerInputs,
            businessInfo: businessInfo,
            router: self
        )

        let bottomSheetPresenter = viewControllerPresenterFactory.makeBottomSheetPresenter(parent: navigationController)
        bottomSheetDismisser = bottomSheetPresenter.present(
            viewController: viewController,
            completion: nil
        )
    }

    func openUrl(url: URL) {
        guard urlOpener.canOpenURL(url) else {
            return
        }
        urlOpener.open(url)
        dismiss()
    }

    func getPayerInputs() -> QuickpayPayerInputs? {
        if let amount,
           let decimalAmount = Decimal(string: amount),
           let currency = currency?.value {
            QuickpayPayerInputs(
                amount: decimalAmount,
                currency: currency,
                description: description
            )
        } else {
            QuickpayPayerInputs(
                amount: nil,
                currency: "",
                description: description
            )
        }
    }

    func makeURLForQuickpay(
        quickpay: String
    ) -> URL? {
        guard let components = URLComponents(
            url: Branding.current.url
                .appendingPathComponent(Constants.quickpayPath)
                .appendingPathComponent(quickpay),
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }
        return components.url
    }

    func makePayWithWiseFlow(payerData: QuickpayPayerData) {
        guard let navigationController else {
            softFailure("[REC] Attempt to start pay with wise flow when the primary navigation controller is empty.")
            return
        }

        guard let businessInfo else {
            softFailure("[REC] Attempt to start pay with wise flow for quickpay with no receiver info.")
            return
        }

        let flow = payWithWiseFlowFactory.makeModalFlow(
            payerData: payerData,
            businessInfo: businessInfo,
            profile: profile,
            host: navigationController
        )

        flow.onFinish { [weak self] _, dismisser in
            self?.payWithWiseFlow = nil
            self?.flowHandler.flowFinished(result: (), dismisser: dismisser)
        }

        payWithWiseFlow = flow
        flow.start()
    }

    func showFailureBottomsheet(title: String?, message: String?) {
        let controller = BottomSheetViewController.makeErrorSheet(viewModel: ErrorViewModel(
            illustrationConfiguration: .warning,
            title: title ?? L10n.Generic.Error.title,
            message: .text(message ?? L10n.Generic.Error.message),
            primaryViewModel: .dismiss { [weak self] in
                self?.lookupContactFailureBottomSheet?.dismiss(animated: UIView.shouldAnimate)
                self?.dismiss()
            }
        ))

        navigationController?.presentBottomSheet(controller)
        lookupContactFailureBottomSheet = controller
    }
}
