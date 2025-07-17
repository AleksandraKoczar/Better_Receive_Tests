import Neptune
import UIKit

final class WisetagQRCodeViewModel: ObservableObject {
    var state: QRCodeState

    enum QRCodeState {
        case qrCodeEnabled(
            qrCode: UIImage?,
            enabledText: String,
            enabledTextOnTap: String,
            // sourcery: skipEquality
            onTap: () -> Void
        )
        case qrCodeDisabled(
            placeholderQRCode: UIImage?,
            disabledText: String,
            // sourcery: skipEquality
            onTap: () -> Void
        )
    }

    init(state: QRCodeState) {
        self.state = state
    }

    var qrCodeImage: UIImage? {
        switch state {
        case let .qrCodeEnabled(qrCode, _, _, _):
            qrCode
        case let .qrCodeDisabled(placeholderQRCode, _, _):
            placeholderQRCode
        }
    }
}

extension WisetagQRCodeViewModel: Equatable {
    static func == (lhs: WisetagQRCodeViewModel, rhs: WisetagQRCodeViewModel) -> Bool {
        lhs.state == rhs.state
    }
}

extension WisetagQRCodeViewModel.QRCodeState: Equatable {
    static func == (lhs: WisetagQRCodeViewModel.QRCodeState, rhs: WisetagQRCodeViewModel.QRCodeState) -> Bool {
        switch (lhs, rhs) {
        case let (.qrCodeDisabled(qrCodeLeft, buttonLeft, _), .qrCodeDisabled(qrCodeRight, buttonRight, _)):
            buttonLeft == buttonRight && qrCodeLeft == qrCodeRight
        case let (.qrCodeEnabled(qrCodeLeft, buttonLeft, _, _), .qrCodeEnabled(qrCodeRight, buttonRight, _, _)):
            buttonLeft == buttonRight && qrCodeLeft == qrCodeRight
        default:
            false
        }
    }
}
