import AnalyticsKit
import BalanceKit
import BalanceKitTestingSupport
import Combine
import ContactsKit
import Neptune
import NeptuneTestingSupport
import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWUI
import UIKit
import UserKit
import WiseCore
import WiseCoreTestingSupport

// swiftlint:disable line_length
extension AccountDetailsInfoHeaderV2ViewModel.ShareButton {
    internal static func build(
        title: String = .canned,
        action: @escaping (UIView) -> Void = { _ in }
    ) -> AccountDetailsInfoHeaderV2ViewModel.ShareButton {
        AccountDetailsInfoHeaderV2ViewModel.ShareButton(
            title: title,
            action: action
        )
    }

    internal static var canned: AccountDetailsInfoHeaderV2ViewModel.ShareButton {
        AccountDetailsInfoHeaderV2ViewModel.ShareButton.build()
    }
}

extension AccountDetailsInfoRowV2ViewModel {
    internal static func build(
        title: String = .canned,
        information: String = .canned,
        isObfuscated: Bool = .canned,
        action: Action = .canned,
        tooltip: IconButtonView.ViewModel? = .canned
    ) -> AccountDetailsInfoRowV2ViewModel {
        AccountDetailsInfoRowV2ViewModel(
            title: title,
            information: information,
            isObfuscated: isObfuscated,
            action: action,
            tooltip: tooltip
        )
    }

    internal static var canned: AccountDetailsInfoRowV2ViewModel {
        AccountDetailsInfoRowV2ViewModel.build()
    }
}

extension AccountDetailsReceiveOptionInfoV2ViewModel {
    internal static func build(
        header: AccountDetailsInfoHeaderV2ViewModel = .canned,
        rows: [AccountDetailsInfoRowV2ViewModel] = .canned
    ) -> AccountDetailsReceiveOptionInfoV2ViewModel {
        AccountDetailsReceiveOptionInfoV2ViewModel(
            header: header,
            rows: rows
        )
    }

    internal static var canned: AccountDetailsReceiveOptionInfoV2ViewModel {
        AccountDetailsReceiveOptionInfoV2ViewModel.build()
    }
}

extension AccountDetailsStatusViewState {
    internal static var canned: AccountDetailsStatusViewState {
        .failedToLoad(.canned)
    }
}

extension AccountDetailsStatusViewState.Model {
    internal static func build(
        header: AccountDetailsStatusHeader = .canned,
        status: AccountDetailsStatus = .canned
    ) -> AccountDetailsStatusViewState.Model {
        AccountDetailsStatusViewState.Model(
            header: header,
            status: status
        )
    }

    internal static var canned: AccountDetailsStatusViewState.Model {
        AccountDetailsStatusViewState.Model.build()
    }
}

extension ContactPickerNudgeModel {
    internal static func build(
        type: ContactPickerNudgeType = .canned,
        title: String = .canned,
        icon: NudgeViewModel.Asset = .canned,
        ctaTitle: String = .canned
    ) -> ContactPickerNudgeModel {
        ContactPickerNudgeModel(
            type: type,
            title: title,
            icon: icon,
            ctaTitle: ctaTitle
        )
    }

    internal static var canned: ContactPickerNudgeModel {
        ContactPickerNudgeModel.build()
    }
}

extension ContactPickerNudgeType {
    internal static var canned: ContactPickerNudgeType {
        .findFriends
    }
}

extension ContactPickerRecentContact {
    internal static func build(
        id: String = .canned,
        contactId: Contact.Id = .canned,
        title: String = .canned,
        subtitle: String = .canned,
        isLoading: Bool = .canned,
        contact: Contact = .canned,
        avatarPublisher: AnyPublisher<AvatarViewModel, Never> = .canned
    ) -> ContactPickerRecentContact {
        ContactPickerRecentContact(
            id: id,
            contactId: contactId,
            title: title,
            subtitle: subtitle,
            isLoading: isLoading,
            contact: contact,
            avatarPublisher: avatarPublisher
        )
    }

    internal static var canned: ContactPickerRecentContact {
        ContactPickerRecentContact.build()
    }
}

extension CreatePaymentRequestFlow.EntryPoint {
    internal static var canned: CreatePaymentRequestFlow.EntryPoint {
        .deeplink
    }
}

extension CreatePaymentRequestInputs {
    internal static func build(
        reference: String? = .canned,
        productDescription: String? = .canned
    ) -> CreatePaymentRequestInputs {
        CreatePaymentRequestInputs(
            reference: reference,
            productDescription: productDescription
        )
    }

