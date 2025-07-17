import BalanceKit
import Foundation
import Neptune
import TransferResources
import UIKit

struct AccountDetailListSectionModel {
    let header: SectionHeaderViewModel?
    let items: [AccountDetailListItemViewModel]
    let footer: String?
}

struct AccountDetailListItemViewModel {
    let title: String
    let image: UIImage?
    let info: String?
    let hasWarning: Bool
}

extension AccountDetailListItemViewModel {
    init(forMultipleCurrencyList accountDetails: AccountDetails) {
        title = accountDetails.currencyName
        image = accountDetails.currency.squareIcon
        info = accountDetails.subtitle
        hasWarning = Self.hasWarning(accountDetails)
    }

    init(forDuplicateCurrenciesList accountDetails: AccountDetails, allAcountDetails: [AccountDetails]) {
        title = accountDetails.currencyName
        image = accountDetails.currency.squareIcon
        info = accountDetails.subtitle
        hasWarning = allAcountDetails.contains {
            Self.hasWarning($0)
        }
    }

    init(forSingleCurrencyList accountDetails: AccountDetails) {
        title = accountDetails.title ?? accountDetails.currencyName
        image = accountDetails.currency.squareIcon
        info = nil
        hasWarning = Self.hasWarning(accountDetails)
    }

    private static func hasWarning(_ accountDetails: AccountDetails) -> Bool {
        accountDetails.receiveOptions.contains { receiveOption in
            switch receiveOption.alert?.type {
            case .error,
                 .warning:
                true
            case .none,
                 .info,
                 .success:
                false
            }
        }
    }
}
