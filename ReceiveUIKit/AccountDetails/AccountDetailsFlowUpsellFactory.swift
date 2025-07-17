import AnalyticsKit
import Foundation
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol AccountDetailsFlowUpsellFactory: AccountDetailsFlowPixUpsellFactory {
    func make(
        currencies: [CurrencyCode],
        feeAmount: Money?,
        profileType: ProfileType,
        infoHandler: @escaping (() -> Void),
        continueHandler: @escaping (() -> Void)
    ) -> UpsellViewController

    func upsellSheetModel(
        for currencies: [CurrencyCode],
        feeAmount: Money?,
        buttonAction: @escaping () -> Void
    ) -> InfoSheetViewModel

    func requestMoneyUpsell(
        continueHandler: @escaping (() -> Void)
    ) -> UpsellViewController
}

// sourcery: AutoMockable
public protocol AccountDetailsFlowPixUpsellFactory {
    func upsellForPix(
        continueHandler: @escaping (() -> Void)
    ) -> UpsellViewController
}

public struct AccountDetailsFlowUpsellFactoryImpl: AccountDetailsFlowUpsellFactory {
    public init() {}

    public func make(
        currencies: [CurrencyCode],
        feeAmount: Money?,
        profileType: ProfileType,
        infoHandler: @escaping (() -> Void),
        continueHandler: @escaping (() -> Void)
    ) -> UpsellViewController {
        if let amount = feeAmount,
           profileType == .personal {
            upsellWithFee(
                currenciesCount: currencies.count,
                feeAmount: amount,
                infoHandler: infoHandler,
                continueHandler: continueHandler
            )
        } else {
            upsellWithoutFee(
                currenciesCount: currencies.count,
                infoHandler: infoHandler,
                continueHandler: continueHandler
            )
        }
    }

    public func upsellSheetModel(
        for currencies: [CurrencyCode],
        feeAmount: Money?,
        buttonAction: @escaping () -> Void
    ) -> InfoSheetViewModel {
        var currenciesString = ""
        currencies.forEach { currency in
            currenciesString.append(" • \(currency.value) - \(currency.localizedCurrencyName)\(String.lineSeparator)")
        }

        let title = L10n.Account.Details.Personal.Upsell.Info.title
        let message = L10n.Account.Details.Personal.Upsell.Info.description(currenciesString)
        let button = L10n.Account.Details.Personal.Upsell.Info.button

        return InfoSheetViewModel(
            title: title,
            info: .markup(message),
            primaryAction: .init(title: button, handler: buttonAction)
        )
    }

    public func requestMoneyUpsell(
        continueHandler: @escaping (() -> Void)
    ) -> UpsellViewController {
        UpsellViewController(
            viewModel: UpsellViewModel(
                headerModel: LargeTitleViewModel(
                    title: L10n.AccountDetails.RequestMoney.Upsell.title,
                    description: L10n.AccountDetails.RequestMoney.Upsell.Title.description
                ),
                imageView: IllustrationView(
                    asset: .image(
                        Neptune.Illustrations.receive.image
                    )
                ),
                items: [
                    SummaryViewModel(
                        title: L10n.AccountDetails.RequestMoney.Upsell.Summaries.GetPaid.title,
                        icon: Icons.coins.image
                    ),
                    SummaryViewModel(
                        title: L10n.AccountDetails.RequestMoney.Upsell.Summaries.GetAccountDetails.title,
                        icon: Icons.receive.image
                    ),
                    SummaryViewModel(
                        title: L10n.AccountDetails.RequestMoney.Upsell.Summaries.ShareDetails.title,
                        icon: Icons.link.image
                    ),
                    SummaryViewModel(
                        title: L10n.AccountDetails.RequestMoney.Upsell.Summaries.MoneyGoesTo.title,
                        icon: Icons.wallet.image
                    ),
                ],
                footerModel: UpsellViewModel.FooterModel(
                    primaryAction: Action(
                        title: L10n.AccountDetails.RequestMoney.Upsell.Action.title,
                        handler: continueHandler
                    )
                )
            )
        )
    }
}

