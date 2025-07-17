import Foundation
import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import TWUI
import WiseCore

final class AccountDetailsWishViewControllerTests: TWSnapshotTestCase {
    func testLayout() {
        let presenter = AccountDetailsWishListPresenterMock()
        let viewController = AccountDetailsWishViewController(
            presenter: presenter
        )

        viewController.configure(
            options: [
                OptionViewModel(
                    title: "GBP",
                    subtitle: "British pound",
                    leadingView: .avatar(
                        AvatarViewModel.image(
                            CurrencyCode.GBP.squareIcon
                        )
                    )
                ),
                OptionViewModel(
                    title: "EUR",
                    subtitle: "Euro",
                    leadingView: .avatar(
                        AvatarViewModel.image(
                            CurrencyCode.EUR.squareIcon
                        )
                    )
                ),
            ]
        )

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}
