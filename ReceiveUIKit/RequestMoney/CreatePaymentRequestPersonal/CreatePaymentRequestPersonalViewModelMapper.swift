import Foundation
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UserKit

// sourcery: AutoMockable
protocol CreatePaymentRequestPersonalViewModelMapper {
    func make(
        contactName: String?,
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        shouldShowNudge: Bool
    ) -> CreatePaymentRequestPersonalViewModel
}

struct CreatePaymentRequestPersonalViewModelMapperImpl: CreatePaymentRequestPersonalViewModelMapper {
    func make(
        contactName: String?,
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        shouldShowNudge: Bool
    ) -> CreatePaymentRequestPersonalViewModel {
        let currency = paymentRequestInfo.selectedCurrency
        let amount = paymentRequestInfo.value.map {
            MoneyFormatter.format($0 as NSDecimalNumber)
        }

        return CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(
                title: L10n.PaymentRequest.Create.Create.header,
                description: makeScreenSubtitle(
                    contactName: contactName
                )
            ),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: L10n.PaymentRequest.Create.MoneyInput.title,
                amount: amount,
                currencyName: currency.value,
                currencyAccessibilityName: currency.localizedCurrencyName,
                flagImage: currency.icon
            ),
            currencySelectorEnabled: isCurrencySelectorEnabled(
                for: paymentRequestInfo.eligibleBalances.eligibilities
            ),
            message: paymentRequestInfo.message,
            alert: makeAlert(paymentRequestInfo.PWWAlert),
            nudge: makeNudge(
                shouldShowNudge: shouldShowNudge
            ),
            footerButtonEnabled: paymentRequestInfo.value != nil && paymentRequestInfo.PWWAlert.isNil,
            footerButtonTitle: makeFooterButtonTitle(
                hasContact: contactName != nil
            )
        )
    }
}

// MARK: - Helpers

private extension CreatePaymentRequestPersonalViewModelMapperImpl {
    private func makeScreenSubtitle(
        contactName: String?
    ) -> String {
        if let contactName {
            L10n.PaymentRequest.Create.Personal.ToContact.subtitle(contactName)
        } else {
            L10n.PaymentRequest.Create.Personal.subtitle
        }
    }

    private func makeFooterButtonTitle(
        hasContact: Bool
    ) -> String {
        if hasContact {
            L10n.PaymentRequest.Create.Footer.Request.button
        } else {
            L10n.PaymentRequest.Create.Footer.Personal.button
        }
    }

    private func isCurrencySelectorEnabled(
        for eligibleBalances: [PaymentRequestEligibleBalances.Eligibility]
    ) -> Bool {
        eligibleBalances.map(\.currency).uniqued().count > 1
    }

    private func makeNudge(
        shouldShowNudge: Bool
    ) -> CreatePaymentRequestPersonalViewModel.Nudge? {
        guard shouldShowNudge else {
            return nil
        }
        return CreatePaymentRequestPersonalViewModel.Nudge(
            title: L10n.PaymentRequest.Create.Nudge.title,
            icon: .wallet,
            ctaTitle: L10n.PaymentRequest.Create.Nudge.ctaTitle
        )
    }

    private func makeAlert(
        _ alert: PWWAlert?
    ) -> CreatePaymentRequestPersonalViewModel.Alert? {
        guard let alert else {
            return nil
        }

        switch alert.type {
        case .neutral:
            return CreatePaymentRequestPersonalViewModel.Alert(
                style: .neutral,
                viewModel: Neptune.InlineAlertViewModel(
                    message: alert.message
                )
            )
        case .warning:
            return CreatePaymentRequestPersonalViewModel.Alert(
                style: .warning,
                viewModel: Neptune.InlineAlertViewModel(
                    message: alert.message,
                    action: alert.action
                )
            )
        }
    }
}
