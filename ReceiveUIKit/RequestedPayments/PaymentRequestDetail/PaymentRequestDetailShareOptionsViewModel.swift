import Neptune

// sourcery: AutoEquatableForTest
struct PaymentRequestDetailShareOptionsViewModel {
    let paymentLink: String
    let options: [OptionViewModel]
    // sourcery: skipEquality
    let handler: (Int, OptionViewModel) -> Void
}
