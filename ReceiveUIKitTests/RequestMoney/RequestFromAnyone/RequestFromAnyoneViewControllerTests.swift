import Foundation
import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class RequestFromAnyoneViewControllerTests: TWSnapshotTestCase {
    private let qrCode = UIImage.qrCode(from: "https://wise.com/abcdefg1234")!

    private var viewController: RequestPaymentFromAnyoneViewController!
    private var presenter: RequestFromAnyonePresenterMock!

    override func setUp() {
        super.setUp()
        presenter = RequestFromAnyonePresenterMock()
        viewController = RequestPaymentFromAnyoneViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }

    func test_screen_withWisetagEnabled() {
        let viewModel = makeWisetagActive()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_withWisetagDisabled() {
        let viewModel = makeWisetagInactive()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    // MARK: - Helpers

    private func makeWisetagActive() -> RequestPaymentFromAnyoneViewModel {
        RequestPaymentFromAnyoneViewModel(
            titleViewModel: .init(title: LoremIpsum.short, description: LoremIpsum.medium),
            qrCodeViewModel: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeEnabled(
                qrCode: qrCode,
                enabledText: LoremIpsum.veryShort,
                enabledTextOnTap: LoremIpsum.veryShort,
                onTap: {}
            )),
            doneAction: SmallButtonView(viewModel: .init(title: "Done", handler: {}), style: .smallSecondaryNeutral),
            primaryActionFooter: Action(
                title: LoremIpsum.veryShort,
                handler: {}
            ),
            secondaryActionFooter: Action(
                title: LoremIpsum.veryShort,
                handler: {}
            )
        )
    }

    private func makeWisetagInactive() -> RequestPaymentFromAnyoneViewModel {
        RequestPaymentFromAnyoneViewModel(
            titleViewModel: .init(title: LoremIpsum.short, description: LoremIpsum.medium),
            qrCodeViewModel: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeDisabled(
                placeholderQRCode: qrCode,
                disabledText: LoremIpsum.veryShort,
                onTap: {}
            )),
            doneAction: SmallButtonView(viewModel: .init(title: "Done", handler: {}), style: .smallSecondaryNeutral),
            primaryActionFooter: Action(
                title: LoremIpsum.veryShort,
                handler: {}
            ),
            secondaryActionFooter: Action(
                title: LoremIpsum.veryShort,
                handler: {}
            )
        )
    }
}
