import AnalyticsKit
import ApiKit
import BalanceKit
import TWFoundation
import WiseCore

struct AccountDetailsAnalyticsEvent: AnalyticsEventItem {
    enum Event {
        case tabChanged(_ receiveType: String)
        case summaryDescriptionShown(_ type: String)
        case modalShown(_ modalType: String)
        case modalCopied(_ modalType: String)
        case shareSheetShown(_ currencyCode: CurrencyCode)
        case sharedViaShareSheet(
            currencyCode: CurrencyCode,
            activityType: String,
            isCompleted: Bool
        )
        case copyButtonTapped(_ currencyCode: CurrencyCode, analyticsValue: String)
        case exploreButtonTapped(_ currencyCode: CurrencyCode)
        case shareActionSheetShown(_ currencyCode: CurrencyCode)
        case copiedFromActionSheet(_ currencyCode: CurrencyCode)
        case pdfShared(_ currency: CurrencyCode)
    }

    private enum PropertyKeys {
        static let currency = "Currency"
    }

    private let name: String
    private let properties: [String: Any]

    // swiftlint:disable:next cyclomatic_complexity
    init(_ event: Event) {
        switch event {
        case let .tabChanged(receiveType):
            name = "Bank Details - Receive option selected"
            properties = ["ReceiveType": receiveType]

        case let .summaryDescriptionShown(type):
            name = "Bank Details - Summary item description opened"
            properties = ["Type": type]

        case let .modalShown(modalType):
            name = "Bank Details - Detail item description opened"
            properties = ["ModalType": modalType]

        case let .modalCopied(modalType):
            name = "Bank Details - Description value copied"
            properties = ["ModalType": modalType]

        case let .shareSheetShown(currencyCode):
            name = "Bank Details - shared"
            properties = [PropertyKeys.currency: currencyCode.value]

        case let .sharedViaShareSheet(currencyCode, activityType, isCompleted):
            name = "Bank Details - shared via share sheet"
            properties = [
                PropertyKeys.currency: currencyCode.value,
                "Activity Type": activityType,
                "Completed": isCompleted,
            ]

        case let .copyButtonTapped(currencyCode, analyticsValue):
            name = "Bank Details - copied"
            properties = [
                PropertyKeys.currency: currencyCode.value,
                "Type": analyticsValue,
            ]

        case let .exploreButtonTapped(currencyCode):
            name = "Bank Details - explore tapped"
            properties = [PropertyKeys.currency: currencyCode.value]

        case let .shareActionSheetShown(currencyCode):
            name = "Bank Details - Share Action Sheet Shown"
            properties = [PropertyKeys.currency: currencyCode.value]

        case let .copiedFromActionSheet(currencyCode):
            name = "Bank Details - Copied From Action Sheet"
            properties = [PropertyKeys.currency: currencyCode.value]

        case let .pdfShared(currencyCode):
            name = "Bank Details - Shared Via PDF"
            properties = [PropertyKeys.currency: currencyCode.value]
        }
    }

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        [MixpanelEvent(name: name, properties: properties)]
    }
}
