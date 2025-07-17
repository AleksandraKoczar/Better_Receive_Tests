import AnalyticsKit

private enum Constants {
    static let flowName = "Multiple Account Details"
}

final class MultipleAccountDetailsFlowStartedEvent: AnalyticsFlowLegacyEventItem {
    private var flowId: String?

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(
                name: "\(Constants.flowName) - Started",
                properties: AnalyticsFlowLegacyParameter.dictionary(
                    withFlowId: flowId
                )
            ),
        ]
    }

    func setFlowId(_ flowId: String) {
        self.flowId = flowId
    }
}

final class MultipleAccountDetailsFlowFinishedEvent: AnalyticsFlowLegacyEventItem {
    enum Result {
        case completed
        case interrupted

        fileprivate var value: String {
            switch self {
            case .completed:
                "completed"
            case .interrupted:
                "interrupted"
            }
        }
    }

    private let result: Result
    private var flowId: String?

    init(result: Result) {
        self.result = result
    }

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(
                name: "\(Constants.flowName) - Finished",
                properties: AnalyticsFlowLegacyParameter.dictionary(
                    withFlowId: flowId,
                    source: ["result": result.value]
                )
            ),
        ]
    }

    func setFlowId(_ flowId: String) {
        self.flowId = flowId
    }
}

final class MultipleAccountDetailsFlowLoadAccountDetailsStatusEvent: AnalyticsFlowLegacyEventItem {
    private var flowId: String?

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(
                name: "\(Constants.flowName) - Load Account Details Status",
                properties: AnalyticsFlowLegacyParameter.dictionary(
                    withFlowId: flowId
                )
            ),
        ]
    }

    func setFlowId(_ flowId: String) {
        self.flowId = flowId
    }
}

final class MultipleAccountDetailsFlowLoadEligibilityEvent: AnalyticsFlowLegacyEventItem {
    private var flowId: String?

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(
                name: "\(Constants.flowName) - Load Eligibility",
                properties: AnalyticsFlowLegacyParameter.dictionary(
                    withFlowId: flowId
                )
            ),
        ]
    }

    func setFlowId(_ flowId: String) {
        self.flowId = flowId
    }
}

final class MultipleAccountDetailsFlowIneligibleEvent: AnalyticsFlowLegacyEventItem {
    private var flowId: String?

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(
                name: "\(Constants.flowName) - Show Ineligibility",
                properties: AnalyticsFlowLegacyParameter.dictionary(
                    withFlowId: flowId
                )
            ),
        ]
    }

    func setFlowId(_ flowId: String) {
        self.flowId = flowId
    }
}

final class MultipleAccountDetailsFlowOrderEvent: AnalyticsFlowLegacyEventItem {
    private var flowId: String?

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(
                name: "\(Constants.flowName) - Show Order",
                properties: AnalyticsFlowLegacyParameter.dictionary(
                    withFlowId: flowId
                )
            ),
        ]
    }

    func setFlowId(_ flowId: String) {
        self.flowId = flowId
    }
}

final class MultipleAccountDetailsFlowSingleDetailsEvent: AnalyticsFlowLegacyEventItem {
    private var flowId: String?

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(
                name: "\(Constants.flowName) - Show Single Details",
                properties: AnalyticsFlowLegacyParameter.dictionary(
                    withFlowId: flowId
                )
            ),
        ]
    }

    func setFlowId(_ flowId: String) {
        self.flowId = flowId
    }
}

final class MultipleAccountDetailsFlowCreateProfileEvent: AnalyticsFlowLegacyEventItem {
    private var flowId: String?

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [
            MixpanelEvent(
                name: "\(Constants.flowName) - Create Profile",
                properties: AnalyticsFlowLegacyParameter.dictionary(
                    withFlowId: flowId
                )
            ),
        ]
    }

    func setFlowId(_ flowId: String) {
        self.flowId = flowId
    }
}
