import BalanceKit
import Combine
import ContactsKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PayWithWiseViewModelFactory: DynamicTypeAccessible {
    func make(
        source: PayWithWiseFlow.PaymentInitializationSource,
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [AcquiringPaymentMethodType],
        profile: Profile,
        paymentRequestLookup: PaymentRequestLookup,
        avatar: ContactsKit.AvatarModel?,
        quote: PayWithWiseQuote?,
        selectedBalance: Balance?,
        selectProfileAction: @escaping (() -> Void),
        selectBalanceAction: @escaping (() -> Void),
        firstButtonAction: @escaping (() -> Void),
        secondButtonAction: @escaping (() -> Void)
    ) -> PayWithWiseViewModel

    func makeQuickpay(
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        profile: Profile,
        businessInfo: ContactSearch,
        quickpayLookup: QuickpayAcquiringPayment,
        quote: PayWithWiseQuote?,
        selectedBalance: Balance?,
        selectProfileAction: @escaping (() -> Void),
        selectBalanceAction: @escaping (() -> Void),
        firstButtonAction: @escaping (() -> Void),
        secondButtonAction: @escaping (() -> Void)
    ) -> PayWithWiseViewModel

    func makeBalanceOptionsContainer(
        fundableBalances: [Balance],
        balances: [Balance]
    ) -> PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer

    func makeBalanceSections(
        container: PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer
    ) -> [PayWithWiseBalanceSelectorViewModel.Section]

    func makeEmptyStateViewModel(
        image: UIImage,
        title: String,
        message: String,
        buttonAction: Action
    ) -> PayWithWiseViewModel

    func makeAlertViewModel(
        message: String,
        style: InlineAlertStyle,
        action: Action?
    ) -> PayWithWiseViewModel.Alert

    static func makeItems(
        paymentRequestLookup: PaymentRequestLookup
    ) -> [LegacyListItemViewModel]

    static func makeItemsForQuickpay(
        quickpayLookup: QuickpayAcquiringPayment
    ) -> [LegacyListItemViewModel]

    static func makeRejectConfirmationModel(
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void
    ) -> InfoSheetViewModel

    func makeHeaderViewModel(
        title: String,
        recipientName: String,
        description: String?,
        avatar: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> PayWithWiseHeaderView.ViewModel
}

struct PayWithWiseViewModelFactoryImpl {
    // sourcery: Buildable
    struct BalanceOption {
        let id: BalanceId
        let viewModel: OptionViewModel
    }

    // sourcery: Buildable
    struct BalanceOptionsContainer {
        let fundables: [PayWithWiseViewModelFactoryImpl.BalanceOption]
        let nonFundables: [PayWithWiseViewModelFactoryImpl.BalanceOption]
    }

    private let balanceFormatter: BalanceFormatter
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.timeZone = TimeZone.utc
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.calendar.timeZone = TimeZone.utc
        formatter.calendar.locale = Locale.posix
        return formatter
    }()

    init(balanceFormatter: BalanceFormatter) {
        self.balanceFormatter = balanceFormatter
    }
}

extension PayWithWiseViewModelFactoryImpl: PayWithWiseViewModelFactory {
    func makeQuickpay(
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        profile: UserKit.Profile,
        businessInfo: ContactSearch,
        quickpayLookup: ReceiveKit.QuickpayAcquiringPayment,
        quote: ReceiveKit.PayWithWiseQuote?,
        selectedBalance: BalanceKit.Balance?,
        selectProfileAction: @escaping (() -> Void),
        selectBalanceAction: @escaping (() -> Void),
        firstButtonAction: @escaping (() -> Void),
        secondButtonAction: @escaping (() -> Void)
    ) -> PayWithWiseViewModel {
        let formattedRequestAmount = MoneyFormatter.format(quickpayLookup.amount)

        let formattedPaymentAmount = quote != nil
            ? MoneyFormatter.format(quote!.sourceAmount)
            : formattedRequestAmount

        let breakdownItems: [BreakdownRowModel] =
            quote != nil
                ? Self.makeBreakdownItemsForCrossCurrency(
                    quote: quote!,
                    formattedRequestAmount: formattedRequestAmount,
                    formattedPaymentAmount: formattedPaymentAmount
                )
                : []

        let supportsPayWithWise = supportedPaymentMethods.contains(where: { $0.available == true && $0.type == .payWithWise })

        let footer = Self.makeFooter(
            hasAlert: inlineAlert.isNonNil,
            isRequestFromContact: false,
            formattedPaymentAmount: formattedPaymentAmount,
            firstButtonAction: firstButtonAction,
            secondButtonAction: secondButtonAction
        )

        let header = makeHeaderViewModel(
            title: formattedRequestAmount,
            recipientName: businessInfo.contact.title,
            description: quickpayLookup.description,
            avatar: businessInfo.contact.avatarPublisher.avatarPublisher
        )

        let paymentSection = Self.makePaymentSection(
            balance: selectedBalance,
            selectBalanceAction: selectBalanceAction,
            balanceFormatter: balanceFormatter,
            supportsProfileChange: supportsProfileChange,
            supportsPayWithWise: supportsPayWithWise,
            selectProfileAction: selectProfileAction,
            profile: profile
        )

        return PayWithWiseViewModel.loaded(PayWithWiseViewModel.Loaded(
            shouldHideDetailsButton: false,
            header: header,
            paymentSection: paymentSection,
            breakdownItems: breakdownItems,
            inlineAlert: inlineAlert,
            footer: footer
        ))
    }

