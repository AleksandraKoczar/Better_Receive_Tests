import ReceiveKit
import TWFoundation
import TWUI
import WiseCore

// sourcery: AutoMockable
public protocol RequestMoneyCardOnboardingFlowFactory {
    func makeModalFlow(
        profileId: ProfileId,
        rootViewController: UIViewController
    ) -> any Flow<RequestMoneyCardOnboardingFlowResult>
    func makeFlow(
        dynamicForms: [PaymentMethodAvailability.DynamicForm],
        navigationController: UINavigationController
    ) -> any Flow<RequestMoneyCardOnboardingFlowResult>
}

public struct RequestMoneyCardOnboardingFlowFactoryImpl: RequestMoneyCardOnboardingFlowFactory {
    public init() {}

    public func makeModalFlow(
        profileId: ProfileId,
        rootViewController: UIViewController
    ) -> any Flow<RequestMoneyCardOnboardingFlowResult> {
        let configuration = RequestMoneyCardOnboardingFlow.Configuration(
            source: .profileId(profileId),
            shouldShowAvailablePromptWhenFinished: true
        )
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        let flow = RequestMoneyCardOnboardingFlow(
            configuration: configuration,
            navigationController: navigationController
        )
        return ModalPresentationFlow(
            flow: flow,
            rootViewController: rootViewController,
            flowController: navigationController
        )
    }

    public func makeFlow(
        dynamicForms: [PaymentMethodAvailability.DynamicForm],
        navigationController: UINavigationController
    ) -> any Flow<RequestMoneyCardOnboardingFlowResult> {
        let configuration = RequestMoneyCardOnboardingFlow.Configuration(
            source: .dynamicForms(dynamicForms),
            shouldShowAvailablePromptWhenFinished: false
        )
        return RequestMoneyCardOnboardingFlow(
            configuration: configuration,
            navigationController: navigationController
        )
    }
}