    internal static var canned: CreatePaymentRequestInputs {
        CreatePaymentRequestInputs.build()
    }
}

extension PayWithWiseBalanceSelectorViewModel {
    internal static func build(
        title: String = .canned,
        sections: [PayWithWiseBalanceSelectorViewModel.Section] = .canned,
        selectAction: @escaping (IndexPath) -> Void = { _ in }
    ) -> PayWithWiseBalanceSelectorViewModel {
        PayWithWiseBalanceSelectorViewModel(
            title: title,
            sections: sections,
            selectAction: selectAction
        )
    }

    internal static var canned: PayWithWiseBalanceSelectorViewModel {
        PayWithWiseBalanceSelectorViewModel.build()
    }
}

extension PayWithWiseBalanceSelectorViewModel.Section {
    internal static func build(
        headerViewModel: SectionHeaderViewModel = .canned,
        options: [OptionViewModel] = .canned
    ) -> PayWithWiseBalanceSelectorViewModel.Section {
        PayWithWiseBalanceSelectorViewModel.Section(
            headerViewModel: headerViewModel,
            options: options
        )
    }

    internal static var canned: PayWithWiseBalanceSelectorViewModel.Section {
        PayWithWiseBalanceSelectorViewModel.Section.build()
    }
}

extension PayWithWiseFlow.PaymentInitializationSource {
    internal static var canned: PayWithWiseFlow.PaymentInitializationSource {
        .paymentKey(.canned)
    }
}

extension PayWithWiseFlowNavigationStep {
    internal static var canned: PayWithWiseFlowNavigationStep {
        .info
    }
}

extension PayWithWiseHeaderView.ViewModel {
    internal static func build(
        title: LargeTitleViewModel = .canned,
        recipientName: String = .canned,
        description: String? = .canned,
        avatarImage: AnyPublisher<AvatarViewModel, Never> = .canned
    ) -> PayWithWiseHeaderView.ViewModel {
        PayWithWiseHeaderView.ViewModel(
            title: title,
            recipientName: recipientName,
            description: description,
            avatarImage: avatarImage
        )
    }

    internal static var canned: PayWithWiseHeaderView.ViewModel {
        PayWithWiseHeaderView.ViewModel.build()
    }
}

extension PayWithWiseInteractorImpl.BalanceFetchingResult {
    internal static func build(
        autoSelectionResult: PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult = .canned,
        fundableBalances: [Balance] = .canned,
        balances: [Balance] = .canned
    ) -> PayWithWiseInteractorImpl.BalanceFetchingResult {
        PayWithWiseInteractorImpl.BalanceFetchingResult(
            autoSelectionResult: autoSelectionResult,
            fundableBalances: fundableBalances,
            balances: balances
        )
    }

    internal static var canned: PayWithWiseInteractorImpl.BalanceFetchingResult {
        PayWithWiseInteractorImpl.BalanceFetchingResult.build()
    }
}

extension PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult {
    internal static func build(
        balance: Balance = .canned,
        hasSameCurrencyBalance: Bool = .canned,
        hasFunds: Bool = .canned
    ) -> PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult {
        PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult(
            balance: balance,
            hasSameCurrencyBalance: hasSameCurrencyBalance,
            hasFunds: hasFunds
        )
    }

    internal static var canned: PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult {
        PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult.build()
    }
}

extension PayWithWiseViewModel.Alert {
    internal static func build(
        viewModel: InlineAlertViewModel = .canned,
        style: InlineAlertStyle = .canned
    ) -> PayWithWiseViewModel.Alert {
        PayWithWiseViewModel.Alert(
            viewModel: viewModel,
            style: style
        )
    }

    internal static var canned: PayWithWiseViewModel.Alert {
        PayWithWiseViewModel.Alert.build()
    }
}

extension PayWithWiseViewModel.BreakDownItem {
    internal static func build(
        accessoryType: PayWithWiseViewModel.BreakDownItem.AccessoryType = .canned,
        title: String = .canned,
        description: String = .canned
    ) -> PayWithWiseViewModel.BreakDownItem {
        PayWithWiseViewModel.BreakDownItem(
            accessoryType: accessoryType,
            title: title,
            description: description
        )
    }

    internal static var canned: PayWithWiseViewModel.BreakDownItem {
        PayWithWiseViewModel.BreakDownItem.build()
    }
}