    func make(
        source: PayWithWiseFlow.PaymentInitializationSource,
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [AcquiringPaymentMethodType],
        profile: Profile,
        paymentRequestLookup: PaymentRequestLookup,
        avatar: AvatarModel?,
        quote: PayWithWiseQuote?,
        selectedBalance: Balance?,
        selectProfileAction: @escaping (() -> Void),
        selectBalanceAction: @escaping (() -> Void),
        firstButtonAction: @escaping (() -> Void),
        secondButtonAction: @escaping (() -> Void)
    ) -> PayWithWiseViewModel {
        let formattedRequestAmount = MoneyFormatter.format(paymentRequestLookup.amount)

        let formattedPaymentAmount = quote != nil
            ? MoneyFormatter.format(quote!.sourceAmount)
            : formattedRequestAmount

        let breakdownItems: [BreakdownRowModel] = quote != nil
            ? Self.makeBreakdownItemsForCrossCurrency(
                quote: quote!,
                formattedRequestAmount: formattedRequestAmount,
                formattedPaymentAmount: formattedPaymentAmount
            )
            : []

        let supportsPayWithWise = supportedPaymentMethods.contains(.payWithWise)
        let footer = Self.makeFooter(
            hasAlert: inlineAlert != nil,
            isRequestFromContact: source.isRequestFromContact,
            formattedPaymentAmount: formattedPaymentAmount,
            firstButtonAction: firstButtonAction,
            secondButtonAction: secondButtonAction
        )

        let avatarPublisher: AnyPublisher<AvatarModel, Never> = avatar.map {
            Just($0).eraseToAnyPublisher()
        } ?? Just(.initials(.init(name: paymentRequestLookup.requester.fullName), badge: nil)).eraseToAnyPublisher()

        let header = makeHeaderViewModel(
            title: formattedRequestAmount,
            recipientName: paymentRequestLookup.requester.fullName,
            description: paymentRequestLookup.message,
            avatar: avatarPublisher
        )

        let paymentSection = Self.makePaymentSection(
            balance: selectedBalance,
            selectBalanceAction: selectBalanceAction,
            balanceFormatter: balanceFormatter,
            supportsProfileChange: supportsProfileChange,
            supportsPayWithWise: supportsPayWithWise,
            selectProfileAction: selectProfileAction,
            profile: profile
        )

        return PayWithWiseViewModel.loaded(PayWithWiseViewModel.Loaded(
            shouldHideDetailsButton: source.isRequestFromContact,
            header: header,
            paymentSection: paymentSection,
            breakdownItems: breakdownItems,
            inlineAlert: inlineAlert,
            footer: footer
        ))
    }

    func makeHeaderViewModel(
        title: String,
        recipientName: String,
        description: String?,
        avatar: AnyPublisher<AvatarModel, Never>
    ) -> PayWithWiseHeaderView.ViewModel {
        PayWithWiseHeaderView.ViewModel(
            title: .init(title: title),
            recipientName: recipientName,
            description: description,
            avatarImage: avatar.map { AvatarViewModel(avatar: $0) }.eraseToAnyPublisher()
        )
    }

