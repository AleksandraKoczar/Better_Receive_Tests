import AnalyticsKit
import ApiKit
import Combine
import CombineSchedulers
import DynamicFlow
import DynamicFlowKit
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import WiseCore

final class RequestMoneyCardOnboardingFlow: Flow {
    var flowHandler: FlowHandler<RequestMoneyCardOnboardingFlowResult> = .empty

    private let configuration: RequestMoneyCardOnboardingFlow.Configuration
    private let navigationController: UINavigationController
    private let analyticsTracker: AnalyticsTracker
    private let flowTracker: RequestMoneyCardOnboardingFlowAnalyticsTracker
    private let paymentMethodsUseCase: PaymentMethodsUseCase
    private let dynamicFlowFactory: TWDynamicFlowFactory
    private let promptViewControllerFactory: RequestMoneyCardOnboardingPromptViewControllerFactory
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var pusherPresenter: NavigationViewControllerPresenter
    private var dismisser: ViewControllerDismisser?
    private var checkCardAvailabilityCancellable: AnyCancellable?
    private var dynamicFlow: (any Flow<Result<DynamicFormResponse?, FlowFailure>>)?

    init(
        configuration: RequestMoneyCardOnboardingFlow.Configuration,
        navigationController: UINavigationController,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        paymentMethodsUseCase: PaymentMethodsUseCase = PaymentMethodsUseCaseFactory.make(),
        viewControllerPresenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl(),
        dynamicFlowFactory: TWDynamicFlowFactory = TWDynamicFlowFactory(),
        promptViewControllerFactory: RequestMoneyCardOnboardingPromptViewControllerFactory = RequestMoneyCardOnboardingPromptViewControllerFactoryImpl(),
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.configuration = configuration
        self.navigationController = navigationController
        self.analyticsTracker = analyticsTracker
        flowTracker = RequestMoneyCardOnboardingFlowAnalyticsTracker(
            contextIdentity: RequestMoneyCardOnboardingFlowAnalytics.identity,
            analyticsTracker: analyticsTracker
        )
        self.paymentMethodsUseCase = paymentMethodsUseCase
        self.dynamicFlowFactory = dynamicFlowFactory
        self.promptViewControllerFactory = promptViewControllerFactory
        self.scheduler = scheduler
        pusherPresenter = viewControllerPresenterFactory.makePushPresenter(navigationController: navigationController)
    }

    func start() {
        flowStarted()
        switch configuration.source {
        case let .profileId(profileId):
            checkCardAvailability(profileId: profileId)
        case let .dynamicForms(dynamicForms):
            showDynamicForms(dynamicForms)
        }
    }

    func terminate() {
        flowFinished(result: .dismissed, onboardingResult: false)
    }
}

// MARK: - Flow helpers

private extension RequestMoneyCardOnboardingFlow {
    func flowStarted() {
        flowTracker.trackFlow(.started)
        flowHandler.flowStarted()
    }

    func flowFinished(
        result: RequestMoneyCardOnboardingFlowResult,
        onboardingResult: Bool
    ) {
        let property = RequestMoneyCardOnboardingFlowAnalytics.OnboardingResultProperty(value: onboardingResult)
        flowTracker.trackFlow(.finished, properties: [property])
        flowHandler.flowFinished(result: result, dismisser: dismisser)
    }
}

// MARK: - Check card availability

private extension RequestMoneyCardOnboardingFlow {
    func processCardAvailiability(_ availability: RequestMoneyCardAvailability) {
        let state = RequestMoneyCardOnboardingFlowAnalytics.StateProperty(availability: availability)
        let action = RequestMoneyCardOnboardingFlowAnalytics.LoadedAction(state: state)
        flowTracker.trackFlow(action)
        switch availability {
        case let .eligible(dynamicForms):
            showDynamicForms(dynamicForms)
        case .ineligible:
            showIneligiblePrompt()
        case .available:
            showAvailablePrompt()
        }
    }

    func checkCardAvailability(profileId: ProfileId) {
        navigationController.showHud()
        checkCardAvailabilityCancellable = paymentMethodsUseCase.cardAvailability(profileId: profileId)
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                navigationController.hideHud()
                switch result {
                case let .success(availability):
                    processCardAvailiability(availability)
                case .failure:
                    navigationController.showDismissableAlert(
                        title: L10n.Generic.Error.title,
                        message: L10n.Generic.Error.message,
                        dismissAction: { [weak self] in
                            self?.flowFinished(result: .dismissed, onboardingResult: false)
                        }
                    )
                }
            }
    }
}