extension PayWithWiseViewModel.BreakDownItem.AccessoryType {
    internal static var canned: PayWithWiseViewModel.BreakDownItem.AccessoryType {
        .circle
    }
}

extension PayWithWiseViewModel.Empty {
    internal static func build(
        image: UIImage = .canned,
        title: String = .canned,
        message: String = .canned,
        buttonAction: Action = .canned
    ) -> PayWithWiseViewModel.Empty {
        PayWithWiseViewModel.Empty(
            image: image,
            title: title,
            message: message,
            buttonAction: buttonAction
        )
    }

    internal static var canned: PayWithWiseViewModel.Empty {
        PayWithWiseViewModel.Empty.build()
    }
}

extension PayWithWiseViewModel.Loaded {
    internal static func build(
        shouldHideDetailsButton: Bool = .canned,
        header: PayWithWiseHeaderView.ViewModel = .canned,
        paymentSection: PayWithWiseViewModel.Section? = .canned,
        breakdownItems: [BreakdownRowModel] = .canned,
        inlineAlert: PayWithWiseViewModel.Alert? = .canned,
        footer: PayWithWiseFooterViewModel? = .canned
    ) -> PayWithWiseViewModel.Loaded {
        PayWithWiseViewModel.Loaded(
            shouldHideDetailsButton: shouldHideDetailsButton,
            header: header,
            paymentSection: paymentSection,
            breakdownItems: breakdownItems,
            inlineAlert: inlineAlert,
            footer: footer
        )
    }

    internal static var canned: PayWithWiseViewModel.Loaded {
        PayWithWiseViewModel.Loaded.build()
    }
}

extension PayWithWiseViewModel.Section {
    internal static func build(
        header: SectionHeaderViewModel = .canned,
        sectionOptions: [PayWithWiseViewModel.Section.SectionOption] = .canned
    ) -> PayWithWiseViewModel.Section {
        PayWithWiseViewModel.Section(
            header: header,
            sectionOptions: sectionOptions
        )
    }

    internal static var canned: PayWithWiseViewModel.Section {
        PayWithWiseViewModel.Section.build()
    }
}

extension PayWithWiseViewModel.Section.SectionOption {
    internal static func build(
        option: OptionViewModel = .canned,
        action: (() -> Void)? = {}
    ) -> PayWithWiseViewModel.Section.SectionOption {
        PayWithWiseViewModel.Section.SectionOption(
            option: option,
            action: action
        )
    }

    internal static var canned: PayWithWiseViewModel.Section.SectionOption {
        PayWithWiseViewModel.Section.SectionOption.build()
    }
}

extension PayWithWiseViewModelFactoryImpl.BalanceOption {
    internal static func build(
        id: BalanceId = .canned,
        viewModel: OptionViewModel = .canned
    ) -> PayWithWiseViewModelFactoryImpl.BalanceOption {
        PayWithWiseViewModelFactoryImpl.BalanceOption(
            id: id,
            viewModel: viewModel
        )
    }

    internal static var canned: PayWithWiseViewModelFactoryImpl.BalanceOption {
        PayWithWiseViewModelFactoryImpl.BalanceOption.build()
    }
}

extension PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer {
    internal static func build(
        fundables: [PayWithWiseViewModelFactoryImpl.BalanceOption] = .canned,
        nonFundables: [PayWithWiseViewModelFactoryImpl.BalanceOption] = .canned
    ) -> PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer {
        PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer(
            fundables: fundables,
            nonFundables: nonFundables
        )
    }

    internal static var canned: PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer {
        PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build()
    }
}

extension PaymentLinkSharingDetails {
    internal static func build(
        paymentRequest: PaymentRequestV2 = .canned,
        qrCodeImage: UIImage? = .canned
    ) -> PaymentLinkSharingDetails {
        PaymentLinkSharingDetails(
            paymentRequest: paymentRequest,
            qrCodeImage: qrCodeImage
        )
    }

    internal static var canned: PaymentLinkSharingDetails {
        PaymentLinkSharingDetails.build()
    }
}

extension PaymentLinkSharingViewAction {
    internal static var canned: PaymentLinkSharingViewAction {
        .shareLink(.canned)
    }
}

extension QuickpayPayerInputs {
    internal static func build(
        amount: Decimal? = .canned,
        currency: String = .canned,
        description: String? = .canned
    ) -> QuickpayPayerInputs {
        QuickpayPayerInputs(
            amount: amount,
            currency: currency,
            description: description
        )
    }