    func makeBalanceOptionsContainer(
        fundableBalances: [Balance],
        balances: [Balance]
    ) -> BalanceOptionsContainer {
        let fundableBalanceOptions = makeBalanceOptions(
            balances: fundableBalances,
            isEnabled: true
        )
        let fundableBalancesDictionary: [BalanceId: Balance] = fundableBalances
            .reduce(into: [:]) { result, balance in
                result[balance.id] = balance
            }

        let nonFundableBalances = balances.filter {
            fundableBalancesDictionary[$0.id] == nil
        }

        let nonFundableBalanceOptions = makeBalanceOptions(
            balances: nonFundableBalances,
            isEnabled: false
        )

        return BalanceOptionsContainer(
            fundables: fundableBalanceOptions,
            nonFundables: nonFundableBalanceOptions
        )
    }

    func makeBalanceSections(
        container: BalanceOptionsContainer
    ) -> [PayWithWiseBalanceSelectorViewModel.Section] {
        var sections: [PayWithWiseBalanceSelectorViewModel.Section] = []
        if container.fundables.isNonEmpty {
            sections.append(
                PayWithWiseBalanceSelectorViewModel.Section(
                    headerViewModel: SectionHeaderViewModel(
                        title: L10n.PayWithWise.Payment.BalanceSelector.Section.AvailableBalances.title
                    ),
                    options: container.fundables.map {
                        $0.viewModel
                    }
                )
            )
        }

        if container.nonFundables.isNonEmpty {
            sections.append(
                PayWithWiseBalanceSelectorViewModel.Section(
                    headerViewModel: SectionHeaderViewModel(
                        title: L10n.PayWithWise.Payment.BalanceSelector.Section.UnavailableBalances.title
                    ),
                    options: container.nonFundables.map {
                        $0.viewModel
                    }
                )
            )
        }

        return sections
    }

    func makeEmptyStateViewModel(
        image: UIImage,
        title: String,
        message: String,
        buttonAction: Action
    ) -> PayWithWiseViewModel {
        PayWithWiseViewModel.empty(
            PayWithWiseViewModel.Empty(
                image: image,
                title: title,
                message: message,
                buttonAction: buttonAction
            )
        )
    }

    func makeAlertViewModel(
        message: String,
        style: InlineAlertStyle,
        action: Action?
    ) -> PayWithWiseViewModel.Alert {
        .init(
            viewModel: InlineAlertViewModel(
                message: .plain(message),
                action: action.map {
                    .action($0)
                }
            ),
            style: style
        )
    }

    static func makeItemsForQuickpay(quickpayLookup: QuickpayAcquiringPayment) -> [LegacyListItemViewModel] {
        var items: [LegacyListItemViewModel] = [
            LegacyListItemViewModel(
                title: L10n.PayWithWise.Payer.Info.Screen.Item.amount,
                subtitle: MoneyFormatter.format(quickpayLookup.amount)
            ),
        ]

        if let description = quickpayLookup.description,
           description.isNonEmpty {
            items.append(
                LegacyListItemViewModel(
                    title: L10n.PayWithWise.Payer.Info.Screen.Item.Payment.description,
                    subtitle: description
                )
            )
        }

        return items
    }

    static func makeItems(paymentRequestLookup: PaymentRequestLookup) -> [LegacyListItemViewModel] {
        var items: [LegacyListItemViewModel] = [
            LegacyListItemViewModel(
                title: L10n.PayWithWise.Payer.Info.Screen.Item.amount,
                subtitle: MoneyFormatter.format(paymentRequestLookup.amount)
            ),
        ]
        if let description = paymentRequestLookup.description,
           description.isNonEmpty {
            items.append(
                LegacyListItemViewModel(
                    title: L10n.PayWithWise.Payer.Info.Screen.Item.Payment.description,
                    subtitle: description
                )
            )
        }

        if let dueAt = paymentRequestLookup.dueAt {
            items.append(
                LegacyListItemViewModel(
                    title: L10n.PayWithWise.Payer.Info.Screen.Item.Payment.dueBy,
                    subtitle: dateFormatter.string(
                        from: dueAt
                    )
                )
            )
        }

        if let expiryAt = paymentRequestLookup.expiryAt {
            items.append(
                LegacyListItemViewModel(
                    title: L10n.PayWithWise.Payer.Info.Screen.Item.Payment.expires,
                    subtitle: dateFormatter.string(
                        from: expiryAt
                    )
                )
            )
        }

        if let message = paymentRequestLookup.message {
            items.append(
                LegacyListItemViewModel(
                    title: L10n.PayWithWise.Payer.Info.Screen.Item.Payment.message,
                    subtitle: message
                )
            )
        }

        if let reference = paymentRequestLookup.reference {
            items.append(
                LegacyListItemViewModel(
                    title: L10n.PayWithWise.Payer.Info.Screen.Item.Payment.reference,
                    subtitle: reference
                )
            )
        }

        return items
    }

