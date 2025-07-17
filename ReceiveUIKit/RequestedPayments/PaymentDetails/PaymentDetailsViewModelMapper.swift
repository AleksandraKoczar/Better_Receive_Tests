import LoggingKit
import Neptune
import ReceiveKit
import TransferResources

// sourcery: AutoMockable
protocol PaymentDetailsViewModelMapperDelegate: AnyObject {
    func isRefundEnabled() -> Bool
    func proceedRefund(paymentId: String)
    func showRefundDisabled(
        title: String,
        message: String,
        illustrationUrn: String?
    )
}

enum PaymentDetailsViewModelMapper {
    static func make(
        from paymentDetails: PaymentDetails,
        delegate: PaymentDetailsViewModelMapperDelegate
    ) -> PaymentDetailsViewModel {
        let alert = paymentDetails.alert.map(makePaymentDetailsViewModelAlert(from:))
        let items = paymentDetails.items.compactMap(makePaymentDetailsViewModelItem(from:))
        let action = paymentDetails.actions.first.flatMap {
            makePaymentDetailsViewModelAction(
                from: $0,
                delegate: delegate
            )
        }
        return PaymentDetailsViewModel(
            title: paymentDetails.title,
            alert: alert,
            items: items,
            footerAction: action
        )
    }

    // MARK: - Helpers

    private static func makeAlertStyle(from state: PaymentDetails.Alert.State) -> InlineAlertStyle {
        switch state {
        case .warning:
            .warning
        case .positive:
            .positive
        case .negative:
            .negative
        case .neutral:
            .neutral
        }
    }

    private static func makePaymentDetailsViewModelAlert(from alert: PaymentDetails.Alert) -> PaymentDetailsViewModel.Alert {
        let style = makeAlertStyle(from: alert.state)
        return PaymentDetailsViewModel.Alert(
            viewModel: InlineAlertViewModel(message: alert.content),
            style: style
        )
    }

    private static func makePaymentDetailsViewModelItem(from item: PaymentRequestDetailsSection.Item) -> PaymentDetailsViewModel.Item? {
        switch item {
        case let .listItem(label, value, _):
            .listItem(ReceiptItemViewModel(title: label, value: value))
        case .divider:
            .separator
        case .optionItem:
            nil
        }
    }

    private static func makePaymentDetailsViewModelAction(
        from action: PaymentDetails.Action,
        delegate: PaymentDetailsViewModelMapperDelegate
    ) -> Action? {
        let actionTitle = L10n.PaymentRequest.PaymentDetail.Action.Title.refundPayment
        switch action {
        case let .refund(paymentId):
            guard delegate.isRefundEnabled() else {
                return nil
            }
            return Action(
                title: actionTitle,
                handler: { [weak delegate] in
                    delegate?.proceedRefund(paymentId: paymentId)
                }
            )
        case let .refundDisabled(title, message, illustrationUrn):
            return Action(
                title: actionTitle,
                handler: { [weak delegate] in
                    delegate?.showRefundDisabled(
                        title: title,
                        message: message,
                        illustrationUrn: illustrationUrn
                    )
                }
            )
        }
    }
}
