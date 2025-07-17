import AnalyticsKit
import BalanceKit
import Combine
import CombineSchedulers
import LoggingKit
import TransferResources
import TWFoundation
import TWUI
import WiseCore

typealias SalarySwitchOptionsAnalyticsView = SalarySwitchFlowAnalytics.OptionsView

enum SalarySwitchOption: Int {
    case shareDetails = 0
    case accountOwnershipProof = 1
}

protocol SalarySwitchOptionSelectionView: SemanticContext {
    var documentInteractionControllerDelegate: UIDocumentInteractionControllerDelegate { get }

    func configure(viewModel: SalarySwitchOptionSelectionViewModel)
    func showErrorAlert(title: String, message: String)
    func showHud()
    func hideHud()
}

// sourcery: AutoMockable
protocol SalarySwitchOptionSelectionPresenter: AnyObject {
    func start(view: SalarySwitchOptionSelectionView)
    func selectedOption(at index: Int, sender: UIView)
}

final class SalarySwitchOptionSelectionPresenterImpl {
    private let router: SalarySwitchOptionSelectionRouter
    private let accountDetailsUseCase: AccountDetailsUseCase
    private let accountOwnershipProofUseCase: AccountOwnershipProofUseCase
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<SalarySwitchOptionsAnalyticsView>

    private let balanceId: BalanceId
    private let currencyCode: CurrencyCode
    private let profileId: ProfileId

    private weak var view: SalarySwitchOptionSelectionView?
    private var accountDetailsCancellable: Cancellable?
    private var accountOwnershipProofCancellable: Cancellable?

    private var accountDetails: ActiveAccountDetails?

    init(
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profileId: ProfileId,
        router: SalarySwitchOptionSelectionRouter,
        accountDetailsUseCase: AccountDetailsUseCase,
        accountOwnershipProofUseCase: AccountOwnershipProofUseCase,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.balanceId = balanceId
        self.currencyCode = currencyCode
        self.profileId = profileId
        self.router = router
        self.accountDetailsUseCase = accountDetailsUseCase
        self.accountOwnershipProofUseCase = accountOwnershipProofUseCase
        self.scheduler = scheduler

        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: SalarySwitchOptionsAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }
}

// MARK: - SalarySwitchOptionSelectionPresenter

extension SalarySwitchOptionSelectionPresenterImpl: SalarySwitchOptionSelectionPresenter {
    func start(view: SalarySwitchOptionSelectionView) {
        analyticsViewTracker.trackView(
            .started,
            properties: [
                SalarySwitchFlowAnalytics.CurrencyProperty(
                    currencyCode: currencyCode
                ),
            ]
        )
        self.view = view
        getAccountDetails()
        let viewModel = SalarySwitchOptionSelectionViewModelFactory.make(
            view: view
        )
        view.configure(viewModel: viewModel)
    }

    func selectedOption(at index: Int, sender: UIView) {
        guard let option = SalarySwitchOption(rawValue: index) else {
            softFailure("[REC]: Selected option is not implemented")
            return
        }
        analyticsViewTracker.track(
            SalarySwitchFlowAnalytics.OptionsView.OptionSelected(
                option: option,
                currencyCode: currencyCode
            )
        )

        switch option {
        case .shareDetails:
            displayShareSheet(sender: sender)
        case .accountOwnershipProof:
            getAccountOwnershipProofDocument()
        }
    }
}

// MARK: - Helpers

private extension SalarySwitchOptionSelectionPresenterImpl {
    func displayShareSheet(sender: UIView) {
        guard let content = accountDetails?.receiveOptions.first?.shareText else {
            softFailure("[REC]: There should be an account details for given currency")
            return
        }
        router.displayShareSheet(content: content, sender: sender)
    }

    func getAccountDetails() {
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
                guard let self,
                      let view else {
                    return
                }
                switch state {
                case .loading:
                    view.showHud()
                case let .loaded(allAccountDetails):
                    view.hideHud()
                    guard let accountDetails = allAccountDetails
                        .activeDetails()
                        .first(where: {
                            $0.currency == self.currencyCode
                                && !$0.isDeprecated
                                && $0.balanceId == self.balanceId
                        }) else {
                        showError(
                            message: L10n.Generic.Error.message
                        )
                        softFailure("[REC]: There should be an account details at this point")
                        return
                    }
                    analyticsViewTracker.track(
                        SalarySwitchOptionsAnalyticsView.AccountDetailsFetched(
                            accountDetails: accountDetails
                        )
                    )
                    self.accountDetails = accountDetails
                case let .recoverableError(error):
                    view.hideHud()
                    showError(
                        message: error.localizedDescription
                    )
                }
            }
    }

    func getAccountOwnershipProofDocument() {
        guard let accountDetailsId = accountDetails?.id else {
            softFailure("[REC]: There should be account details id at this point")
            showError(
                message: L10n.Generic.Error.message
            )
            return
        }
        accountOwnershipProofCancellable?.cancel()
        view?.showHud()
        accountOwnershipProofCancellable = accountOwnershipProofUseCase.accountOwnershipProof(
            profileId: profileId,
            accountDetailsId: accountDetailsId,
            currencyCode: currencyCode,
            addStamp: false
        )
        .receive(on: scheduler)
        .sink(receiveCompletion: { [weak self] completion in
            guard let self else { return }
            view?.hideHud()
            if case let .failure(error) = completion {
                showError(
                    message: error.localizedDescription
                )
            }
        }, receiveValue: { [weak self] url in
            guard let self else { return }
            analyticsViewTracker.track(
                SalarySwitchOptionsAnalyticsView.AccountOwnershipProofDocumentFetched(
                    url: url
                )
            )
            router.displayOwnershipProofDocument(
                url: url,
                delegate: view?.documentInteractionControllerDelegate
            )
        })
    }

    func showError(message: String) {
        analyticsViewTracker.track(
            SalarySwitchOptionsAnalyticsView.ErrorShown(
                message: message
            )
        )
        view?.showErrorAlert(
            title: L10n.Generic.Error.title,
            message: message
        )
    }
}
