import BalanceKit
import Neptune
import TransferResources
import TWFoundation
import WiseCore

enum AccountDetailsInfoIntroViewModelFactory {
    static func make(
        shouldShowDetailsSummary: Bool,
        view: AccountDetailsInfoIntroView,
        maxNumberOfDetailItems: Int,
        currencyCode: CurrencyCode,
        details: [AccountDetailsDetailItem],
        navigationActions: [AccountDetailsInfoIntroNavigationAction],
        footerAction: @escaping () -> Void
    ) -> AccountDetailsInfoIntroViewModel {
        let infoViewModel: AccountDetailsReceiveOptionInfoViewModel? = {
            guard shouldShowDetailsSummary else {
                return nil
            }
            return AccountDetailsReceiveOptionInfoViewModel(
                header: nil,
                rows: details.prefix(maxNumberOfDetailItems).map {
                    makeInfoRowViewModel(detailItem: $0)
                },
                footer: AccountDetailsInfoFooterViewModel(
                    title: L10n.AccountDetails.Intro.Full.Details.title,
                    style: .link,
                    action: footerAction
                )
            )
        }()

        return AccountDetailsInfoIntroViewModel(
            title: LargeTitleViewModel(
                title: L10n.AccountDetails.Intro.Header.title
            ),
            infoViewModel: infoViewModel,
            sectionHeader: SectionHeaderViewModel(
                title: L10n.AccountDetails.Intro.Options.Section.title(
                    currencyCode.value
                )
            ),
            navigationActions: navigationActions
        )
    }
}

// MARK: - Helpers

private extension AccountDetailsInfoIntroViewModelFactory {
    static func makeInfoRowViewModel(detailItem: AccountDetailsDetailItem) -> AccountDetailsInfoRowViewModel {
        if detailItem.description == nil {
            return AccountDetailsInfoRowViewModel(
                title: detailItem.title,
                information: detailItem.body,
                isObfuscated: detailItem.shouldObfuscate,
                action: nil
            )
        }

        return AccountDetailsInfoRowViewModel(
            title: detailItem.title,
            information: detailItem.body,
            isObfuscated: detailItem.shouldObfuscate,
            action: nil
        )
    }
}
