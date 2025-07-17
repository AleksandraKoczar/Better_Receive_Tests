import Combine
import CombineSchedulers
import Foundation
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import WiseCore

// sourcery: AutoMockable
protocol ReceiveRestrictionPresenter: AnyObject {
    func start(view: ReceiveRestrictionView)
    func handleFooterAction(type: ReceiveRestriction.Footer.`Type`)
    func handleURI(string: String)
    func dismiss()
}

final class ReceiveRestrictionPresenterImpl {
    private let context: ReceiveRestrictionContext
    private let profileId: ProfileId
    private let useCase: ReceiveRestrictionUseCase
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private weak var routingDelegate: ReceiveRestrictionRoutingDelegate?
    private weak var view: ReceiveRestrictionView?

    private var cancellable: AnyCancellable?

    init(
        context: ReceiveRestrictionContext,
        profileId: ProfileId,
        useCase: ReceiveRestrictionUseCase,
        routingDelegate: ReceiveRestrictionRoutingDelegate,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.context = context
        self.profileId = profileId
        self.useCase = useCase
        self.routingDelegate = routingDelegate
        self.scheduler = scheduler
    }
}

// MARK: - ReceiveRestrictionPresenter

extension ReceiveRestrictionPresenterImpl: ReceiveRestrictionPresenter {
    func start(view: ReceiveRestrictionView) {
        self.view = view

        view.showHud()
        cancellable = useCase.receiveRestriction(
            profileId: profileId,
            context: context
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else { return }
            self.view?.hideHud()
            switch result {
            case let .success(restriction):
                let viewModel = ReceiveRestrictionViewModel(
                    restriction: restriction
                )
                self.view?.configure(viewModel: viewModel)
            case let .failure(error):
                self.view?.showErrorState(
                    title: L10n.Generic.Error.title,
                    message: error.localizedDescription
                )
            }
        }
    }

    func handleFooterAction(type: ReceiveRestriction.Footer.`Type`) {
        switch type {
        case .dismiss:
            routingDelegate?.dismiss()
        case let .link(uri):
            guard let uri else { return }
            handleURI(uri)
        }
    }

    func handleURI(string: String) {
        guard let uri = URI(string: string) else {
            softFailure("[REC]: URN building failed from \(string)")
            return
        }
        handleURI(uri)
    }

    func dismiss() {
        routingDelegate?.dismiss()
    }
}

// MARK: - Helpers

private extension ReceiveRestrictionPresenterImpl {
    func handleURI(_ uri: URI) {
        routingDelegate?.handleURI(uri)
    }
}
