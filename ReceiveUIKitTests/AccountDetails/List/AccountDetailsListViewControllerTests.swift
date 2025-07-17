import Foundation
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import TWUI
import WiseCore

final class AccountDetailsListViewControllerTests: TWSnapshotTestCase {
    func testLayout() {
        let presenter = AccountDetailListPresenterMock()
        let viewController = AccountDetailsListViewController(
            presenter: presenter
        )

        viewController.configureHeader(
            viewModel: LargeTitleViewModel(
                title: "List",
                searchFieldPlaceholder: "Search"
            )
        )

        viewController.updateList(
            sections: [
                AccountDetailListSectionModel(
                    header: SectionHeaderViewModel(
                        title: "Your acc details"
                    ),
                    items: [
                        AccountDetailListItemViewModel(
                            title: "Britti Pound",
                            image: CurrencyCode.GBP.icon,
                            info: "Sort code, IBAN",
                            hasWarning: true
                        ),
                        AccountDetailListItemViewModel(
                            title: "Europa",
                            image: CurrencyCode.EUR.icon,
                            info: "BIC BIC SWIFT",
                            hasWarning: false
                        ),
                    ],
                    footer: nil
                ),
                AccountDetailListSectionModel(
                    header: SectionHeaderViewModel(
                        title: "Get more"
                    ),
                    items: [
                        AccountDetailListItemViewModel(
                            title: "Canada dolllllar",
                            image: CurrencyCode.CAD.icon,
                            info: "Transt number, acc number",
                            hasWarning: false
                        ),
                    ],
                    footer: "Looking for sth else"
                ),
            ]
        )

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}
