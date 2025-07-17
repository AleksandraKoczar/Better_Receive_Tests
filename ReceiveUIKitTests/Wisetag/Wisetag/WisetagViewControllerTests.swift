import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class WisetagViewControllerTests: TWSnapshotTestCase {
    private let qrCode = UIImage.qrCode(from: "https://wise.com/abcdefg1234")!

    private var viewController: WisetagViewController!
    private var presenter: WisetagPresenterMock!

    override func setUp() {
        super.setUp()
        presenter = WisetagPresenterMock()
        viewController = WisetagViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }

    func test_screen_givenWisetagIsInactive() {
        let viewModel = makeWisetagInactiveViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_givenWisetagIsActive() {
        let viewModel = makeWisetagActiveViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    // MARK: - Helpers

    private func makeWisetagInactiveViewModel() -> WisetagViewModel {
        WisetagViewModel(
            header: WisetagHeaderViewModel(
                avatar: AvatarViewModel.initials(Initials(name: "Harry Potter")),
                title: LoremIpsum.veryShort,
                linkType: .inactive(inactiveLink: LoremIpsum.veryShort)
            ),
            qrCode: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeDisabled(
                placeholderQRCode: qrCode,
                disabledText: LoremIpsum.veryShort,
                onTap: {}
            )),
            shareButtons: [],
            footerAction: Action(
                title: LoremIpsum.veryShort,
                handler: {}
            ),
            navigationBarButtons: [
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.slider.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
            ]
        )
    }

    private func makeWisetagActiveViewModel() -> WisetagViewModel {
        WisetagViewModel(
            header: WisetagHeaderViewModel(
                avatar: AvatarViewModel.initials(Initials(name: "Harry Potter")),
                title: LoremIpsum.veryShort,
                linkType: .active(link: LoremIpsum.veryShort, touchHandler: {})
            ),
            qrCode: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeEnabled(
                qrCode: qrCode,
                enabledText: LoremIpsum.veryShort,
                enabledTextOnTap: LoremIpsum.veryShort,
                onTap: {}
            )),
            shareButtons: [
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.link.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.shareIos.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.download.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
            ],
            footerAction: nil,
            navigationBarButtons: [
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.slider.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.scanQrCode.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
            ]
        )
    }
}
