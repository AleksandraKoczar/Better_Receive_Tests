import AnalyticsKitTestingSupport
import ApiKit
import ApiKitTestingSupport
import BalanceKit
import Combine
import HttpClientKit
import ObjectModelKitTestingSupport
import PersistenceKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import UIKit
import UserKit
import UserKitTestingSupport

final class OpenAccountDetailViewStateTests: TWSnapshotTestCase {
    private var viewController: AccountDetailsListViewController!
    private var presenter: AccountDetailListPresenter!

    override func setUp() {
        super.setUp()
        presenter = AccountDetailListPresenterMock()
        viewController = AccountDetailsListViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil

        super.tearDown()
    }

    func test_accountDetailsList() {
        viewController.configureHeader(viewModel: LargeTitleViewModel(title: "Account Details"))
        viewController.updateList(sections: [
            AccountDetailListSectionModel(
                header: SectionHeaderViewModel(title: "This is the header"),
                items: [
                    AccountDetailListItemViewModel(
                        title: "Account Details 1",
                        image: nil,
                        info: "Some info",
                        hasWarning: false
                    ),
                    AccountDetailListItemViewModel(
                        title: "Account Details 2",
                        image: nil,
                        info: "Some info that is different",
                        hasWarning: false
                    ),
                    AccountDetailListItemViewModel(
                        title: "Account Details 3",
                        image: nil,
                        info: "Some info that is really long and complicated",
                        hasWarning: false
                    ),
                    AccountDetailListItemViewModel(
                        title: "Account Details 4",
                        image: nil,
                        info: nil,
                        hasWarning: false
                    ),
                ],
                footer: "Footer messsage"
            ),
        ])

        TWSnapshotVerifyViewController(viewController)
    }

    func test_getExistingAccountDetails_afterFailedLoading() {
        viewController.configureHeader(viewModel: LargeTitleViewModel(title: "Account Details"))
        presenter.start(withView: viewController)
        viewController.updateList(sections: [])
        viewController.showErrorAlert(title: "There is an error", error: nil)

        TWSnapshotVerifyViewController(viewController)
    }

    func testNavigationItem_givenContextIsAccountTab() {
        let buttonItem = UIBarButtonItem.backButton(.arrow, action: {})
        viewController.setupNavigationLeftButton(buttonStyle: .arrow, buttonAction: {})

        XCTAssertEqual(viewController.navigationItem.leftBarButtonItem?.image, buttonItem.image)
    }

    func testNavigationItem_givenContextIsIntentPicker() {
        let buttomItem = UIBarButtonItem.backButton(.cross, action: {})

        viewController.setupNavigationLeftButton(buttonStyle: .cross, buttonAction: {})

        XCTAssertEqual(viewController.navigationItem.leftBarButtonItem?.image, buttomItem.image)
    }
}
