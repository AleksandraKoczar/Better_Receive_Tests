import BalanceKit
import Combine
import CombineSchedulers
import TWFoundation
import TWUI
import UserKit

final class LoadAccountDetailsStatusPresenter {
    private let profile: Profile
    private let router: LoadAccountDetailsStatusRouter
    private let interactor: LoadAccountDetailsStatusInteractor
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var cancellable: AnyCancellable?

    init(
        profile: Profile,
        router: LoadAccountDetailsStatusRouter,
        interactor: LoadAccountDetailsStatusInteractor,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profile = profile
        self.router = router
        self.interactor = interactor
        self.scheduler = scheduler
    }
}

extension LoadAccountDetailsStatusPresenter: DataLoadingViewPresenter {
    func configure(view: DataLoadingView) {
        view.configure(with: .loading)
        cancellable = interactor.accountDetails
            .prefix(1)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { result in
                    if case .failure = result {
                        view.configure(with: .error)
                    }
                },
                receiveValue: { [router, profile] details in
                    view.configure(with: .loaded)
                    router.route(
                        action: .loaded(.init(
                            profile: profile,
                            status: Self.status(for: details)
                        ))
                    )
                }
            )
    }

    func dismissSelected() {
        router.route(action: .dismissed)
    }
}

private extension LoadAccountDetailsStatusPresenter {
    static func status(
        for details: [AccountDetails]
    ) -> LoadAccountDetailsStatusInfo.Status {
        details.contains(
            where: { $0.isActive }
        ) ? .active : .inactive
    }
}
