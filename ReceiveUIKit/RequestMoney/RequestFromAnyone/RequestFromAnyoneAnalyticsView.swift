import AnalyticsKit
import Foundation

struct RequestFromAnyoneAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Request Flow - Share Profile Link")
}

// MARK: - Actions

extension RequestFromAnyoneAnalyticsView {
    struct Started: AnalyticsViewAction {
        typealias View = RequestFromAnyoneAnalyticsView
        let name = "Started"
    }

    struct Copied: AnalyticsViewAction {
        typealias View = RequestFromAnyoneAnalyticsView
        let name = "Copied"
    }

    struct ShareClicked: AnalyticsViewAction {
        typealias View = RequestFromAnyoneAnalyticsView
        let name = "Share clicked"
    }

    struct Activate: AnalyticsViewAction {
        typealias View = RequestFromAnyoneAnalyticsView
        let name = "Activate"
    }

    struct CreateStepClick: AnalyticsViewAction {
        typealias View = RequestFromAnyoneAnalyticsView
        let name = "Create step click"
    }

    struct Finished: AnalyticsViewAction {
        typealias View = RequestFromAnyoneAnalyticsView
        let name = "Finished"
        let properties: [AnalyticsProperty]

        init(result: RequestFromAnyoneFinishResult) {
            let value =
                switch result {
                case .success:
                    "Success"
                case .dismissed:
                    "Dismissed"
                }
            properties = [AnyAnalyticsProperty("Result", value)]
        }
    }
}
