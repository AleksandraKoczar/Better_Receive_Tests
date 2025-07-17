import Combine
import CombineSchedulers
import Foundation
import Prism
import ReceiveKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsV3SplitterScreenPresenter: AnyObject {
    func start(with view: AccountDetailsV3SplitterScreenListView)
}

final class AccountDetailsV3SplitterScreenPresenterImpl {
    private weak var view: AccountDetailsV3SplitterScreenListView?
    private let router: ReceiveMethodActionHandler
    private let currency: CurrencyCode
    private let receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCase
    private let profile: Profile
    private let analyticsTracker: ReceiveMethodsNavigationTracking
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var receiveMethodNavigationCancellable: AnyCancellable?

    init(
        currency: CurrencyCode,
        profile: Profile,
        router: ReceiveMethodActionHandler,
        receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCase,
        analyticsTracker: ReceiveMethodsNavigationTracking,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.currency = currency
        self.profile = profile
        self.router = router
        self.receiveMethodNavigationUseCase = receiveMethodNavigationUseCase
        self.analyticsTracker = analyticsTracker
        self.scheduler = scheduler
    }
}

extension AccountDetailsV3SplitterScreenPresenterImpl: AccountDetailsV3SplitterScreenPresenter {
    func start(with view: AccountDetailsV3SplitterScreenListView) {
        self.view = view
        fetchReceiveMethods()
    }
}

private extension AccountDetailsV3SplitterScreenPresenterImpl {
    func fetchReceiveMethods() {
        view?.showHud()
        receiveMethodNavigationCancellable = receiveMethodNavigationUseCase.getReceiveMethodNavigation(
            profileId: profile.id,
            context: .splitter,
            groupId: nil,
            balanceId: nil,
            types: nil,
            currency: currency
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else {
                return
            }
            view?.hideHud()
            switch result {
            case let .success(receiveMethod):
                let model = AccountDetailsV3SplitterScreenModelMapper.mapSplitterScreen(
                    currency: currency,
                    receiveMethodNavigation: receiveMethod,
                    delegate: self
                )
                view?.configure(with: model)
                analyticsTracker.onLoaded(context: .Splitter(), isSuccess: true)
            case .failure:
                view?.configureWithError(with: .networkError(primaryViewModel: .retry { [weak self] in
                    guard let self else {
                        return
                    }
                    fetchReceiveMethods()
                }))
                analyticsTracker.onLoaded(context: .Splitter(), isSuccess: false)
            }
        }
    }

    func trackActionSelected(action: ReceiveMethodNavigationAction) {
        switch action {
        case let .order(currency, _, _):
            analyticsTracker.onSelected(context: .List(), value: currency?.value ?? "nil", actionType: .Order())
        case let .query(_, currency, _, _, _):
            analyticsTracker.onSelected(context: .List(), value: currency?.value ?? "nil", actionType: .Query())
        case .view:
            analyticsTracker.onSelected(context: .List(), value: "View Action - No Currency", actionType: .View())
        }
    }
}

extension AccountDetailsV3SplitterScreenPresenterImpl: ReceiveMethodNavigationDelegate {
    func handleAction(action: ReceiveMethodNavigationAction) {
        router.handleReceiveMethodAction(action: action)
        trackActionSelected(action: action)
    }
}
