import Foundation
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UserKit

// sourcery: AutoMockable
protocol CreatePaymentRequestViewModelMapper {
    func make(
        shouldShowPaymentLimitsCheckbox: Bool,
        isLimitPaymentsSelected: Bool,
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        paymentMethodsOption: CreatePaymentRequestViewModel.PaymentMethodsOption,
        nudge: NudgeViewModel?
    ) -> CreatePaymentRequestViewModel
}

struct CreatePaymentRequestViewModelMapperImpl: CreatePaymentRequestViewModelMapper {
    func make(
        shouldShowPaymentLimitsCheckbox: Bool,
        isLimitPaymentsSelected: Bool,
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        paymentMethodsOption: CreatePaymentRequestViewModel.PaymentMethodsOption,
        nudge: NudgeViewModel?
    ) -> CreatePaymentRequestViewModel {
        let currency = paymentRequestInfo.selectedCurrency
        let amount = paymentRequestInfo.value.map {
            MoneyFormatter.format($0 as NSDecimalNumber)
        }
        let title = L10n.PaymentRequest.Create.Business.title
        let footerButtonTitle = L10n.PaymentRequest.Create.PaymentMethodsEnabled.FooterButton.title

        return CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(
                title: title
            ),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: L10n.PaymentRequest.Create.MoneyInput.title,
                amount: amount,
                currencyName: currency.value,
                currencyAccessibilityName: currency.localizedCurrencyName,
                flagImage: currency.icon
            ),
            currencySelectorEnabled: isCurrencySelectorEnabled(for: paymentRequestInfo.eligibleBalances.balances),
            shouldShowPaymentLimitsCheckbox: shouldShowPaymentLimitsCheckbox,
            isLimitPaymentsSelected: isLimitPaymentsSelected,
            productDescription: paymentRequestInfo.productDescription,
            paymentMethodsOption: paymentMethodsOption,
            nudge: nudge,
            footerButtonEnabled: paymentRequestInfo.value != nil,
            footerButtonTitle: footerButtonTitle
        )
    }
}

// MARK: - Helpers

private extension CreatePaymentRequestViewModelMapperImpl {
    private func isCurrencySelectorEnabled(
        for eligibleBalances: [PaymentRequestEligibleBalances.Balance]
    ) -> Bool {
        eligibleBalances.map(\.currency).uniqued().count > 1
    }
}
