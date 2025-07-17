import AnalyticsKit
import Foundation

enum WisetagScannedProfileFinishedReason: String {
    case SEND
    case REQUEST
    case DISMISS
}

struct WisetagScannedProfileAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Contact Link Page")
}

// MARK: - Page Started

extension WisetagScannedProfileAnalyticsView {
    struct Started: AnalyticsViewAction {
        typealias View = WisetagScannedProfileAnalyticsView
        let name = "Started"
    }
}

// MARK: - Page Loaded

extension WisetagScannedProfileAnalyticsView {
    struct Loaded: AnalyticsViewAction {
        typealias View = WisetagScannedProfileAnalyticsView
        let name = "Loaded"
        let properties: [AnalyticsProperty]

        init(
            matchIsSelf: Bool,
            matchIsExisting: Bool,
            matchHasAvatar: Bool
        ) {
            properties = [
                MatchIsSelf(value: matchIsSelf),
                MatchHasAvatar(value: matchHasAvatar),
                MatchIsExisting(value: matchIsExisting),
            ]
        }
    }
}

// MARK: - Page Failed

extension WisetagScannedProfileAnalyticsView {
    struct Failed: AnalyticsViewAction {
        typealias View = WisetagScannedProfileAnalyticsView
        let name = "Failed"
        let properties: [AnalyticsProperty]

        init(
            message: String
        ) {
            properties = [
                Reason(value: message),
            ]
        }
    }
}

// MARK: - Page Added

extension WisetagScannedProfileAnalyticsView {
    struct Added: AnalyticsViewAction {
        typealias View = WisetagScannedProfileAnalyticsView
        let name = "Added"
    }
}

// MARK: - Page Finished

extension WisetagScannedProfileAnalyticsView {
    struct Finished: AnalyticsViewAction {
        typealias View = WisetagScannedProfileAnalyticsView
        let name = "Finished"
        let properties: [AnalyticsProperty]

        init(
            finishedAction: WisetagScannedProfileFinishedReason,
            matchIsSelf: Bool,
            matchIsExisting: Bool,
            matchHasAvatar: Bool
        ) {
            properties = [
                Reason(action: finishedAction),
                MatchIsSelf(value: matchIsSelf),
                MatchHasAvatar(value: matchHasAvatar),
                MatchIsExisting(value: matchIsExisting),
            ]
        }
    }
}

private extension WisetagScannedProfileAnalyticsView {
    struct MatchIsSelf: AnalyticsProperty {
        let name = "Match - Is Self"
        let value: AnalyticsPropertyValue

        init(value: Bool) {
            self.value = value
        }
    }

    struct MatchIsExisting: AnalyticsProperty {
        let name = "Match - Is Existing"
        let value: AnalyticsPropertyValue

        init(value: Bool) {
            self.value = value
        }
    }

    struct MatchHasAvatar: AnalyticsProperty {
        let name = "Match - Has Avatar"
        let value: AnalyticsPropertyValue

        init(value: Bool) {
            self.value = value
        }
    }
}

private extension WisetagScannedProfileAnalyticsView.Failed {
    struct Reason: AnalyticsProperty {
        let name = "Reason"
        let value: AnalyticsPropertyValue

        init(value: String) {
            self.value = value
        }
    }
}

private extension WisetagScannedProfileAnalyticsView.Finished {
    struct Reason: AnalyticsProperty {
        let name = "Reason"
        let value: AnalyticsPropertyValue
        init(action: WisetagScannedProfileFinishedReason) {
            value = action.rawValue
        }
    }
}
