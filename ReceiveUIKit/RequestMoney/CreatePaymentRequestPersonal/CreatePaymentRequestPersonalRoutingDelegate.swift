import Combine
import Foundation
import ReceiveKit
import TWFoundation
import WiseCore

// sourcery: AutoMockable
protocol CreatePaymentRequestPersonalRoutingDelegate: AnyObject {
    func showCurrencySelector(
        activeCurrencies: [CurrencyCode],
        eligibleCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: @escaping (CurrencyCode) -> Void
    )
    func dismiss()
    func showConfirmation(paymentRequest: PaymentRequestV2)
    func showRequestFromContactsSuccess(
        contact: RequestMoneyContact,
        paymentRequest: PaymentRequestV2
    )
    func showPayWithWiseEducation()
    func showAccountDetailsFlow(
        currencyCode: CurrencyCode
    ) -> AnyPublisher<Void, Never>
    func handleDynamicForms(
        forms: [PaymentMethodAvailability.DynamicForm],
        completionHandler: @escaping () -> Void
    )
}
