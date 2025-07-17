import AnalyticsKitTestingSupport
import ApiKitTestingSupport
import Neptune
import PersistenceKitTestingSupport
@testable import ReceiveUIKit
import TransferResources
import TWFoundation
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport
import WiseCore

final class SalarySwitchOptionSelectionViewControllerTests: TWSnapshotTestCase {
    func testUpsellScreen() {
        let viewController = SalarySwitchOptionSelectionViewController(
            presenter: SalarySwitchOptionSelectionPresenterMock()
        )
        viewController.configure(viewModel: SalarySwitchOptionSelectionViewModel(
            titleViewModel: LargeTitleViewModel(title: "Switch your salary"),
            sections: [
                SalarySwitchOptionSelectionViewModel.Section(
                    title: "Section 1",
                    options: [OptionViewModel(title: "Ooption nummber 1")]
                ),
                SalarySwitchOptionSelectionViewModel.Section(
                    title: "Section 2",
                    options: [OptionViewModel(title: "Option number 2")]
                ),
            ]
        ))
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}
