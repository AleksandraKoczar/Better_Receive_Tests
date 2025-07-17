import Foundation
import Neptune

// sourcery: AutoEquatableForTest
struct PaymentLinkPaymentDetailsViewModel {
    let title: LargeTitleViewModel
    let sections: [PaymentLinkPaymentDetailsViewModel.Section]
}

extension PaymentLinkPaymentDetailsViewModel {
    // sourcery: AutoEquatableForTest
    struct Section {
        let title: String
        let items: [PaymentLinkPaymentDetailsViewModel.Section.Item]
    }
}

extension PaymentLinkPaymentDetailsViewModel.Section {
    // sourcery: AutoEquatableForTest
    enum Item {
        case optionItem(PaymentLinkPaymentDetailsViewModel.Section.OptionItem)
        case listItem(LegacyListItemViewModel)
    }

    // sourcery: AutoEquatableForTest
    struct OptionItem {
        let option: OptionViewModel
        // sourcery: skipEquality
        let onTap: () -> Void
    }
}