extension AccountDetailsFlowUpsellFactoryImpl: AccountDetailsFlowPixUpsellFactory {
    public func upsellForPix(
        continueHandler: @escaping (() -> Void)
    ) -> UpsellViewController {
        UpsellViewController(
            viewModel: UpsellViewModel(
                headerModel: LargeTitleViewModel(
                    title: L10n.AccountDetails.Pix.Upsell.title
                ),
                imageView: IllustrationView(
                    asset: .image(
                        ReceiveKitImages.brazilPix
                    )
                ),
                sectionHeader: SectionHeaderViewModel(
                    title: L10n.AccountDetails.Pix.Upsell.description
                ),
                items: [
                    SummaryViewModel(
                        title: L10n.AccountDetails.Pix.Upsell.Summaries.AddMoney.title,
                        icon: Icons.lightningBolt.image
                    ),
                    SummaryViewModel(
                        title: L10n.AccountDetails.Pix.Upsell.Summaries.Convert.title,
                        icon: Icons.multiCurrency.image
                    ),
                    SummaryViewModel(
                        title: L10n.AccountDetails.Pix.Upsell.Summaries.SendReceiveWithdraw.title,
                        icon: Icons.clock.image
                    ),
                    SummaryViewModel(
                        title: L10n.AccountDetails.Pix.Upsell.Summaries.QrCode.title,
                        icon: Icons.qrCode.image
                    ),
                ],
                footerModel: UpsellViewModel.FooterModel(
                    primaryAction: Action(
                        title: L10n.AccountDetails.RequestMoney.Upsell.Action.title,
                        handler: continueHandler
                    )
                )
            )
        )
    }
}

// MARK: - Helpers

private extension AccountDetailsFlowUpsellFactory {
    func title(fee: Money) -> String {
        L10n.Account.Details.Personal.Upsell.With.Charge.title(
            MoneyFormatter.format(fee)
        )
    }

    func upsellWithoutFee(
        currenciesCount: Int,
        infoHandler: @escaping (() -> Void),
        continueHandler: @escaping (() -> Void)
    ) -> UpsellViewController {
        UpsellViewController(
            viewModel: UpsellViewModel(
                headerModel: LargeTitleViewModel(
                    title: L10n.Account.Details.Personal.Upsell.title
                ),
                imageView: IllustrationView(
                    asset: .image(
                        Neptune.Illustrations.documents.image
                    )
                ),
                items: [
                    SummaryViewModel(
                        title: L10n.Account.Details.Personal.Upsell.getpaid(currenciesCount),
                        icon: Icons.receive.image,
                        info: infoHandler
                    ),
                    SummaryViewModel(
                        title: L10n.Account.Details.Personal.Upsell.salary,
                        icon: Icons.payIn.image
                    ),
                    SummaryViewModel(
                        title: L10n.Account.Details.Personal.Upsell.directdebit,
                        icon: Icons.directDebits.image
                    ),
                    SummaryViewModel(
                        title: L10n.Account.Details.Personal.Upsell.ecommerce,
                        icon: Icons.shoppingBag.image
                    ),
                ],
                footerModel: .init(primaryAction: .init(
                    title: L10n.Account.Details.Personal.Upsell.button,
                    handler: continueHandler
                ))
            )
        )
    }

    func upsellWithFee(
        currenciesCount: Int,
        feeAmount: Money,
        infoHandler: @escaping (() -> Void),
        continueHandler: @escaping (() -> Void)
    ) -> UpsellViewController {
        UpsellViewController(
            viewModel: UpsellViewModel(
                headerModel: LargeTitleViewModel(
                    title: title(fee: feeAmount)
                ),
                imageView: IllustrationView(
                    asset: .image(
                        Neptune.Illustrations.documents.image
                    )
                ),
                items: [
                    SummaryViewModel(
                        title: L10n.Account.Details.Personal.Upsell.With.Charge.fee,
                        icon: Icons.money.image
                    ),
                    SummaryViewModel(
                        title: L10n.Account.Details.Personal.Upsell.getpaid(currenciesCount),
                        icon: Icons.receive.image,
                        info: infoHandler
                    ),
                    SummaryViewModel(
                        title: L10n.Account.Details.Personal.Upsell.salary,
                        icon: Icons.payIn.image
                    ),
                    SummaryViewModel(
                        title: L10n.Account.Details.Personal.Upsell.directdebit,
                        icon: Icons.directDebits.image
                    ),
                    SummaryViewModel(
                        title: L10n.Account.Details.Personal.Upsell.ecommerce,
                        icon: Icons.shoppingBag.image
                    ),
                ],
                footerModel: .init(primaryAction: .init(
                    title: L10n.Account.Details.Personal.Upsell.button,
                    handler: continueHandler
                ))
            )
        )
    }
}

public struct AccountDetailsUpsellPersonalAnalyticsScreen: AnalyticsScreenItem {
    public init() {}
    public func screenDescriptors() -> [AnalyticsScreenDescriptor] {
        [MixpanelScreen(name: "Bank Details Flow - Personal Upsell")]
    }
}
