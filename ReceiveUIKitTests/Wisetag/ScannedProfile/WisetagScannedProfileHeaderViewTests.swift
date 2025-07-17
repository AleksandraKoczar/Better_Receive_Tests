import Neptune
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit

final class WisetagScannedProfileHeaderViewTests: TWSnapshotTestCase {
    @MainActor
    func test_view() {
        let viewModel = WisetagScannedProfileViewModel.HeaderViewModel(
            avatar: .canned,
            title: LoremIpsum.veryShort,
            subtitle: LoremIpsum.medium,
            alert: nil
        )

        let view = WisetagScannedProfileHeaderView()
        view.configure(with: viewModel)
        view.layoutForTest(fittingWidth: 390)
        TWSnapshotVerifyView(view)
    }

    @MainActor
    func test_view_withAlert() {
        let alert = WisetagScannedProfileViewModel.HeaderViewModel.Alert(
            style: .neutral,
            viewModel: Neptune.InlineAlertViewModel(message: L10n.Wisetag.ScannedProfile.IsSelf.Alert.message)
        )

        let viewModel = WisetagScannedProfileViewModel.HeaderViewModel(
            avatar: .canned,
            title: LoremIpsum.veryShort,
            subtitle: LoremIpsum.medium,
            alert: alert
        )

        let view = WisetagScannedProfileHeaderView()
        view.configure(with: viewModel)
        view.layoutForTest(fittingWidth: 390)
        TWSnapshotVerifyView(view)
    }
}
