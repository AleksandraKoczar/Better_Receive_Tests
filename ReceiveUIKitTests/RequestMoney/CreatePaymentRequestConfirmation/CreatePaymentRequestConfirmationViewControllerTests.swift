import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class CreatePaymentRequestConfirmationViewControllerTests: TWSnapshotTestCase {
    func test_screen() {
        let presenter = CreatePaymentRequestConfirmationPresenterMock()
        let viewController = CreatePaymentRequestConfirmationViewController(presenter: presenter)
        let viewModel = makeViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController)
    }

    // MARK: - Helpers

    private func makeViewModel() -> CreatePaymentRequestConfirmationViewModel {
        CreatePaymentRequestConfirmationViewModel(
            asset: .scene3D(.checkMark),
            title: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: LoremIpsum.veryShort,
                style: LabelStyle.display.centered,
                action: nil
            ),
            info: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: LoremIpsum.short,
                style: LabelStyle.largeBody.centered,
                action: nil
            ),
            privacyNotice: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: LoremIpsum.medium + " <link>Learn more</link>",
                style: LabelStyle.defaultBody.centered,
                action: {}
            ),
            shareButtons: [
                CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                    icon: Icons.shareIos.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                    icon: Icons.link.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                    icon: Icons.qrCode.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
            ],
            shouldShowExtendedFooter: true
        )
    }
}
