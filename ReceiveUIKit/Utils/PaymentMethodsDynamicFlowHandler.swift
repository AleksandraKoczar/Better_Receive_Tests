import AnalyticsKit
import ApiKit
import DynamicFlow
import DynamicFlowKit
import LoggingKit
import MacrosKit
import ReceiveKit
import TWFoundation
import UIKit

struct DynamicFormResponse: Decodable {
    let completed: Bool?
    let exited: DynamicFormResponse.Exited?

    struct Exited: Decodable {
        let reason: String?
    }
}

// sourcery: AutoMockable
protocol PaymentMethodsDynamicFlowHandler {
    func showDynamicForms(
        _ dynamicForms: [PaymentMethodDynamicForm],
        delegate: PaymentMethodsDelegate?
    )
}

class PaymentMethodsDynamicFlowHandlerImpl: PaymentMethodsDynamicFlowHandler {
    private let dynamicFlowFactory: TWDynamicFlowFactory
    private let navigationController: UINavigationController
    private let analyticsTracker: AnalyticsTracker

    private var dynamicFlow: (any Flow<Result<DynamicFormResponse?, FlowFailure>>)?

    init(
        dynamicFlowFactory: TWDynamicFlowFactory = TWDynamicFlowFactory(),
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        navigationController: UINavigationController
    ) {
        self.dynamicFlowFactory = dynamicFlowFactory
        self.analyticsTracker = analyticsTracker
        self.navigationController = navigationController
    }

    func showDynamicForms(
        _ dynamicForms: [PaymentMethodDynamicForm],
        delegate: PaymentMethodsDelegate?
    ) {
        guard let dynamicForm = dynamicForms.first else {
            return
        }

        let flow = makeDynamicFlow(flowId: dynamicForm.flowId, url: dynamicForm.url)
        flow.onFinish { [weak self] result, dismisser in
            dismisser?.dismiss(animated: false)
            guard let self else {
                return
            }
            dynamicFlow = nil
            switch result {
            case let .success(optionalResponse):
                showNextDynamicFormIfNeededMethodManagement(
                    optionalResponse: optionalResponse,
                    dynamicForms: dynamicForms,
                    delegate: delegate
                )
            case .failure:
                delegate?.trackDynamicFlowFailed()
                delegate?.refreshPaymentMethods()
            }
        }
        dynamicFlow = flow
        flow.start()
    }
}

private extension PaymentMethodsDynamicFlowHandlerImpl {
    func showNextDynamicFormIfNeededMethodManagement(
        optionalResponse: DynamicFormResponse?,
        dynamicForms: [PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm],
        delegate: PaymentMethodsDelegate?
    ) {
        let exitReasonFlowCompleted = "FLOW_COMPLETED"
        var remindedDynamicForms = dynamicForms
        remindedDynamicForms.removeFirst()
        guard let response = optionalResponse else {
            // Since mitigator will return empty response as success,
            // we should take care of that use case
            showDynamicForms(remindedDynamicForms, delegate: delegate)
            return
        }
        if response.completed == true || response.exited?.reason == exitReasonFlowCompleted {
            showDynamicForms(remindedDynamicForms, delegate: delegate)
        } else {
            delegate?.refreshPaymentMethods()
        }
    }

    func makeDynamicFlow(
        flowId: String,
        url: String
    ) -> any Flow<Result<DynamicFormResponse?, FlowFailure>> {
        let resource = RestGwResource<DynamicFlowHTTPResponse>(
            path: url,
            method: .get,
            parser: DynamicFlowHTTPResponse.parser
        )
        let analyticsFlowTracker = AnalyticsFlowLegacyTrackerImpl(
            analyticsTracker: analyticsTracker,
            flowId: flowId
        )
        return dynamicFlowFactory.makeFlow(
            resource: resource,
            presentationStyle: .push(navigationController: navigationController),
            analyticsFlowTracker: analyticsFlowTracker,
            resultParser: OptionalDecodableParser<DynamicFormResponse>()
        )
    }
}
