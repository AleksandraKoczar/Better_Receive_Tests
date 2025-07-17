import AnalyticsKit
import BalanceKit
import Combine
import CombineSchedulers
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

typealias SalarySwitchUpsellAnalyticsView = SalarySwitchFlowAnalytics.UpsellView

// sourcery: AutoMockable
protocol SalarySwitchUpsellPresenter: AnyObject {
    func start()
}

final class SalarySwitchUpsellPresenterImpl {
    private let useCase: SalarySwitchUpsellUseCase
    private let router: SalarySwitchUpsellRouter
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private let profile: Profile
    private let currency: CurrencyCode
    private let accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus

    private var fetchContentCancellable: AnyCancellable?
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<SalarySwitchUpsellAnalyticsView>

    init(
        profile: Profile,
        currency: CurrencyCode,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        useCase: SalarySwitchUpsellUseCase,
        router: SalarySwitchUpsellRouter,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profile = profile
        self.currency = currency
        self.accountDetailsRequirementStatus = accountDetailsRequirementStatus
        self.useCase = useCase
        self.router = router
        self.scheduler = scheduler
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: SalarySwitchUpsellAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }
}

// MARK: - SalarySwitchUpsellPresenter

extension SalarySwitchUpsellPresenterImpl: SalarySwitchUpsellPresenter {
    func start() {
        fetchUpsellContent()
    }
}

// MARK: - Data Fetching

private extension SalarySwitchUpsellPresenterImpl {
    func fetchUpsellContent() {
        fetchContentCancellable?.cancel()
        fetchContentCancellable = useCase.getUpsellContent(
            profileId: profile.id,
            currency: currency
        ).handleEvents(receiveSubscription: { [weak self] _ in
            self?.router.showHud()
        }).receive(on: scheduler)
            .prefix(1)
            .sink(
                receiveCompletion: { [weak self] result in
                    guard let self else { return }
                    router.hideHud()
                    if case let .failure(error) = result {
                        router.showErrorAlert(
                            title: L10n.Generic.Error.title,
                            message: error.localizedDescription
                        )
                        analyticsViewTracker.track(
                            SalarySwitchUpsellAnalyticsView.ErrorShown(
                                message: error.localizedDescription
                            )
                        )
                    }
                },
                receiveValue: { [weak self] content in
                    guard let self else { return }
                    showUpsell(content: content)
                    analyticsViewTracker.trackView(.started)
                }
            )
    }
}

// MARK: - View Management

private extension SalarySwitchUpsellPresenterImpl {
    func showUpsell(content: SwitchSalaryUpsellContent) {
        let viewModel = makeUpsellViewModel(content: content)
        router.showUpsell(viewModel: viewModel)
    }
}

// MARK: - Actions

private extension SalarySwitchUpsellPresenterImpl {
    func continueFromUpsell() {
        analyticsViewTracker.track(
            SalarySwitchUpsellAnalyticsView.ContinuePressed(
                currencyCode: currency,
                requirementStatus: accountDetailsRequirementStatus
            )
        )
        switch accountDetailsRequirementStatus {
        case let .hasActiveAccountDetails(balanceId):
            router.showOptionSelection(
                balanceId: balanceId,
                currency: currency,
                profileId: profile.id
            )
        case .needsAccountDetailsActivation:
            router.showOrderAccountDetailsFlow(
                profile: profile,
                currency: currency
            )
        }
    }
}

// MARK: - Model creation & mappings

private extension SalarySwitchUpsellPresenterImpl {
    func makeUpsellViewModel(content: SwitchSalaryUpsellContent) -> UpsellViewModel {
        let items = content.summaries.map {
            self.makeUpsellSummaryViewModel(summary: $0)
        }
        return UpsellViewModel(
            headerModel: LargeTitleViewModel(
                title: L10n.Account.Details.Receive.Salary.Upsell.title
            ),
            imageView: UIImageView(image: Neptune.Illustrations.wallet.image)
                .with { $0.contentMode = .scaleAspectFit },
            items: items,
            footerModel: .init(primaryAction: .init(
                title: L10n.Account.Details.Receive.Salary.Upsell.button,
                handler: { [weak self] in
                    self?.continueFromUpsell()
                }
            ))
        )
    }

    func makeUpsellSummaryViewModel(summary: SwitchSalaryUpsellSummary) -> SummaryViewModel {
        let infoAction: (() -> Void)? = {
            guard let action = summary.action,
                  let path = action.urlPath else {
                return nil
            }
            return { [weak self] in
                self?.router.showFAQ(path: path)
            }
        }()
        return SummaryViewModel(
            title: summary.title,
            description: summary.description,
            icon: summary.iconResource.image,
            info: infoAction
        )
    }
}

// MARK: - SwitchSalaryUpsellSummary + Icon Resource

private extension SwitchSalaryUpsellSummary {
    var iconResource: Neptune.Icon {
        switch icon {
        case "direct-debits":
            Icons.directDebits
        case "lock":
            Icons.padlock
        case "graph":
            Icons.graph
        case "travel":
            Icons.suitcase
        case "salary":
            Icons.payIn
        case "card":
            Icons.card
        case "convert":
            Icons.convert
        default:
            Icons.fastFlag
        }
    }
}
