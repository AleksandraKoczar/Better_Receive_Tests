import BalanceKit
import Combine
import CombineSchedulers
import TWFoundation
import TWUI
import UserKit

final class LoadAccountDetailsEligibilityPresenter {
    private let profile: Profile
    private let router: LoadAccountDetailsEligibilityRouter
    private let interactor: LoadAccountDetailsEligibilityInteractor
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var cancellable: AnyCancellable?

    init(
        profile: Profile,
        router: LoadAccountDetailsEligibilityRouter,
        interactor: LoadAccountDetailsEligibilityInteractor,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profile = profile
        self.router = router
        self.interactor = interactor
        self.scheduler = scheduler
    }
}

extension LoadAccountDetailsEligibilityPresenter: DataLoadingViewPresenter {
    func configure(view: DataLoadingView) {
        view.configure(with: .loading)
        cancellable = interactor.eligibility(for: profile)
            .prefix(1)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { result in
                    if case .failure = result {
                        view.configure(with: .error)
                    }
                },
                receiveValue: { [router, profile] eligibility in
                    view.configure(with: .loaded)
                    switch eligibility {
                    case let .eligible(requirements: requirements):
                        router.route(action: .loaded(.eligible(.init(
                            profile: profile,
                            requirements: requirements
                        ))))
                    case .ineligible:
                        router.route(action: .loaded(.ineligible(profile)))
                    }
                }
            )
    }

    func dismissSelected() {
        router.route(action: .dismissed)
    }
}
