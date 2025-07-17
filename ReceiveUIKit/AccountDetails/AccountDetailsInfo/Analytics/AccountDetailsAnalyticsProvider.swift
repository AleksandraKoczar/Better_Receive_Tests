import AnalyticsKit
import BalanceKit
import TWFoundation
import WiseCore

protocol AccountDetailsAnalyticsProvider {
    func pageShown(
        accountDetailsId: AccountDetailsId?,
        currencyCode: CurrencyCode?,
        invocationSource: AccountDetailsInfoInvocationSource,
        context: AccountDetailsType
    ) -> AnalyticsScreenItem
    func tabChanged(_ receiveType: String?) -> AnalyticsEventItem
    func summaryDescriptionShown(_ type: String?) -> AnalyticsEventItem
    func modalShown(_ modalType: String?) -> AnalyticsEventItem
    func modalCopied(_ modalType: String?) -> AnalyticsEventItem
    func shareSheetShown(_ currencyCode: CurrencyCode) -> AnalyticsEventItem
    func copyButtonTapped(
        _ currencyCode: CurrencyCode,
        analyticsType: String?
    ) -> AnalyticsEventItem
    func exploreButtonTapped(_ currencyCode: CurrencyCode) -> AnalyticsEventItem
    func shareActionSheetShown(_ currencyCode: CurrencyCode) -> AnalyticsEventItem
    func sharedViaShareSheet(
        currencyCode: CurrencyCode,
        activityType: String,
        isCompleted: Bool
    ) -> AnalyticsEventItem
    func copiedFromActionSheet(_ currencyCode: CurrencyCode) -> AnalyticsEventItem
    func pdfShared(_ currencyCode: CurrencyCode) -> AnalyticsEventItem
}

struct AccountDetailsAnalyticsProviderImpl: AccountDetailsAnalyticsProvider {
    func pageShown(
        accountDetailsId: AccountDetailsId?,
        currencyCode: CurrencyCode?,
        invocationSource: AccountDetailsInfoInvocationSource,
        context: AccountDetailsType
    ) -> AnalyticsScreenItem {
        AccountDetailsAnalyticsScreenItem(
            accountDetailsId: accountDetailsId,
            currencyCode: currencyCode,
            invocationSource: invocationSource,
            context: context
        )
    }

    func tabChanged(_ receiveType: String?) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(.tabChanged(receiveType ?? "No tab name"))
    }

    func summaryDescriptionShown(_ type: String?) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(.summaryDescriptionShown(type ?? "No modal type"))
    }

    func modalShown(_ modalType: String?) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(.modalShown(modalType ?? "No modal type"))
    }

    func modalCopied(_ modalType: String?) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(.modalCopied(modalType ?? "No modal type"))
    }

    func shareSheetShown(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(.shareSheetShown(currencyCode))
    }

    func sharedViaShareSheet(
        currencyCode: CurrencyCode,
        activityType: String,
        isCompleted: Bool
    ) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(
            .sharedViaShareSheet(
                currencyCode: currencyCode,
                activityType: activityType,
                isCompleted: isCompleted
            )
        )
    }

    func copyButtonTapped(
        _ currencyCode: CurrencyCode,
        analyticsType: String?
    ) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(
            .copyButtonTapped(
                currencyCode,
                analyticsValue: analyticsType ?? "ALL"
            )
        )
    }

    func exploreButtonTapped(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(.exploreButtonTapped(currencyCode))
    }

    func shareActionSheetShown(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(.shareActionSheetShown(currencyCode))
    }

    func copiedFromActionSheet(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(.copiedFromActionSheet(currencyCode))
    }

    func pdfShared(_ currencyCode: CurrencyCode) -> AnalyticsEventItem {
        AccountDetailsAnalyticsEvent(.pdfShared(currencyCode))
    }
}
