@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit

final class AccountDetailsEducationViewControllerTests: TWSnapshotTestCase {
    private var view: AccountDetailsEducationViewController!

    override func tearDown() {
        view = nil
        super.tearDown()
    }

    func test_noCopyButton() {
        let model = AccountDetailsBottomSheetViewModel(
            title: "Vintage tee, brand new phone",
            description: "High heels on cobblestones, When you are young, they assume you know nothing",
            footerConfig: nil
        )
        view = AccountDetailsEducationViewController(model: model)

        TWSnapshotVerifyViewController(view)
    }

    func test_copyButton_plainText() {
        let model = AccountDetailsBottomSheetViewModel(
            title: "Vintage tee, brand new phone",
            description: "High heels on cobblestones, When you are young, they assume you know nothing",
            footerConfig: AccountDetailsBottomSheetViewModel.CopyConfig(
                type: .plainText,
                title: "Sequin smile, black lipstick",
                value: "when you are young they assume you know nothing",
                copyAction: {}
            )
        )
        view = AccountDetailsEducationViewController(model: model)

        TWSnapshotVerifyViewController(view)
    }

    func test_copyButton_revealable() {
        let model = AccountDetailsBottomSheetViewModel(
            title: "Vintage tee, brand new phone",
            description: "High heels on cobblestones, When you are young, they assume you know nothing",
            footerConfig: AccountDetailsBottomSheetViewModel.CopyConfig(
                type: .revealed,
                title: "Sequin smile, black lipstick",
                value: "when you are young they assume you know nothing",
                copyAction: {}
            )
        )

        view = AccountDetailsEducationViewController(model: model)

        TWSnapshotVerifyViewController(view)
    }
}
