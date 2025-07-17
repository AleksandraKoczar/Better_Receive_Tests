import Combine
import CombineSchedulers
import ContactsKit
import LoggingKit
import Neptune
import Prism
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol QuickpayPayerPresenter: AnyObject {
    func start(with view: QuickpayPayerView)
    func dismiss()
    func moneyValueUpdated(_ value: String?)
    func moneyInputCurrencyTapped()
    func descriptionValueUpdated(_text: String?)
    func continueTapped(inputs: QuickpayPayerInputs)
}

final class QuickpayPayerPresenterImpl {
    private weak var view: QuickpayPayerView?
    private let profile: Profile
    private let businessInfo: ContactSearch
    private let quickpayName: String
    private let quickpayUseCase: QuickpayUseCase
    private let analyticsTracker: QuickpayTracking
    private weak var router: QuickpayPayerRouter?
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var quickpayPayerInputs: QuickpayPayerInputs?
    private var localData: QuickpayLocalInfo?
    private var fetchCurrenciesCancellable: AnyCancellable?
    private var createAcquiringPaymentCancellable: AnyCancellable?

    init(
        profile: Profile,
        businessInfo: ContactSearch,
        quickpayName: String,
        quickpayPayerInputs: QuickpayPayerInputs?,
        quickpayUseCase: QuickpayUseCase,
        analyticsTracker: QuickpayTracking,
        router: QuickpayPayerRouter,
        scheduler: AnySchedulerOf<DispatchQueue>
    ) {
        self.profile = profile
        self.businessInfo = businessInfo
        self.quickpayName = quickpayName
        self.quickpayPayerInputs = quickpayPayerInputs
        self.quickpayUseCase = quickpayUseCase
        self.analyticsTracker = analyticsTracker
        self.router = router
        self.scheduler = scheduler
    }
}

extension QuickpayPayerPresenterImpl: QuickpayPayerPresenter {
    func start(with view: QuickpayPayerView) {
        self.view = view
        fetchCurrencies(view: view)
    }

    func continueTapped(inputs: QuickpayPayerInputs) {
        guard let amount = inputs.amount else {
            return
        }

        analyticsTracker.onAmountSelectionContinuePressed()

        let body = QuickpayCreateAPBody(
            amount: .init(value: amount, currency: CurrencyCode(inputs.currency)),
            description: inputs.description
        )

        createAcquiringPaymentCancellable = quickpayUseCase.createAcquiringPayment(wisetag: quickpayName, body: body)
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }

                switch result {
                case .success:
                    let payerData = QuickpayPayerData(
                        value: amount,
                        currency: CurrencyCode(inputs.currency),
                        description: inputs.description,
                        businessQuickpay: quickpayName
                    )

                    router?.navigateToPayWithWise(payerData: payerData)
                case let .failure(error):
                    handleCreateAcquiringPaymentError(error: error)
                    trackError(error)
                }
            }
    }

    func moneyInputCurrencySelected(_ currency: CurrencyCode) {
        localData?.updateSelectedCurrency(currency: currency)
        view?.updateSelectedCurrency(currency: currency)
    }

    func moneyInputCurrencyTapped() {
        guard let localData else {
            return
        }
        router?.showCurrencySelector(
            activeCurrencies: localData.eligibleBalances,
            selectedCurrency: localData.selectedCurrency
        ) { [weak self] currency in
            self?.moneyInputCurrencySelected(currency)
        }
    }

    func moneyValueUpdated(_ value: String?) {
        guard let value,
              let amount = MoneyFormatter.number(value)?.decimalValue, amount > 0 else {
            view?.footerButtonState(enabled: false)
            localData?.updateAmount(amount: nil)
            return
        }
        localData?.updateAmount(amount: amount)
        view?.footerButtonState(enabled: true)
    }

    func descriptionValueUpdated(_text: String?) {
        view?.footerButtonState(enabled: true)
    }

    func dismiss() {
        router?.dismiss()
    }
}

// MARK: Tracking