    internal static var canned: QuickpayPayerInputs {
        QuickpayPayerInputs.build()
    }
}

extension ReceiveMethodsQRSharingMode.SingleSharingModel {
    internal static func build(
        alias: ReceiveMethodAlias = .canned,
        amount: Decimal? = .canned,
        message: String? = .canned
    ) -> ReceiveMethodsQRSharingMode.SingleSharingModel {
        ReceiveMethodsQRSharingMode.SingleSharingModel(
            alias: alias,
            amount: amount,
            message: message
        )
    }

    internal static var canned: ReceiveMethodsQRSharingMode.SingleSharingModel {
        ReceiveMethodsQRSharingMode.SingleSharingModel.build()
    }
}

extension Refund {
    internal static func build(
        amount: Money = .canned,
        reason: String? = .canned,
        payerData: Refund.PayerData? = .canned
    ) -> Refund {
        Refund(
            amount: amount,
            reason: reason,
            payerData: payerData
        )
    }

    internal static var canned: Refund {
        Refund.build()
    }
}

extension Refund.PayerData {
    internal static func build(
        name: String? = .canned,
        email: String? = .canned
    ) -> Refund.PayerData {
        Refund.PayerData(
            name: name,
            email: email
        )
    }

    internal static var canned: Refund.PayerData {
        Refund.PayerData.build()
    }
}

extension RequestMoneyFlow.BalanceInfo {
    internal static func build(
        id: BalanceId = .canned,
        currencyCode: CurrencyCode? = .canned
    ) -> RequestMoneyFlow.BalanceInfo {
        RequestMoneyFlow.BalanceInfo(
            id: id,
            currencyCode: currencyCode
        )
    }

    internal static var canned: RequestMoneyFlow.BalanceInfo {
        RequestMoneyFlow.BalanceInfo.build()
    }
}

extension RequestMoneyFlow.EntryPoint {
    internal static var canned: RequestMoneyFlow.EntryPoint {
        .deeplink
    }
}

extension WisetagScannedProfileViewModel {
    internal static func build(
        header: WisetagScannedProfileViewModel.HeaderViewModel? = .canned,
        footer: WisetagScannedProfileViewModel.FooterViewModel = .canned
    ) -> WisetagScannedProfileViewModel {
        WisetagScannedProfileViewModel(
            header: header,
            footer: footer
        )
    }

    internal static var canned: WisetagScannedProfileViewModel {
        WisetagScannedProfileViewModel.build()
    }
}

extension WisetagScannedProfileViewModel.ButtonViewModel {
    internal static func build(
        icon: UIImage = .canned,
        title: String = .canned,
        enabled: Bool = .canned,
        action: (() -> Void)? = {}
    ) -> WisetagScannedProfileViewModel.ButtonViewModel {
        WisetagScannedProfileViewModel.ButtonViewModel(
            icon: icon,
            title: title,
            enabled: enabled,
            action: action
        )
    }

    internal static var canned: WisetagScannedProfileViewModel.ButtonViewModel {
        WisetagScannedProfileViewModel.ButtonViewModel.build()
    }
}

extension WisetagScannedProfileViewModel.FooterViewModel {
    internal static func build(
        buttons: [WisetagScannedProfileViewModel.ButtonViewModel]? = .canned,
        isLoading: Bool = .canned
    ) -> WisetagScannedProfileViewModel.FooterViewModel {
        WisetagScannedProfileViewModel.FooterViewModel(
            buttons: buttons,
            isLoading: isLoading
        )
    }

    internal static var canned: WisetagScannedProfileViewModel.FooterViewModel {
        WisetagScannedProfileViewModel.FooterViewModel.build()
    }
}

extension WisetagScannedProfileViewModel.HeaderViewModel {
    internal static func build(
        avatar: AnyPublisher<AvatarViewModel, Never> = .canned,
        title: String = .canned,
        subtitle: String? = .canned,
        alert: WisetagScannedProfileViewModel.HeaderViewModel.Alert? = .canned
    ) -> WisetagScannedProfileViewModel.HeaderViewModel {
        WisetagScannedProfileViewModel.HeaderViewModel(
            avatar: avatar,
            title: title,
            subtitle: subtitle,
            alert: alert
        )
    }

    internal static var canned: WisetagScannedProfileViewModel.HeaderViewModel {
        WisetagScannedProfileViewModel.HeaderViewModel.build()
    }
}

// swiftlint:enable line_length