// MARK: - Prompt helpers

private extension RequestMoneyCardOnboardingFlow {
    func showIneligiblePrompt() {
        let viewController = promptViewControllerFactory.makeCardIneligible(
            primaryButtonAction: { [weak self] _ in
                guard let self else {
                    return
                }
                flowFinished(result: .dismissed, onboardingResult: false)
            }
        )
        dismisser = pusherPresenter.present(viewController: viewController)
    }

    func showAvailablePrompt() {
        let viewController = promptViewControllerFactory.makeCardAvailable(
            primaryButtonAction: { [weak self] _ in
                guard let self else {
                    return
                }
                flowFinished(result: .completed, onboardingResult: true)
            },
            secondaryButtonAction: { [weak self] _ in
                guard let self else {
                    return
                }
                flowFinished(result: .dismissed, onboardingResult: true)
            }
        )
        dismisser = pusherPresenter.present(viewController: viewController)
    }
}

// MARK: - Dynamic flow helpers

private extension RequestMoneyCardOnboardingFlow {
    enum Constants {
        static let exitReasonFlowCompleted = "FLOW_COMPLETED"
    }

    func makeDynamicFlow(
        dynamicForm: PaymentMethodAvailability.DynamicForm
    ) -> any Flow<Result<DynamicFormResponse?, FlowFailure>> {
        let resource = RestGwResource<DynamicFlowHTTPResponse>(
            path: dynamicForm.url,
            method: .get,
            parser: DynamicFlowHTTPResponse.parser
        )
        let analyticsFlowTracker = AnalyticsFlowLegacyTrackerImpl(
            analyticsTracker: analyticsTracker,
            flowId: dynamicForm.flowId
        )
        return dynamicFlowFactory.makeFlow(
            resource: resource,
            presentationStyle: .push(navigationController: navigationController),
            analyticsFlowTracker: analyticsFlowTracker,
            resultParser: OptionalDecodableParser<DynamicFormResponse>()
        )
    }

    func showNextDynamicFormIfNeeded(
        optionalResponse: DynamicFormResponse?,
        dynamicForms: [PaymentMethodAvailability.DynamicForm]
    ) {
        var remindedDynamicForms = dynamicForms
        remindedDynamicForms.removeFirst()
        guard let response = optionalResponse else {
            // Since mitigator will return empty response as success,
            // we should take care of that use case
            showDynamicForms(remindedDynamicForms)
            return
        }
        if response.completed == true || response.exited?.reason == Constants.exitReasonFlowCompleted {
            showDynamicForms(remindedDynamicForms)
        } else {
            flowFinished(result: .dismissed, onboardingResult: false)
        }
    }

    func showDynamicForms(_ dynamicForms: [PaymentMethodAvailability.DynamicForm]) {
        guard let dynamicForm = dynamicForms.first else {
            completeDynamicForms()
            return
        }
        let flow = makeDynamicFlow(dynamicForm: dynamicForm)
        flow.onFinish { [weak self] result, dismisser in
            dismisser?.dismiss(animated: false)
            guard let self else {
                return
            }
            dynamicFlow = nil
            switch result {
            case let .success(optionalResponse):
                showNextDynamicFormIfNeeded(
                    optionalResponse: optionalResponse,
                    dynamicForms: dynamicForms
                )
            case .failure:
                showIneligiblePrompt()
            }
        }
        dynamicFlow = flow
        flow.start()
    }
}

// MARK: - Helpers

private extension RequestMoneyCardOnboardingFlow {
    func completeDynamicForms() {
        if configuration.shouldShowAvailablePromptWhenFinished {
            showAvailablePrompt()
        } else {
            flowFinished(result: .completed, onboardingResult: true)
        }
    }
}

// MARK: - Flow Configuration

extension RequestMoneyCardOnboardingFlow {
    struct Configuration {
        let source: RequestMoneyCardOnboardingFlow.Configuration.Source
        let shouldShowAvailablePromptWhenFinished: Bool
    }
}

extension RequestMoneyCardOnboardingFlow.Configuration {
    enum Source {
        case profileId(ProfileId)
        case dynamicForms([PaymentMethodAvailability.DynamicForm])
    }
}

// MARK: - Flow Response

extension RequestMoneyCardOnboardingFlow {
    struct DynamicFormResponse: Decodable {
        let completed: Bool?
        let exited: DynamicFormResponse.Exited?
    }
}

extension RequestMoneyCardOnboardingFlow.DynamicFormResponse {
    struct Exited: Decodable {
        let reason: String?
    }
}
