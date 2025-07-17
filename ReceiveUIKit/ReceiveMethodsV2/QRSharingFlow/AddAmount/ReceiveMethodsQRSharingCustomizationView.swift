import Neptune
import SwiftUI
import TransferResources
import TWFoundation
import WiseCore

struct ReceiveMethodsQRSharingCustomizationView: View {
    @ObservedObject
    private var viewModel: ReceiveMethodsQRSharingCustomizationViewModel

    @Theme
    var theme

    init(viewModel: ReceiveMethodsQRSharingCustomizationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        LCEView(
            viewModel: viewModel,
            refreshAction: {},
            content: view(for:)
        )
        .footer(item: viewModel.state.content, separatorHidden: .always) { _ in
            let v = PrimaryButton(title: L10n.Receive.Pix.Share.Customization.Action.title, handler: {
                viewModel.createTapped()
            })

            return v.padding(.horizontal, theme.spacing.horizontal.value16)
        }
    }

    @ViewBuilder
    private func view(for content: ReceiveMethodsQRSharingCustomizationContent) -> some View {
        VStack(alignment: .leading) {
            PlainText(L10n.Receive.Pix.Share.Customization.title)
                .textStyle(\.screenTitle)
                .padding(.top, theme.spacing.vertical.value16)
            PlainText(L10n.Receive.Pix.Share.Customization.subtitle)
                .textStyle(\.largeBody)
                .padding(.bottom, theme.spacing.vertical.value32)
            MoneyInput(
                value: viewModel.moneyInputValue(),
                label: L10n.Receive.Pix.Share.Customization.amount,
                information: nil,
                currency: .init(
                    code: CurrencyCode.BRL.value,
                    name: CurrencyCode.BRL.localizedCurrencyName,
                    supportsDecimals: true
                ),
                presentCurrencies: nil,
                textFieldAccessibilityLabel: L10n.Receive.Pix.Share.Customization.Amount.inputAccessibilityLabel,
                currencySelectAccessibilityLabel: ""
            )
            .sentiment(.positive)
            .padding(.bottom, theme.spacing.vertical.value16)
            TextInput(
                value: $viewModel.message,
                label: L10n.Receive.Pix.Share.Customization.note,
                information: nil,
                optional: true
            )
            .padding(.bottom, theme.spacing.vertical.value16)
        }
        .padding(.horizontal, theme.spacing.horizontal.value16)
    }
}