    static func makeRejectConfirmationModel(
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void
    ) -> InfoSheetViewModel {
        InfoSheetViewModel(
            title: L10n.PayWithWise.Payment.RejectRequest.BottomSheet.title,
            message: L10n.PayWithWise.Payment.RejectRequest.BottomSheet.message,
            confirmAction: .init(
                title: L10n.PayWithWise.Payment.RejectRequest.BottomSheet.Confirm.title,
                handler: confirmAction
            ),
            cancelAction: .init(
                title: L10n.PayWithWise.Payment.RejectRequest.BottomSheet.Cancel.title,
                handler: cancelAction
            )
        )
    }
}

// MARK: - Helpers

private extension PayWithWiseViewModelFactoryImpl {
    func makeBalanceOptions(
        balances: [Balance],
        isEnabled: Bool
    ) -> [BalanceOption] {
        balances.map { balance in
            let viewModel = OptionViewModel(
                title: balance.currency.localizedCurrencyName,
                subtitle: balanceFormatter.formatAmountWithCurrencyCode(
                    balance.availableAmount,
                    currencyCode: balance.currency.value
                ),
                leadingView: .avatar(
                    .image(
                        balance.currency.squareIcon
                    )
                ),
                isEnabled: isEnabled
            )
            return BalanceOption(
                id: balance.id,
                viewModel: viewModel
            )
        }
    }

    static func makePaymentSectionProfileOption(
        supportsProfileChange: Bool,
        supportsPayWithWise: Bool,
        selectProfileAction: @escaping (() -> Void),
        profile: Profile
    ) -> PayWithWiseViewModel.Section.SectionOption? {
        guard supportsProfileChange,
              supportsPayWithWise else {
            return nil
        }

        let accountType = Self.makeAccountType(
            profileType: profile.type
        )
        let displayName = ProfileLocaleDisplayName(
            profile: profile,
            style: .full
        ).name

        let avatar = Self.makeAvatar(
            profile: profile,
            displayName: displayName
        )

        return PayWithWiseViewModel.Section.SectionOption(
            option: OptionViewModel(
                title: displayName,
                subtitle: accountType,
                avatar: avatar
            ),
            action: selectProfileAction
        )
    }

    static func makePaymentSectionBalanceOption(
        balance: Balance?,
        selectBalanceAction: @escaping (() -> Void),
        balanceFormatter: BalanceFormatter
    ) -> PayWithWiseViewModel.Section.SectionOption? {
        guard let balance else {
            return nil
        }

        let balanceOptionModel = {
            let balanceAmount = balanceFormatter.formatAmountWithCurrencyCode(
                balance.availableAmount,
                currencyCode: balance.currency.value
            )

            let avatarViewModel: AvatarViewModel? = .image(balance.currency.squareIcon)
            return OptionViewModel(
                title: L10n.PayWithWise.Payment.Balance.Option.title(balanceAmount),
                subtitle: balance.currency.localizedCurrencyName,
                leadingView: avatarViewModel.map {
                    .avatar($0)
                }
            )
        }()

        return PayWithWiseViewModel.Section.SectionOption(option: balanceOptionModel, action: selectBalanceAction)
    }

    static func makePaymentSection(
        balance: Balance?,
        selectBalanceAction: @escaping (() -> Void),
        balanceFormatter: BalanceFormatter,
        supportsProfileChange: Bool,
        supportsPayWithWise: Bool,
        selectProfileAction: @escaping (() -> Void),
        profile: Profile
    ) -> PayWithWiseViewModel.Section? {
        let profileOption = Self.makePaymentSectionProfileOption(
            supportsProfileChange: supportsProfileChange,
            supportsPayWithWise: supportsPayWithWise,
            selectProfileAction: selectProfileAction,
            profile: profile
        )
        let balanceOption = Self.makePaymentSectionBalanceOption(
            balance: balance,
            selectBalanceAction: selectBalanceAction,
            balanceFormatter: balanceFormatter
        )

        let options = [profileOption, balanceOption].compactMap { $0 }

        return PayWithWiseViewModel.Section(
            header: .init(title: L10n.PayWithWise.PaymentOptionHeader.Section.title),
            sectionOptions: options
        )
    }

