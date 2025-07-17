import Foundation
import Neptune

// sourcery: AutoEquatableForTest
struct QRDownloadViewModel {
    let title: String
    let subtitle: String
    let cameraDownloadOption: QRDownloadViewModel.Option
    let fileDownloadOption: QRDownloadViewModel.Option
}

extension QRDownloadViewModel {
    // sourcery: AutoEquatableForTest
    struct Option {
        let viewModel: OptionViewModel
        // sourcery: skipEquality
        let onTap: () -> Void
    }
}
