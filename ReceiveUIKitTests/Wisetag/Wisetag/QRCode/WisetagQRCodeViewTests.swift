import Neptune
@testable import ReceiveUIKit
import SwiftUI
import TWFoundation
import TWTestingSupportKit

final class WisetagQRCodeViewTests: TWSnapshotTestCase {
    private let qrCode = UIImage.qrCode(from: "https://wise.com/abcdefg1234")!

    func test_view_qrCodeEnabled() throws {
        try XCTSkipAlways("Skipping since Xcode 16")

        let viewModel = WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeEnabled(
            qrCode: qrCode,
            enabledText: LoremIpsum.veryShort,
            enabledTextOnTap: LoremIpsum.veryShort,
            onTap: {}
        ))
        let view = WisetagQRCodeView(viewModel: viewModel)
        TWSnapshotVerifySwiftUIView(view)
    }

    func test_view_qrCodeDisabled() throws {
        try XCTSkipAlways("Skipping since Xcode 16")

        let viewModel = WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeDisabled(
            placeholderQRCode: qrCode,
            disabledText: LoremIpsum.veryShort,
            onTap: {}
        ))

        let view = WisetagQRCodeView(viewModel: viewModel)
        TWSnapshotVerifySwiftUIView(view)
    }
}
