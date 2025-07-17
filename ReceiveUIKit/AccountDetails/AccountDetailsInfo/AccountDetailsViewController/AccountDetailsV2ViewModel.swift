import ApiKit
import BalanceKit
import Foundation
import Neptune
import TWFoundation
import UIKit
import WiseCore

struct AccountDetailsV2ViewModel {
    let title: LargeTitleViewModel
    let receiveOptions: [AccountDetailsReceiveOptionV2PageViewModel]
    let isExploreEnabled: Bool
}

extension AccountDetailsV2ViewModel {
    init(
        title: String?,
        currency: CurrencyCode,
        activeAccountDetails: ActiveAccountDetails,
        modalDelegate: AccountDetailsInfoModalDelegate,
        accountDetailsType: AccountDetailsType,
        isExploreEnabled: Bool,
        nudgeSelectAction: @escaping (() -> Void),
        alertAction: @escaping ((String) -> Void)
    ) {
        self.title = LargeTitleViewModel(title: title ?? "")
        self.isExploreEnabled = isExploreEnabled
        receiveOptions = activeAccountDetails.receiveOptions.map { receiveOption in
            AccountDetailsReceiveOptionV2PageViewModelFactory.make(
                currencyCode: currency,
                receiveOption: receiveOption,
                modalDelegate: modalDelegate,
                accountDetailsType: accountDetailsType,
                nudgeSelectAction: nudgeSelectAction,
                alertAction: alertAction
            )
        }
    }
}

extension AccountDetailsAlert {
    func asInlineAlertStyle() -> InlineAlertStyle {
        switch type {
        case .success:
            .positive
        case .warning:
            .warning
        case .info:
            .neutral
        case .error:
            .negative
        }
    }
}

extension AccountDetailsSummaryItem.SummaryItemType {
    var image: UIImage {
        switch self {
        case .info:
            Icons.infoCircle.image
        case .time:
            Icons.clock.image
        case .limit:
            Icons.limit.image
        case .platform:
            Icons.bankTransfer.image
        case .fee:
            Icons.receipt.image
        case .safety:
            Icons.padlock.image
        case .other:
            Icons.infoCircle.image
        }
    }
}
