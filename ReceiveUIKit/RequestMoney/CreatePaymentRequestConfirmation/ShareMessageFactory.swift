import ReceiveKit
import TransferResources
import TWFoundation
import UserKit

// sourcery: AutoMockable
protocol ShareMessageFactory {
    func make(profile: Profile, paymentRequest: PaymentRequestV2) -> String
}

struct ShareMessageFactoryImpl: ShareMessageFactory {
    func make(
        profile: Profile,
        paymentRequest: PaymentRequestV2
    ) -> String {
        typealias Localization = L10n.PaymentRequest.Create.Confirm

        let amount = MoneyFormatter.format(
            decimal: paymentRequest.amount.value,
            withCurrencyCode: paymentRequest.amount.currency.value
        )
        let messageLines: [String?]
        if case let .business(businessProfileInfo) = profile {
            let productLine: String =
                if let productDescription = paymentRequest.description {
                    Localization.Business.Share.product(amount, productDescription)
                } else {
                    Localization.Business.Share.noProduct
                }
            messageLines = [
                productLine,
                businessProfileInfo.name,
                Localization.Business.share,
                paymentRequest.link,
            ]
        } else {
            messageLines = [
                Localization.Personal.share(amount),
                paymentRequest.link,
            ]
        }

        return messageLines.compactMap { $0 }.joined(separator: "\n")
    }
}
