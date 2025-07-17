import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class QRDownloadBottomSheetViewControllerTests: TWSnapshotTestCase {
    func test_screen() {
        let viewModel = makeViewModel()
        let presenter = QRDownloadPresenterMock()
        let viewController = QRDownloadBottomSheetViewController(presenter: presenter)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController)
    }

    private func makeViewModel() -> QRDownloadViewModel {
        QRDownloadViewModel(
            title: LoremIpsum.short,
            subtitle: LoremIpsum.medium,
            cameraDownloadOption: makeOption(),
            fileDownloadOption: makeOption()
        )
    }

    private func makeOption() -> QRDownloadViewModel.Option {
        QRDownloadViewModel.Option(
            viewModel: OptionViewModel(
                title: LoremIpsum.short,
                avatar: .icon(Icons.people.image)
            ),
            onTap: {}
        )
    }
}
