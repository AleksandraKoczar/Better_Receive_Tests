import Foundation
import Neptune
import UIKit

// sourcery: AutoEquatableForTest
struct CreatePaymentRequestMethodManagementViewModel {
    let title: String
    let subtitle: String
    let options: [CreatePaymentRequestMethodManagementViewModel.OptionViewModel]
    let footerAction: Action
    let secondaryFooterAction: Action
}

extension CreatePaymentRequestMethodManagementViewModel {
    // sourcery: AutoEquatableForTest
    enum OptionViewModel {
        case switchOptionViewModel(SwitchOptionViewModel)
        case payWithWiseOptionViewModel(Neptune.OptionViewModel)
        case actionOptionViewModel(ActionOptionViewModel)
    }

    // sourcery: AutoEquatableForTest
    struct SwitchOptionViewModel {
        let title: String
        let subtitle: String?
        let leadingViewModel: LeadingViewModel
        let isOn: Bool
        let isEnabled: Bool
        // sourcery: skipEquality
        let onToggle: (Bool) -> Void
    }

    // sourcery: AutoEquatableForTest
    struct ActionOptionViewModel {
        let title: String
        let subtitle: String?
        let leadingViewModel: LeadingViewModel
        let action: Action
    }
}
