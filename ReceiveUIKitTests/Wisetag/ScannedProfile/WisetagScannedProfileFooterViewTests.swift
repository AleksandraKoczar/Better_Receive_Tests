import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class WisetagScannedProfileFooterViewTests: TWSnapshotTestCase {
    @MainActor
    func test_view_withButtons() {
        let viewModel = makeViewModelButtons()
        let view = WisetagScannedProfileFooterView()
        view.configure(with: viewModel)
        view.layoutForTest(fittingWidth: 390)
        TWSnapshotVerifyView(view)
    }

    @MainActor
    func test_view_withLoader() {
        let viewModel = makeViewModelLoader()
        let view = WisetagScannedProfileFooterView()
        view.configure(with: viewModel)
        view.layoutForTest(fittingWidth: 390)
        TWSnapshotVerifyView(view)
    }

    // MARK: - Helpers

    private func makeViewModelButtons() -> WisetagScannedProfileViewModel.FooterViewModel {
        let button = WisetagScannedProfileViewModel.ButtonViewModel(
            icon: Icons.fastFlag.image,
            title: LoremIpsum.veryShort,
            enabled: true,
            action: nil
        )

        let buttons = Array(repeating: button, count: 3)

        return WisetagScannedProfileViewModel.FooterViewModel(
            buttons: buttons,
            isLoading: false
        )
    }

    private func makeViewModelLoader() -> WisetagScannedProfileViewModel.FooterViewModel {
        WisetagScannedProfileViewModel.FooterViewModel(
            buttons: nil,
            isLoading: true
        )
    }
}
