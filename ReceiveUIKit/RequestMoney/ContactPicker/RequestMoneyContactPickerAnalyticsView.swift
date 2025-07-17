import AnalyticsKit
import Foundation

struct RequestMoneyContactPickerAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(
        name: CreatePaymentRequestFlowAnalytics.identity.name
            + " - "
            + "Contact Picker"
    )
}

struct RequestMoneyContactPickerSuccessAnalyticsView: AnalyticsView {
    static let identity = AnalyticsIdentity(
        name: CreatePaymentRequestFlowAnalytics.identity.name
            + " - "
            + "Success Screen"
    )
}

// MARK: - Actions

extension RequestMoneyContactPickerAnalyticsView {
    struct LoadedAction: AnalyticsViewAction {
        typealias View = RequestMoneyContactPickerAnalyticsView

        let name = "Loaded"
        let properties: [AnalyticsProperty]

        init(hasContacts: Bool) {
            properties = [
                HasContacts(value: hasContacts),
            ]
        }
    }

    struct LoadingFailed: AnalyticsViewAction {
        typealias View = RequestMoneyContactPickerAnalyticsView

        let name = "Loading Failed"
        let properties: [AnalyticsProperty]

        init(hasContacts: Bool, message: String) {
            properties = [
                HasContacts(value: hasContacts),
                AnyAnalyticsProperty("Message", message),
            ]
        }
    }

    struct ContactSelected: AnalyticsViewAction {
        typealias View = RequestMoneyContactPickerAnalyticsView

        let name = "Contact Selected"
        let properties: [AnalyticsProperty] = []
    }

    struct CreateLinkSelected: AnalyticsViewAction {
        typealias View = RequestMoneyContactPickerAnalyticsView

        let name = "Create Link Selected"
        let properties: [AnalyticsProperty]

        init(hasContacts: Bool) {
            properties = [
                HasContacts(value: hasContacts),
            ]
        }
    }
}

extension RequestMoneyContactPickerSuccessAnalyticsView {
    struct DoneTapped: AnalyticsViewAction {
        typealias View = RequestMoneyContactPickerSuccessAnalyticsView

        let name = "Done Tapped"
    }

    struct ViewRequestTapped: AnalyticsViewAction {
        typealias View = RequestMoneyContactPickerSuccessAnalyticsView

        let name = "View Request Tapped"
    }
}

// MARK: - Properties

extension RequestMoneyContactPickerAnalyticsView {
    final class HasContacts: BooleanStringAnalyticsProperty {
        init(value: Bool) {
            super.init(
                name: "Has Contacts",
                value: value
            )
        }
    }
}