private extension QuickpayPayerPresenterImpl {
    func trackError(_ error: QuickpayError) {
        let errorMessage: String? =
            switch error.code {
            case .amountTooHigh:
                "Amount is too high"
            case .amountTooLow:
                "Amount is too low"
            case .noPaymentMethods:
                "No payments methods available"
            case .noAvailableCurrency:
                "No currency available"
            case .badDescription:
                "Bad description"
            case .other:
                "Other"
            }
        analyticsTracker.onAmountSelectionContinueFailed(errorMessage: errorMessage)
    }
}

// MARK: Error Handling

private extension QuickpayPayerPresenterImpl {
    func handleCreateAcquiringPaymentError(error: QuickpayError) {
        switch error.code {
        case .badDescription:
            configureView()
            view?.footerButtonState(enabled: false)
            view?.descriptionInputError(error.message ?? error.localizedDescription)
        case .amountTooHigh,
             .amountTooLow:
            configureView()
            view?.footerButtonState(enabled: false)
            view?.moneyInputError(error.message ?? error.localizedDescription)
        default:
            showError(title: error.message, message: nil, ctaTitle: NeptuneLocalization.Button.Title.tryAgain)
        }
    }

    func showError(title: String?, message: String?, ctaTitle: String?) {
        let errorViewModel = ErrorViewModel(
            illustrationConfiguration: .warning,
            title: title ?? L10n.Generic.Error.title,
            message: .text(message),
            primaryViewModel: .init(
                title: ctaTitle ?? NeptuneLocalization.Button.Title.gotIt,
                handler: { [weak self] in
                    guard let self, let view else { return }
                    fetchCurrencies(view: view)
                }
            )
        )
        view?.configureError(with: errorViewModel)
    }
}

// MARK: Data Pipeline

private extension QuickpayPayerPresenterImpl {
    func fetchCurrencies(view: QuickpayPayerView) {
        fetchCurrenciesCancellable = quickpayUseCase.getCurrencyAvailability(wisetag: quickpayName)
            .receive(on: scheduler)
            .handleLoading(view)
            .sink { [weak self] model in
                guard let self else { return }

                guard let availability = model.content else {
                    showError(title: model.error?.message, message: nil, ctaTitle: nil)
                    return
                }

                localData = QuickpayLocalInfo(
                    eligibleBalances: availability.availableCurrencies,
                    selectedCurrency: availability.preferredCurrency
                )
                goToNextStep(inputs: quickpayPayerInputs)
            }
    }

    func goToNextStep(inputs: QuickpayPayerInputs?) {
        guard let inputs,
              let amount = inputs.amount,
              inputs.amount.isNonNil,
              inputs.currency.isNonEmpty else {
            configureView()
            view?.footerButtonState(enabled: false)
            quickpayPayerInputs = nil
            analyticsTracker.onAmountSelectionStarted()
            return
        }
        analyticsTracker.onLoadedWithQueryParameters(
            amount: KotlinDouble(double: amount.doubleValue),
            currency: inputs.currency,
            hasDescription: inputs.description.isNonEmpty
        )
        continueTapped(inputs: inputs)
        quickpayPayerInputs = nil
    }

    func configureView() {
        guard let localData else {
            return
        }
        let amount = localData.amount.map {
            MoneyFormatter.format($0 as NSDecimalNumber)
        }

        let viewModel = QuickpayPayerViewModel(
            avatar: businessInfo.contact.avatarPublisher.avatarPublisher
                .map { AvatarViewModel(avatar: $0) }
                .eraseToAnyPublisher(),
            businessName: businessInfo.contact.title,
            subtitle: businessInfo.contact.subtitle,
            moneyInputViewModel: MoneyInputViewModel(
                titleText: L10n.QuickpayPayer.BusinessInfo.moneyInput,
                amount: amount,
                currencyName: localData.selectedCurrency.value,
                currencyAccessibilityName: localData.selectedCurrency.localizedCurrencyName,
                flagImage: localData.selectedCurrency.icon
            ),
            description: quickpayPayerInputs?.description
        )

        view?.configure(with: viewModel)
    }
}
