import AnalyticsKit
import BalanceKit
@testable import ReceiveUIKit
import TWFoundation
import WiseCore

final class MockAccountDetailsAnalyticsProvider: AccountDetailsAnalyticsProvider {
    init() {}

    var pageShownAccountDetailsId: AccountDetailsId!
    var pageShownCurrencyCode: CurrencyCode!
    var pageShownContext: AccountDetailsType!
    func pageShown(
        accountDetailsId: AccountDetailsId?,
        currencyCode: CurrencyCode?,
        invocationSource: AccountDetailsInfoInvocationSource,
        context: AccountDetailsType
    ) -> AnalyticsScreenItem {
        pageShownAccountDetailsId = accountDetailsId
        pageShownCurrencyCode = currencyCode
        pageShownContext = context
        return MockAnalyticsItem(name: "pageShown")
    }

    var tabChangedReceiveType: String!
    func tabChanged(_ receiveType: String?) -> AnalyticsEventItem {
        tabChangedReceiveType = receiveType
        return MockAnalyticsItem(name: "tabChanged")
    }

    var summaryDescriptionType: String!
    func summaryDescriptionShown(_ type: String?) -> AnalyticsEventItem {
        summaryDescriptionType = type
        return MockAnalyticsItem(name: "summaryDescriptionShown")
    }

    var modalShownType: String!
    func modalShown(_ modalType: String?) -> AnalyticsEventItem {
        modalShownType = modalType
        return MockAnalyticsItem(name: "modalShown")
    }

    var modalCopiedBool = false
    func modalCopied(_ modalType: String?) -> AnalyticsEventItem {
        modalCopiedBool = true
        return MockAnalyticsItem(name: "modalCopied")
    }

    var shareSheetCurrencyCode: CurrencyCode!
    func shareSheetShown(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        shareSheetCurrencyCode = currencyCode
        return MockAnalyticsItem(name: "shareSheetShown")
    }

    var copyButtonCurrencyCode: CurrencyCode!
    var copyButtonAnalyticsType: String!
    func copyButtonTapped(
        _ currencyCode: CurrencyCode,
        analyticsType: String?
    ) -> AnalyticsEventItem {
        copyButtonCurrencyCode = currencyCode
        copyButtonAnalyticsType = analyticsType
        return MockAnalyticsItem(name: "copyButtonTapped")
    }

    var exploreButtonCurrencyCode: CurrencyCode!
    func exploreButtonTapped(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        exploreButtonCurrencyCode = currencyCode
        return MockAnalyticsItem(name: "exploreButtonTapped")
    }

    var shareActionSheetShownCurrencyCode: CurrencyCode!
    func shareActionSheetShown(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        shareActionSheetShownCurrencyCode = currencyCode
        return MockAnalyticsItem(name: "shareActionSheetShown")
    }

    var copiedFromActionSheetCurrencyCode: CurrencyCode!
    func copiedFromActionSheet(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        copiedFromActionSheetCurrencyCode = currencyCode
        return MockAnalyticsItem(name: "copiedFromActionSheet")
    }

    var pdfSharedCurrencyCode: CurrencyCode!
    func pdfShared(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        pdfSharedCurrencyCode = currencyCode
        return MockAnalyticsItem(name: "pdfShared")
    }

    var sharedViaShareSheetCurrencyCode: CurrencyCode!
    var sharedViaShareSheetActivityType: String!
    var sharedViaShareSheetIsCompleted: Bool!
    func sharedViaShareSheet(
        currencyCode: CurrencyCode,
        activityType: String,
        isCompleted: Bool
    ) -> AnalyticsEventItem {
        sharedViaShareSheetCurrencyCode = currencyCode
        sharedViaShareSheetActivityType = activityType
        sharedViaShareSheetIsCompleted = isCompleted
        return MockAnalyticsItem(name: "sharedViaShareSheet")
    }
}

struct MockAnalyticsItem: AnalyticsEventItem, AnalyticsScreenItem, Equatable {
    let name: String

    func eventDescriptors() -> [AnalyticsEventDescriptor] {
        []
    }

    func screenDescriptors() -> [AnalyticsScreenDescriptor] {
        []
    }
}
