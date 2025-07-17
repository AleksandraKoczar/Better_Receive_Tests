import AnalyticsKit
import ApiKit
import DynamicFlow
import DynamicFlowKit
import Foundation
import HttpClientKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import WiseCore

public enum ReceiveMethodsDFFlowResult {
    case registrationCompleted
    case registrationFailed
    case dismissed
    case notApplicable
}

final class ReceiveMethodsDFFlow: Flow {
    var flowHandler: FlowHandler<ReceiveMethodsDFFlowResult> = .empty

    private let mode: ReceiveMethodsDFFlowMode
    private let accountDetailsId: AccountDetailsId
    private let profileId: ProfileId
    private let hostViewController: UIViewController
    private let accountDetailsUseCase: AccountDetailsV3UseCase
    private let dynamicFlowFactory: TWDynamicFlowFactory
    private let flowPresenter: FlowPresenter
    private let analyticsTracker: AnalyticsTracker

    private var dynamicFlow: (any Flow<Result<SuccessResult, FlowFailure>>)?

    init(
        mode: ReceiveMethodsDFFlowMode,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        hostViewController: UIViewController,
        accountDetailsUseCase: AccountDetailsV3UseCase = AccountDetailsV3UseCaseFactory.sharedUseCase,
        dynamicFlowFactory: TWDynamicFlowFactory = TWDynamicFlowFactory(),
        flowPresenter: FlowPresenter = .current,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self]
    ) {
        self.mode = mode
        self.accountDetailsId = accountDetailsId
        self.profileId = profileId
        self.hostViewController = hostViewController
        self.accountDetailsUseCase = accountDetailsUseCase
        self.dynamicFlowFactory = dynamicFlowFactory
        self.flowPresenter = flowPresenter
        self.analyticsTracker = analyticsTracker
    }

    func start() {
        let resource = Self.makeResource(
            mode: mode,
            profileId: profileId,
            accountDetailsId: accountDetailsId
        )

        let analyticsFlowTracker = AnalyticsFlowLegacyTrackerImpl(
            analyticsTracker: analyticsTracker,
            flowId: "Receive Aliases - \(mode.analyticsName)"
        )
        let flow: any Flow<Result<SuccessResult, FlowFailure>> = dynamicFlowFactory.makeFlow(
            resource: resource,
            presentationStyle: .modal(parent: hostViewController, isFullScreen: true),
            analyticsFlowTracker: analyticsFlowTracker,
            onFlowCancelled: { [weak self] in
                self?.accountDetailsUseCase.refresh()
            }
        )

        flow.onFinish { [weak self] result, dismisser in
            guard let self else { return }
            accountDetailsUseCase.refresh()
            handleResult(result, dismisser: dismisser)
        }
        dynamicFlow = flow
        flowPresenter.start(flow: flow)
        flowHandler.flowStarted()
    }

    func terminate() {
        guard let dynamicFlow else { return }
        flowPresenter.terminate(flow: dynamicFlow)
        flowHandler.flowFinished(result: .notApplicable, dismisser: nil)
    }
}

// MARK: - Helpers

private extension ReceiveMethodsDFFlow {
    static func makeResource(
        mode: ReceiveMethodsDFFlowMode,
        profileId: ProfileId,
        accountDetailsId: AccountDetailsId
    ) -> RestGwResource<DynamicFlowHTTPResponse> {
        let path =
            switch mode {
            case .manage:
                "/v1/profiles/{profileId}/receive-method/deposit-account/{accountDetailsId}/management/alias"
            case .register:
                "/v1/profiles/{profileId}/receive-method/deposit-account/{accountDetailsId}/alias/registration-flow"
            }

        let parameters: [UrlParameter] = [
            .makePathUrlParameter("profileId", value: String(profileId.value), sensitive: false),
            .makePathUrlParameter("accountDetailsId", value: String(accountDetailsId.value), sensitive: false),
        ]

        return RestGwResource<DynamicFlowHTTPResponse>(
            path: path,
            method: .get,
            parameters: parameters,
            parser: DynamicFlowHTTPResponse.parser
        )
    }
}

// MARK: - Helpers

private extension ReceiveMethodsDFFlow {
    func handleResult(
        _ result: Result<SuccessResult, FlowFailure>,
        dismisser: (any ViewControllerDismisser)?
    ) {
        accountDetailsUseCase.refresh()
        switch result {
        case let .success(_result):
            switch _result.type {
            case .other:
                flowHandler.flowFinished(result: .dismissed, dismisser: dismisser)
            case .successScreen:
                displaySuccessScreen(result: _result, dismisser: dismisser)
            }
        case .failure:
            flowHandler.flowFinished(result: .registrationFailed, dismisser: dismisser)
        }
    }

    func displaySuccessScreen(
        result: SuccessResult,
        dismisser: (any ViewControllerDismisser)?
    ) {
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen

        let viewController = TemplateLayoutViewController(
            configuration: .success(
                asset: .illustration(result.visual.illustration),
                title: result.title,
                message: .markup(result.body),
                footer: .simple(),
                preferredTheme: {
                    switch result.visual {
                    case .success: \.secondary
                    case .pending,
                         .other: \.primary
                    }
                }()
            )
        ).with {
            $0.primaryViewModel = .init(Action(
                title: result.buttons.first?.title ?? L10n.Dynamicforms.Button.Title.ok,
                handler: { [weak navigationController] in
                    navigationController?.dismiss(animated: UIView.shouldAnimate)
                }
            ))
        }
        navigationController.viewControllers = [viewController]
        flowHandler.flowFinished(result: .registrationCompleted, dismisser: dismisser)
        hostViewController.present(navigationController, animated: UIView.shouldAnimate)
    }
}

// MARK: - Analytics helpers

private extension ReceiveMethodsDFFlowMode {
    var analyticsName: String {
        switch self {
        case .manage: "MANAGE"
        case .register: "REGISTER"
        }
    }
}
