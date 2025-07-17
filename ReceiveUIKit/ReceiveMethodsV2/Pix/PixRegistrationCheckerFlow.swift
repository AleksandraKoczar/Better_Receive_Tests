import BalanceKit
import Combine
import CombineSchedulers
import Foundation
import ReceiveKit
import TWFoundation
import UIKit
import WiseCore

final class PixRegistrationCheckerFlow: Flow {
    var flowHandler: TWFoundation.FlowHandler<PixRegistrationCheckerFlowResult> = .empty

    private let profileId: ProfileId
    private let hostViewController: UIViewController
    private let accountDetailsUseCase: AccountDetailsUseCase
    private let receiveMethodsAliasUseCase: ReceiveMethodsAliasUseCase
    private let receiveMethodsDFFlowFactory: ReceiveMethodsDFFlowFactory
    private let flowPresenter: FlowPresenter
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var receiveMethodsDFFlow: (any Flow<ReceiveMethodsDFFlowResult>)?
    private var pixSuccessCancellable: AnyCancellable?

    init(
        profileId: ProfileId,
        hostViewController: UIViewController,
        accountDetailsUseCase: AccountDetailsUseCase = AccountDetailsUseCaseFactory.makeUseCase(),
        receiveMethodsAliasUseCase: ReceiveMethodsAliasUseCase = ReceiveMethodsAliasUseCaseFactoryImpl().make(),
        receiveMethodsDFFlowFactory: ReceiveMethodsDFFlowFactory = ReceiveMethodsDFFlowFactoryImpl(),
        flowPresenter: FlowPresenter = .current,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profileId = profileId
        self.hostViewController = hostViewController
        self.accountDetailsUseCase = accountDetailsUseCase
        self.receiveMethodsAliasUseCase = receiveMethodsAliasUseCase
        self.receiveMethodsDFFlowFactory = receiveMethodsDFFlowFactory
        self.flowPresenter = flowPresenter
        self.scheduler = scheduler
    }

    func start() {
        checkPix(
            profileId: profileId,
            hostViewController: hostViewController
        )
    }

    func terminate() {
        pixSuccessCancellable = nil
        receiveMethodsDFFlow?.terminate()
    }
}

extension PixRegistrationCheckerFlow {
    func checkPix(
        profileId: ProfileId,
        hostViewController: UIViewController
    ) {
        enum PixCheckResult {
            case noBRLDetails
            case needsKeyRegistration(ActiveAccountDetails)
            case alreadyHasAliases
            case otherError
        }
        showHud()
        accountDetailsUseCase.clearData()
        accountDetailsUseCase.refreshAccountDetails()
        pixSuccessCancellable = accountDetailsUseCase
            .accountDetails
            .tryMap {
                switch $0 {
                case let .loaded(details):
                    details.activeDetails()
                case .loading,
                     .none:
                    nil
                case let .recoverableError(error):
                    throw error
                }
            }
            .compactMap { $0 }
            .replaceError(with: [])
            .flatMap { [unowned self] (details: [ActiveAccountDetails]) -> AnyPublisher<PixCheckResult, Never> in
                guard let detail = details.first(where: {
                    PixStatusChecker.isPixAvailableAccountDetails(accountDetails: $0)
                }) else {
                    return .just(PixCheckResult.noBRLDetails)
                }
                return receiveMethodsAliasUseCase.aliases(
                    accountDetailsId: detail.id,
                    profileId: profileId
                ).map { aliases in
                    PixStatusChecker.hasPixAliasRegistered(
                        aliases: aliases
                    )
                }
                // Don't show pix registration on error
                .replaceError(with: true)
                .flatMap { hasAliases -> AnyPublisher<PixCheckResult, Never> in
                    if hasAliases {
                        return .just(PixCheckResult.alreadyHasAliases)
                    } else {
                        return .just(PixCheckResult.needsKeyRegistration(detail))
                    }
                }
                .eraseToAnyPublisher()
            }
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else { return }
                hideHud()
                switch result {
                case let .needsKeyRegistration(detail):
                    showPixRegistrationFlow(
                        activeAccountDetails: detail,
                        profileId: profileId,
                        hostViewController: hostViewController
                    )
                case .noBRLDetails,
                     .alreadyHasAliases,
                     .otherError:
                    flowHandler.flowFinished(
                        result: .finished(pixRegistered: false),
                        dismisser: nil
                    )
                }
            }
    }
}

private extension PixRegistrationCheckerFlow {
    func showPixRegistrationFlow(
        activeAccountDetails: ActiveAccountDetails,
        profileId: ProfileId,
        hostViewController: UIViewController
    ) {
        let flow = receiveMethodsDFFlowFactory.make(
            mode: .register,
            accountDetailsId: activeAccountDetails.id,
            profileId: profileId,
            hostViewController: hostViewController
        ).onFinish { [weak self] result, dismisser in
            guard let self else { return }
            dismisser?.dismiss()
            let isPixRegistered =
                switch result {
                case .registrationCompleted:
                    true
                case .registrationFailed,
                     .dismissed,
                     .notApplicable:
                    false
                }
            receiveMethodsDFFlow = nil
            flowHandler.flowFinished(
                result: .finished(pixRegistered: isPixRegistered),
                dismisser: dismisser
            )
        }
        receiveMethodsDFFlow = flow
        flowPresenter.start(flow: flow)
    }

    func showHud() {
        topViewController?.showHud()
    }

    func hideHud() {
        topViewController?.hideHud()
    }

    var topViewController: UIViewController? {
        if let _navController = hostViewController as? UINavigationController {
            _navController.topViewController
        } else {
            hostViewController
        }
    }
}
