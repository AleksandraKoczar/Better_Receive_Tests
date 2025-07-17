import AnalyticsKit
import Foundation

struct WisetagAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(name: "Profile Link")
}

// MARK: - Actions

extension WisetagAnalyticsView {
    struct Loaded: AnalyticsViewAction {
        typealias View = WisetagAnalyticsView
        let name = "Loaded"
        let properties: [AnalyticsProperty]

        private init(properties: [AnalyticsProperty]) {
            self.properties = properties
        }

        static let success = Self(properties: [Self.Success(success: true)])
        static func error(message: String) -> Self {
            Self(properties: [
                Success(success: false),
                Error(message: message),
            ])
        }
    }

    final class WisetagFailed: ReceiveErrorAnalyticsViewAction<WisetagAnalyticsView> {
        init?(error: WisetagError) {
            super.init(name: "Wisetag Failed", model: error)
        }
    }

    struct Copied: AnalyticsViewAction {
        typealias View = WisetagAnalyticsView
        let name = "Copied"
    }

    struct ShareStarted: AnalyticsViewAction {
        typealias View = WisetagAnalyticsView
        let name = "Share started"
    }

    struct NicknameOpened: AnalyticsViewAction {
        typealias View = WisetagAnalyticsView
        let name = "Nickname opened"
    }

    struct ActivateStarted: AnalyticsViewAction {
        typealias View = WisetagAnalyticsView
        let name = "Activate started"
    }

    struct SettingsOpened: AnalyticsViewAction {
        typealias View = WisetagAnalyticsView
        let name = "Settings opened"
    }

    struct ScanOpened: AnalyticsViewAction {
        typealias View = WisetagAnalyticsView
        let name = "Scan opened"
    }
}

// MARK: - Properties

private extension WisetagAnalyticsView.Loaded {
    struct Success: AnalyticsProperty {
        let name = "Success"
        let value: AnalyticsPropertyValue

        init(success: Bool) {
            value = success
        }
    }

    struct Error: AnalyticsProperty {
        let name = "Error"
        let value: AnalyticsPropertyValue

        init(message: String) {
            value = message
        }
    }
}

extension WisetagError: ReceiveErrorAnalyticsModel {
    var type: String {
        switch self {
        case .ineligible:
            "Wisetag Ineligible"
        case .loadingError:
            "Wisetag Loading Failed"
        case .updateSharableLinkError:
            "Wisetag Update Sharable Link Failed"
        case .downloadWisetagImageError:
            "Wisetag Download Image Failed"
        }
    }

    var message: String {
        switch self {
        case .ineligible:
            localizedDescription
        case let .loadingError(error):
            error.localizedDescription
        case let .updateSharableLinkError(error):
            error.localizedDescription
        case .downloadWisetagImageError:
            localizedDescription
        }
    }

    var identifier: String {
        caseNameId
    }
}
