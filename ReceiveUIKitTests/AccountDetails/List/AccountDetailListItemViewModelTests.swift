import BalanceKit
@testable import ReceiveUIKit
import TWTestingSupportKit

final class AccountDetailListItemViewModelTests: TWTestCase {
    private let accountDetailsWithoutAlert = AccountDetails.canned
    private let accountDetailsWithAlert = AccountDetails.active(.build(
        receiveOptions: [
            .canned,
            AccountDetailsReceiveOption.build(
                alert: AccountDetailsAlert.build(
                    content: "",
                    type: .warning
                )
            ),
        ]
    ))

    func testSingle_GivenAlert_ThenModelHasWarning() {
        let cannedModel = AccountDetailListItemViewModel(
            forSingleCurrencyList: accountDetailsWithoutAlert
        )
        let model = AccountDetailListItemViewModel(
            forSingleCurrencyList: accountDetailsWithAlert
        )

        XCTAssertFalse(cannedModel.hasWarning)
        XCTAssertTrue(model.hasWarning)
    }

    func testMultiple_GivenAlert_ThenModelHasWarning() {
        let cannedModel = AccountDetailListItemViewModel(
            forMultipleCurrencyList: accountDetailsWithoutAlert
        )
        let model = AccountDetailListItemViewModel(
            forMultipleCurrencyList: accountDetailsWithAlert
        )

        XCTAssertFalse(cannedModel.hasWarning)
        XCTAssertTrue(model.hasWarning)
    }

    func testSingle_GivenInfoAlert_ThenModelHasWarning() {
        let accountDetailsWithAlert = AccountDetails.active(.build(
            receiveOptions: [
                .canned,
                AccountDetailsReceiveOption.build(
                    alert: AccountDetailsAlert.build(
                        content: "",
                        type: .info
                    )
                ),
            ]
        ))

        let model = AccountDetailListItemViewModel(
            forSingleCurrencyList: accountDetailsWithAlert
        )

        XCTAssertFalse(model.hasWarning)
    }

    func testDuplicate_GivenAlert_ThenModelHasWarning() {
        let accountDetailsWithAlert = AccountDetails.active(.build(
            currency: .SGD,
            receiveOptions: [
                AccountDetailsReceiveOption.build(),
                AccountDetailsReceiveOption.build(
                    alert: AccountDetailsAlert.build(
                        content: "",
                        type: .info
                    )
                ),
            ]
        ))
        let accountDetailsWithoutAlert = AccountDetails.active(.build(
            currency: .SGD,
            receiveOptions: [
                AccountDetailsReceiveOption.build(),
                AccountDetailsReceiveOption.build(
                    alert: AccountDetailsAlert.build(
                        content: "",
                        type: .error
                    )
                ),
            ]
        ))

        let model = AccountDetailListItemViewModel(
            forDuplicateCurrenciesList: accountDetailsWithoutAlert,
            allAcountDetails: [accountDetailsWithoutAlert, accountDetailsWithAlert]
        )

        XCTAssertTrue(model.hasWarning)
    }
}
