import Neptune

// sourcery: AutoEquatableForTest
struct PaymentRequestsListRadioOptionsViewModel {
    let title: String
    let options: [RadioOptionViewModel]
    let dismissOnSelection: Bool
    let action: PaymentRequestsListRadioOptionsViewModel.Action
    // sourcery: skipEquality
    let handler: (Int, RadioOptionViewModel) -> Void
}

extension PaymentRequestsListRadioOptionsViewModel {
    // sourcery: AutoEquatableForTest
    struct Action {
        let title: String
        // sourcery: skipEquality
        let style: any LargeButtonAppearance
        // sourcery: skipEquality
        let handler: () -> Void
    }
}
