import TransferResources

enum CreatePaymentRequestPersonalValidator {
    private enum Constants {
        static let payerNameLengthLimit = 151
        static let personalMessageLengthLimit = 41
    }

    static func validPayerName(_ name: String) -> Result {
        if name.count < Constants.payerNameLengthLimit {
            return .valid
        } else {
            let lengthLimit = Constants.payerNameLengthLimit
            let reason = InvalidReason(
                description: L10n.PaymentRequest.Create.PayerInput.Error.invalid(lengthLimit)
            )
            return .invalid(reason: reason)
        }
    }

    static func validPersonalMessage(_ message: String) -> Result {
        if message.count < Constants.personalMessageLengthLimit {
            return .valid
        } else {
            let lengthLimit = Constants.personalMessageLengthLimit
            let description = L10n.PaymentRequest.Create.MessageInput.Error.invalid(lengthLimit)
            let reason = InvalidReason(description: description)
            return .invalid(reason: reason)
        }
    }
}

extension CreatePaymentRequestPersonalValidator {
    struct InvalidReason: Equatable {
        let description: String
    }

    enum Result: Equatable {
        case valid
        case invalid(reason: InvalidReason)
    }
}

extension CreatePaymentRequestPersonalValidator.InvalidReason {
    static let ignorable = Self(description: "")
}
