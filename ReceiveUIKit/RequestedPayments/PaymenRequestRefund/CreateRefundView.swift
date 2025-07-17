import Neptune
import SwiftUI
import TransferResources
import TWFoundation

struct CreateRefundView: View {
    @ObservedObject
    private var viewModel: CreateRefundViewModel

    @Theme
    var theme

    init(viewModel: CreateRefundViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        LCEView(
            viewModel: viewModel,
            refreshAction: {
                await viewModel.fetchData()
            },
            content: view(for:)
        )
        .footer(item: viewModel.state.content) { content in
            PrimaryButton(viewModel: .init(title: L10n.PaymentRequest.Refund.Create.button, isEnabled: content.buttonEnabled, handler: {
                viewModel.continueTapped()
            }))
        }
        .task {
            await viewModel.fetchData()
        }
    }

    @ViewBuilder
    private func view(for content: CreateRefundContent) -> some View {
        VStack(alignment: .leading) {
            PlainText(L10n.PaymentRequest.Refund.Create.title)
                .textStyle(\.screenTitle)
                .padding(.bottom, theme.spacing.vertical.value32)

            MoneyInput(
                value: viewModel.moneyInputValue(),
                label: L10n.PaymentRequest.Refund.Create.Amount.title,
                information: content.moneyInputInformation,
                currency: content.refundCurrency,
                presentCurrencies: nil,
                textFieldAccessibilityLabel: L10n.PaymentRequest.Refund.Create.Amount.inputAccessibilityLabel,
                currencySelectAccessibilityLabel: ""
            )
            .sentiment(content.moneyInputSentiment)
            .padding(.bottom, theme.spacing.vertical.value32)

            TextInput(
                value: $viewModel.refundReason,
                label: L10n.PaymentRequest.Refund.Create.Reason.title,
                information: L10n.PaymentRequest.Refund.Create.Reason.info,
                optional: true
            )
        }
        .padding(.horizontal, theme.spacing.horizontal.componentDefault)
    }
}
