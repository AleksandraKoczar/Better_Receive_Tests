import WiseCore

// sourcery: Buildable
struct Refund: Equatable {
    // sourcery: Buildable
    struct PayerData: Equatable {
        let name: String?
        let email: String?
    }

    let amount: Money
    let reason: String?
    let payerData: PayerData?
}
