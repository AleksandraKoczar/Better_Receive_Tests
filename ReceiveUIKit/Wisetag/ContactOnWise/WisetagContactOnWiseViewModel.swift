import Foundation
import Neptune

// sourcery: AutoEquatableForTest
struct WisetagContactOnWiseViewModel {
    let title: String
    let subtitle: String
    let inlineAlert: WisetagContactOnWiseViewModel.Alert?
    let wisetagOption: WisetagContactOnWiseViewModel.SwitchOption
    let action: Action
}

extension WisetagContactOnWiseViewModel {
    // sourcery: AutoEquatableForTest
    struct Alert {
        let viewModel: InlineAlertViewModel
        let style: InlineAlertStyle
    }

    // sourcery: AutoEquatableForTest
    struct SwitchOption {
        let viewModel: SwitchOptionViewModel
        // sourcery: skipEquality
        let onToggle: (Bool) -> Void
    }
}
