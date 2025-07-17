import Foundation
import Neptune

// sourcery: AutoEquatableForTest
struct PaymentRequestDetailViewModel {
    let header: PaymentRequestDetailViewModel.HeaderViewModel
    let sections: [PaymentRequestDetailViewModel.SectionViewModel]
    let footer: PaymentRequestDetailViewModel.FooterViewModel?
}

extension PaymentRequestDetailViewModel {
    // sourcery: AutoEquatableForTest
    struct HeaderViewModel {
        let icon: AvatarViewModel
        let iconStyle: AvatarViewStyle
        let title: String
        let subtitle: String
    }

    // sourcery: AutoEquatableForTest
    struct SectionViewModel {
        let header: SectionHeaderViewModel
        let items: [SectionViewModel.ItemViewModel]
    }

    // sourcery: AutoEquatableForTest
    struct FooterViewModel {
        let primaryAction: Neptune.Action
        let secondaryAction: Neptune.Action?
        let configuration: Configuration

        enum Configuration {
            case positiveOnly
            case negativeOnly
            case positiveAndNegative
        }
    }
}

extension PaymentRequestDetailViewModel.SectionViewModel {
    // sourcery: AutoEquatableForTest
    enum ItemViewModel {
        case listItem(Neptune.LegacyListItemViewModel)
        case optionItem(PaymentRequestDetailViewModel.SectionViewModel.OptionViewModel)
    }

    // sourcery: AutoEquatableForTest
    struct OptionViewModel {
        let option: Neptune.OptionViewModel
        // sourcery: skipEquality
        let onTap: () -> Void
    }
}
