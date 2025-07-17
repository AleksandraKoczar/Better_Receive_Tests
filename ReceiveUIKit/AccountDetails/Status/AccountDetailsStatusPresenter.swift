import Combine
import CombineSchedulers
import Foundation
import ReceiveKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsStatusPresenter {
    func configure(view: AccountDetailsStatusView)
    func refresh()
    func infoSelected(info: AccountDetailsStatus.Section.Summary.Info)
    func dismissSelected()
    func buttonSelected(action: AccountDetailsStatus.Button.Action)
}

final class AccountDetailsStatusPresenterImpl {
    private let profileId: ProfileId
    private let currencyCode: CurrencyCode
    private let router: AccountDetailsStatusRouter
    private let interactor: AccountDetailsStatusInteractor
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private weak var view: AccountDetailsStatusView?
    private weak var routingDelegate: AccountDetailsActionsListDelegate?

    private var cancellable: AnyCancellable?

    init(
        profileId: ProfileId,
        currencyCode: CurrencyCode,
        routingDelegate: AccountDetailsActionsListDelegate,
        router: AccountDetailsStatusRouter,
        interactor: AccountDetailsStatusInteractor,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profileId = profileId
        self.currencyCode = currencyCode
        self.routingDelegate = routingDelegate
        self.router = router
        self.interactor = interactor
        self.scheduler = scheduler
    }
}

extension AccountDetailsStatusPresenterImpl: AccountDetailsStatusPresenter {
    func configure(view: AccountDetailsStatusView) {
        self.view = view
        refresh()
    }

    func refresh() {
        view?.configure(with: .loading)
        cancellable = interactor.status(
            profileId: profileId,
            currencyCode: currencyCode
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(status):
                view?.configure(
                    with: .loaded(.init(
                        header: .init(
                            title: status.title,
                            description: status.description?.text ?? ""
                        ),
                        status: status
                    ))
                )
            case .failure:
                view?.configure(
                    with: .failedToLoad(
                        .networkError(primaryViewModel: .retry { [weak self] in
                            guard let self else {
                                return
                            }
                            refresh()
                        }
                        )
                    )
                )
            }
        }
    }

    func infoSelected(info: AccountDetailsStatus.Section.Summary.Info) {
        router.route(action: .showInfo(
            .init(title: info.title, content: info.content)
        ))
    }

    func dismissSelected() {
        routingDelegate?.dismiss()
    }

    func buttonSelected(action: AccountDetailsStatus.Button.Action) {
        switch action {
        case .proceed:
            routingDelegate?.nextStep()
        }
    }
}
