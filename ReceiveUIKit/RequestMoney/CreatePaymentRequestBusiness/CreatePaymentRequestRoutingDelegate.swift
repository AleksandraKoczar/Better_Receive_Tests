import Combine
import Foundation
import ReceiveKit
import TWFoundation
import WiseCore

// sourcery: AutoMockable
protocol CreatePaymentRequestRoutingDelegate: AnyObject {
    func showCurrencySelector(
        activeCurrencies: [CurrencyCode],
        eligibleCurrencies: [CurrencyCode],
        selectedCurrency: CurrencyCode?,
        onCurrencySelected: @escaping (CurrencyCode) -> Void
    )
    func dismiss()
    func showConfirmation(paymentRequest: PaymentRequestV2)
    func showPayWithWiseEducation()
    func showPaymentMethodsSheet(
        delegate: PaymentMethodsDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        methods: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        completion: @escaping (([PaymentRequestV2PaymentMethods]) -> Void)
    )
    func showAccountDetailsFlow(
        currencyCode: CurrencyCode
    ) -> AnyPublisher<Void, Never>
    func showDynamicFormsMethodManagement(
        _ dynamicForms: [PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm],
        delegate: PaymentMethodsDelegate?
    )
    func showPaymentMethodManagementOnWeb(delegate: PaymentMethodsDelegate?)
}