    static func makeFooter(
        hasAlert: Bool,
        isRequestFromContact: Bool,
        formattedPaymentAmount: String,
        firstButtonAction: @escaping () -> Void,
        secondButtonAction: @escaping () -> Void
    ) -> PayWithWiseFooterViewModel? {
        let secondaryButton: PayWithWiseFooterViewModel.SecondButtonConfig? = {
            if isRequestFromContact {
                return .init(
                    title: L10n.PayWithWise.Payment.RejectRequest.Button.title,
                    style: .tertiary,
                    isEnabled: true,
                    action: secondButtonAction
                )
            } else {
                let title = L10n.PayWithWise.Payment.AlternativePaymentMethods.WithOtherMethods.title
                return .init(
                    title: title,
                    style: .tertiary,
                    isEnabled: true,
                    action: secondButtonAction
                )
            }
        }()

        let primaryButton = PayWithWiseFooterViewModel.FirstButtonConfig(
            title: L10n.PayWithWise.Payment.Continue.title(formattedPaymentAmount),
            style: .primary,
            isEnabled: !hasAlert,
            action: firstButtonAction
        )

        return PayWithWiseFooterViewModel(
            firstButton: primaryButton,
            secondButton: secondaryButton
        )
    }

    static func makeBreakdownItemsForCrossCurrency(
        quote: PayWithWiseQuote,
        formattedRequestAmount: String,
        formattedPaymentAmount: String
    ) -> [BreakdownRowModel] {
        func formatFeeAmount(_ fee: Decimal) -> String {
            MoneyFormatter.format(
                fee,
                withCurrencyCode: quote.sourceAmount.currency
            )
        }
        let descriptionItems = [
            BreakdownRowModel(
                accessoryType: .circle,
                primaryText: formattedRequestAmount,
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.requestedAmount,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .divide,
                primaryText: MoneyFormatter.format(
                    NSDecimalNumber(
                        decimal: quote.rate
                    ),
                    withMaximumFractionDigits: 2
                ),
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.rate,
                secondaryMarkupTag: .secondary
            ),
        ]
        let feeItems: [BreakdownRowModel] =
            if quote.fee.discount == 0 {
                [
                    BreakdownRowModel(
                        accessoryType: .plus,
                        primaryText: formatFeeAmount(quote.fee.total),
                        secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.fees,
                        secondaryMarkupTag: .secondary
                    ),
                ]
            } else {
                [
                    BreakdownRowModel(
                        accessoryType: .plus,
                        primaryText: formatFeeAmount(quote.fee.conversion),
                        secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.conversionFee,
                        secondaryMarkupTag: .secondary
                    ),
                    .init(
                        accessoryType: .minus,
                        primaryText: formatFeeAmount(quote.fee.discount),
                        secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.discount,
                        secondaryMarkupTag: .secondary
                    ),
                    .init(
                        accessoryType: .circle,
                        primaryText: formatFeeAmount(quote.fee.total),
                        secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.totalFee,
                        secondaryMarkupTag: .secondary
                    ),
                ]
            }
        let youPay = BreakdownRowModel(
            accessoryType: .equals,
            primaryText: formattedPaymentAmount,
            secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.youPay,
            secondaryMarkupTag: .secondary
        )

        return (descriptionItems + feeItems).appending(youPay)
    }
}

// MARK: - Field initializers

private extension PayWithWiseViewModelFactory {
    static func makeAvatar(profile: Profile, displayName: String) -> AvatarViewModel {
        if let avatar = profile.avatar.downloadedImage {
            AvatarViewModel.image(avatar)
        } else {
            AvatarViewModel.initials(
                Initials(name: displayName)
            )
        }
    }

    static func makeInlineAlert(message: String?) -> InlineAlertViewModel? {
        guard let message else {
            return nil
        }
        return InlineAlertViewModel(message: message)
    }

    static func makeAccountType(profileType: ProfileType) -> String {
        switch profileType {
        case .personal:
            L10n.PayWithWise.Payment.Payer.Info.Section.AccountType.personal
        case .business:
            L10n.PayWithWise.Payment.Payer.Info.Section.AccountType.business
        }
    }
}
