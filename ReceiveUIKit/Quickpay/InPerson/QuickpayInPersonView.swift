import Combine
import Neptune
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
import TWUI
import WiseCore

struct QuickpayInPersonView: View {
    @Theme
    var theme
    @Environment(\.preferredMaxLayoutWidth)
    var preferredMaxLayoutWidth
    let componentHeight = CGFloat(60.0)

    @ObservedObject
    var viewModel: QuickpayInPersonViewModel

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
    }

    @ViewBuilder
    private func content(for content: QuickpayPersonaliseContent) -> some View {
        FooterScrollView {
            VStack(alignment: .center, spacing: theme.spacing.vertical.componentDefault) {
                if let qrCode = viewModel.qrCodeViewModel {
                    WisetagQRCodeView(viewModel: qrCode)
                }
                SwiftUIContainerView<SwitchOptionView>(
                    viewModel: .init(
                        model: .init(
                            title: L10n.Quickpay.PersonalisePage.SetAmount.label,
                            avatar: ._icon(Icons.edit.image, badge: nil)
                        ),
                        isOn: viewModel.isSetAmountToggleOn
                    ),
                    style: (),
                    configure: {
                        $0.onToggle = { isOn in
                            viewModel.setAmountToggled(isOn: isOn)
                        }
                    }
                )
                .enabled(viewModel.status != .notDiscoverable)
                .frame(height: componentHeight)
                .preferredMaxLayoutWidth(preferredMaxLayoutWidth)
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
                .enabled(viewModel.isSetAmountToggleOn)
                TextInput(
                    value: $viewModel.description,
                    formatter: nil,
                    label: L10n.Quickpay.PersonalisePage.Description.label,
                    information: nil,
                    error: viewModel.errorMessageForDescription,
                    optional: true
                )
                .enabled(viewModel.isSetAmountToggleOn)
                .onChange(of: viewModel.description) { text in
                    Task {
                        do {
                            try await Task.sleep(nanoseconds: 1000000000)
                            await viewModel.onDescriptionChange(text: text)
                        } catch {}
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
        }
        .footer {
            PrimaryButton(viewModel: .init(title: viewModel.footerTitle, handler: {
                Task {
                    await viewModel.footerTapped()
                }
            }), style: .primary)
        }
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
        .uiKitBottomSheet(item: $viewModel.confirmationSheetViewModel) { vc, model in
            vc.presentBottomSheet(
                BottomSheetViewController.makeConfirmationSheet(viewModel: model)
            )
        }
    }
}

private extension BottomSheetViewController {
    static func makeConfirmationSheet(viewModel: QuickpayConfirmationSheetViewModel) -> BottomSheetViewController {
        let imageView = UIImageView(image: viewModel.qrCodeImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 270),
            imageView.heightAnchor.constraint(equalToConstant: 270),
        ])
        var arrangedSubviews = [UIView]()
        arrangedSubviews.append(imageView)

        let titleLabel = StackLabel().with {
            $0.text = viewModel.title
            $0.setStyle(LabelStyle.smallDisplay.centered)
        }
        let businessLabel = StackLabel().with {
            $0.text = viewModel.businessName
            $0.setStyle(LabelStyle.largeBody.centered)
        }
        let vStack = UIStackView(arrangedSubviews: [titleLabel, businessLabel])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.layoutMargins = UIEdgeInsets(top: 24, left: 0, bottom: 0, right: 0)
        vStack.isLayoutMarginsRelativeArrangement = true
        arrangedSubviews.append(vStack)

        if let money = viewModel.money {
            let amountItem = LegacyStackListItemView().with {
                $0.configure(with: .init(
                    title: L10n.Quickpay.PersonalisePage.MoneyInput.label,
                    subtitle: money.value.description + " " + money.currency.value,
                    avatar: nil
                ))
            }
            arrangedSubviews.append(amountItem)
        }

        if let description = viewModel.description {
            let descriptionItem = LegacyStackListItemView().with {
                $0.configure(with: .init(
                    title: L10n.Quickpay.PersonalisePage.Description.label,
                    subtitle: description,
                    avatar: nil
                ))
            }
            arrangedSubviews.append(descriptionItem)
        }

        let linkItem = LegacyStackListItemView().with {
            $0.configure(with: .init(
                title: L10n.Quickpay.PersonalisePage.Link.label,
                subtitle: viewModel.link,
                avatar: nil
            ))
        }
        arrangedSubviews.append(linkItem)
        return BottomSheetViewController(arrangedSubviews: arrangedSubviews)
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
