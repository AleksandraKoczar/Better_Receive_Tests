import Combine
import CombineSchedulers
import Foundation
import ReceiveKit
import UserKit
import WiseCore

final class AccountDetailsV3SwitcherPresenterImpl {
    private weak var view: AccountDetailsV3ListView?
    private weak var actionHandler: ReceiveMethodActionHandler?
    private let receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCase
    private let profile: Profile
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var receiveMethodNavigationCancellable: AnyCancellable?

    init(
        profile: Profile,
        actionHandler: ReceiveMethodActionHandler,
        receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCase,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profile = profile
        self.actionHandler = actionHandler
        self.receiveMethodNavigationUseCase = receiveMethodNavigationUseCase
        self.scheduler = scheduler
    }
}

extension AccountDetailsV3SwitcherPresenterImpl: AccountDetailsV3ListPresenter {
    func refresh() {}

    func start(with view: AccountDetailsV3ListView) {
        self.view = view
        fetchReceiveMethods()
    }
}

private extension AccountDetailsV3SwitcherPresenterImpl {
    func fetchReceiveMethods() {
        view?.showHud()
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
            view?.hideHud()
            switch result {
            case let .success(receiveMethod):
                let model = AccountDetailsV3ListModelMapper.mapAccountDetailsList(
                    receiveMethodNavigation: receiveMethod,
                    delegate: self,
                    trackOnSearchTapped: {}
                )
                view?.configure(with: model)
            case .failure:
                view?.configureWithError(with: .networkError(primaryViewModel: .retry { [weak self] in
                    guard let self else {
                        return
                    }
                    fetchReceiveMethods()
                }))
            }
        }
    }
}

extension AccountDetailsV3SwitcherPresenterImpl: ReceiveMethodNavigationDelegate {
    func handleAction(action: ReceiveMethodNavigationAction) {
        actionHandler?.handleReceiveMethodAction(action: action)
    }
}
