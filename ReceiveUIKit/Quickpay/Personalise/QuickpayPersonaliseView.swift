import Combine
import Neptune
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
import TWUI
import WiseCore

struct QuickpayPersonaliseView: View {
    @Theme
    var theme

    @ObservedObject
    var viewModel: QuickpayPersonaliseViewModel

    var body: some View {
        LCEView(
            viewModel: viewModel,
            refreshAction: {
                await viewModel.handle(.load)
            },
            content: content(for:)
        )
        .task {
            await viewModel.handle(.load)
        }
        .footer {
            PlainText(viewModel.link)
                .textStyle(\.defaultBody.centered)
                .hideWhenKeyboardIsVisible(false)
                .expandVertically()
            PrimaryButton(viewModel: .init(
                title: L10n.Quickpay.PersonalisePage.CopyLink.title,
                isEnabled: !viewModel.state.isLoading,
                handler: {
                    viewModel.copyLink()
                }
            ))
        }
    }

    @ViewBuilder
    private func content(for content: QuickpayPersonaliseContent) -> some View {
        VStack(alignment: .center, spacing: theme.spacing.vertical.componentDefault) {
            if let qrCode = viewModel.qrCodeViewModel {
                WisetagQRCodeView(viewModel: qrCode)
            }
            MoneyInput(
                value: $viewModel.amount,
                label: L10n.Quickpay.PersonalisePage.MoneyInput.label,
                information: nil,
                currency: .init(
                    code: viewModel.selectedCurrency.value,
                    name: "",
                    supportsDecimals: true
                ),
                presentCurrencies: viewModel.onChangeCurrency,
                textFieldAccessibilityLabel: "",
                currencySelectAccessibilityLabel: ""
            )
            TextInput(
                value: $viewModel.description,
                formatter: nil,
                label: L10n.Quickpay.PersonalisePage.Description.label,
                information: nil,
                error: viewModel.errorMessage,
                optional: true
            )
            .onChange(of: viewModel.description) { text in
                Task {
                    await viewModel.onDescriptionChange(text: text)
                }
            }
            .onChange(of: viewModel.amount) { _ in
                Task {
                    await viewModel.updateQRCode()
                }
            }
        }
        .padding(.horizontal, theme.spacing.horizontal.componentDefault)
        .padding(.vertical, theme.spacing.horizontal.componentDefault)
        .sheet(isPresented: $viewModel.showCurrencySelector) {
            CurrencySelectorRepresentable(
                activeCurrencies: viewModel.allCurrencies,
                selectedCurrency: viewModel.selectedCurrency,
                onCurrencySelected: {
                    viewModel.selectedCurrency = $0
                    Task {
                        await viewModel.updateQRCode()
                    }
                }
            )
        }
    }
}

private struct CurrencySelectorRepresentable: UIViewControllerRepresentable {
    let activeCurrencies: [CurrencyCode]
    let selectedCurrency: CurrencyCode?
    let onCurrencySelected: (CurrencyCode) -> Void

    func filterSearchResults(_ currencies: [CurrencyCode]) -> (_ query: String) -> CurrencyList<CurrencyCode> {
        let searchResultsFilter: ([CurrencyCode], String) -> ([CurrencyCode]) = { input, query in
            input
                .filter { $0.value.uppercased().hasPrefix(query) || $0.localizedCurrencyName.containsCaseInsensitive(query) }
        }
        return { query in
            SearchResultsCurrenciesList(filtered: searchResultsFilter(currencies, query), searchQuery: query)
        }
    }

    func makeUIViewController(context: Context) -> UIViewController {
        CurrencySelectorFactoryImpl.make(
            items: SectionedCurrenciesList(
                [
                    .init(
                        title: L10n.Convertbalance.CurrencyPicker.yourBalances,
                        currencies: activeCurrencies
                    ),
                ]
            ),
            configuration: CurrencySelectorConfiguration(selectedItem: selectedCurrency),
            searchResultsFilter: filterSearchResults(activeCurrencies),
            onSelect: onCurrencySelected,
            onDismiss: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
