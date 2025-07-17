import Neptune

// sourcery: AutoEquatableForTest
struct PaymentDetailsViewModel {
    let title: String
    let alert: PaymentDetailsViewModel.Alert?
    let items: [PaymentDetailsViewModel.Item]
    let footerAction: Action?
}

extension PaymentDetailsViewModel {
    // sourcery: AutoEquatableForTest
    struct Alert {
        let viewModel: InlineAlertViewModel
        let style: InlineAlertStyle
    }

    // sourcery: AutoEquatableForTest
    enum Item {
        case listItem(ReceiptItemViewModel)
        case separator
    }
}
