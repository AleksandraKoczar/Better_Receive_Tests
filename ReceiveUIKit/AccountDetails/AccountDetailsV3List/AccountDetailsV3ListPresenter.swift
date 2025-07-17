import Combine
import CombineSchedulers
import Foundation
import Prism
import ReceiveKit
import UserKit
import WiseCore

protocol ReceiveMethodNavigationDelegate: AnyObject {
    func handleAction(action: ReceiveMethodNavigationAction)
}

// sourcery: AutoMockable
protocol AccountDetailsV3ListPresenter {
    func start(with view: AccountDetailsV3ListView)
    func refresh()
}

final class AccountDetailsV3ListPresenterImpl {
    private weak var view: AccountDetailsV3ListView?
    private let actionHandler: ReceiveMethodActionHandler
    private let receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCase
    private let profile: Profile
    private let analyticsTracker: ReceiveMethodsNavigationTracking

    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var receiveMethodNavigationCancellable: AnyCancellable?

    init(
        profile: Profile,
        actionHandler: ReceiveMethodActionHandler,
        receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCase,
        analyticsTracker: ReceiveMethodsNavigationTracking,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profile = profile
        self.actionHandler = actionHandler
        self.receiveMethodNavigationUseCase = receiveMethodNavigationUseCase
        self.analyticsTracker = analyticsTracker
        self.scheduler = scheduler
    }
}

extension AccountDetailsV3ListPresenterImpl: AccountDetailsV3ListPresenter {
    func start(with view: AccountDetailsV3ListView) {
        self.view = view
        fetchReceiveMethods(isRefreshing: false)
    }

    func refresh() {
        fetchReceiveMethods(isRefreshing: true)
    }
}

private extension AccountDetailsV3ListPresenterImpl {
    func fetchReceiveMethods(isRefreshing: Bool) {
        if !isRefreshing {
            view?.showHud()
        }
        receiveMethodNavigationCancellable = receiveMethodNavigationUseCase.getReceiveMethodNavigation(
            profileId: profile.id,
            context: .list,
            groupId: nil,
            balanceId: nil,
            types: nil,
            currency: nil
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else {
                return
            }
            if isRefreshing {
                view?.hideLoading()
            } else {
                view?.hideHud()
            }
            switch result {
            case let .success(receiveMethod):
                let model = AccountDetailsV3ListModelMapper.mapAccountDetailsList(
                    receiveMethodNavigation: receiveMethod,
                    delegate: self,
                    trackOnSearchTapped: { [weak self] in
                        guard let self else { return }
                        analyticsTracker.onSearchTapped(value: .List())
                    }
                )
                view?.configure(with: model)
                analyticsTracker.onLoaded(context: .List(), isSuccess: true)
            case .failure:
                view?.configureWithError(with: .networkError(primaryViewModel: .retry {
                    [weak self] in
                    guard let self else {
                        return
                    }
                    fetchReceiveMethods(isRefreshing: false)
                }))
                analyticsTracker.onLoaded(context: .List(), isSuccess: false)
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

extension AccountDetailsV3ListPresenterImpl: ReceiveMethodNavigationDelegate {
    func handleAction(action: ReceiveMethodNavigationAction) {
        actionHandler.handleReceiveMethodAction(action: action)
        trackActionSelected(action: action)
    }
}
