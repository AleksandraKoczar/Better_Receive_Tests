import AnalyticsKit
import BalanceKit
import Combine
import ContactsKit
import Neptune
import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWUI
import UIKit
import UserKit
import WiseCore

// swiftlint:disable file_length
// swiftlint:disable cyclomatic_complexity
private func compareOptionals<T>(lhs: T?, rhs: T?, compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case let (lValue?, rValue?):
        compare(lValue, rValue)
    case (nil, nil):
        true
    default:
        false
    }
}

private func compareArrays<T>(lhs: [T], rhs: [T], compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (idx, lhsItem) in lhs.enumerated() {
        guard compare(lhsItem, rhs[idx]) else { return false }
    }

    return true
}

// MARK: - AutoEquatableForTest for classes, protocols, structs

// MARK: - AccountDetailsInfoHeaderV2ViewModel AutoEquatableForTest

extension AccountDetailsInfoHeaderV2ViewModel: @retroactive Equatable {}
public func == (lhs: AccountDetailsInfoHeaderV2ViewModel, rhs: AccountDetailsInfoHeaderV2ViewModel) -> Bool {
    guard lhs.avatarAccessibilityValue == rhs.avatarAccessibilityValue else { return false }
    guard lhs.title == rhs.title else { return false }
    guard compareOptionals(lhs: lhs.shareButton, rhs: rhs.shareButton, compare: ==) else { return false }
    return true
}

// MARK: - AccountDetailsInfoHeaderV2ViewModel.ShareButton AutoEquatableForTest

extension AccountDetailsInfoHeaderV2ViewModel.ShareButton: @retroactive Equatable {}
public func == (lhs: AccountDetailsInfoHeaderV2ViewModel.ShareButton, rhs: AccountDetailsInfoHeaderV2ViewModel.ShareButton) -> Bool {
    guard lhs.title == rhs.title else { return false }
    return true
}

// MARK: - AccountDetailsInfoRowV2ViewModel AutoEquatableForTest

extension AccountDetailsInfoRowV2ViewModel: @retroactive Equatable {}
public func == (lhs: AccountDetailsInfoRowV2ViewModel, rhs: AccountDetailsInfoRowV2ViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.information == rhs.information else { return false }
    guard lhs.isObfuscated == rhs.isObfuscated else { return false }
    guard compareOptionals(lhs: lhs.tooltip, rhs: rhs.tooltip, compare: ==) else { return false }
    return true
}

// MARK: - AccountDetailsReceiveOptionInfoV2ViewModel AutoEquatableForTest

extension AccountDetailsReceiveOptionInfoV2ViewModel: @retroactive Equatable {}
public func == (lhs: AccountDetailsReceiveOptionInfoV2ViewModel, rhs: AccountDetailsReceiveOptionInfoV2ViewModel) -> Bool {
    guard lhs.header == rhs.header else { return false }
    guard lhs.rows == rhs.rows else { return false }
    return true
}

// MARK: - AccountDetailsReceiveOptionV2PageViewModel AutoEquatableForTest

extension AccountDetailsReceiveOptionV2PageViewModel: @retroactive Equatable {}
public func == (lhs: AccountDetailsReceiveOptionV2PageViewModel, rhs: AccountDetailsReceiveOptionV2PageViewModel) -> Bool {
    guard compareOptionals(lhs: lhs.title, rhs: rhs.title, compare: ==) else { return false }
    guard lhs.type == rhs.type else { return false }
    guard compareOptionals(lhs: lhs.alert, rhs: rhs.alert, compare: ==) else { return false }
    guard lhs.summaries == rhs.summaries else { return false }
    guard compareOptionals(lhs: lhs.infoViewModel, rhs: rhs.infoViewModel, compare: ==) else { return false }
    guard lhs.nudge == rhs.nudge else { return false }
    return true
}

// MARK: - AccountDetailsReceiveOptionV2PageViewModel.Alert AutoEquatableForTest

extension AccountDetailsReceiveOptionV2PageViewModel.Alert: @retroactive Equatable {}
public func == (lhs: AccountDetailsReceiveOptionV2PageViewModel.Alert, rhs: AccountDetailsReceiveOptionV2PageViewModel.Alert) -> Bool {
    guard lhs.style == rhs.style else { return false }
    guard lhs.viewModel == rhs.viewModel else { return false }
    return true
}

// MARK: - AccountDetailsV3ListViewModel.Section AutoEquatableForTest

extension AccountDetailsV3ListViewModel.Section: @retroactive Equatable {}
public func == (lhs: AccountDetailsV3ListViewModel.Section, rhs: AccountDetailsV3ListViewModel.Section) -> Bool {
    guard lhs.id == rhs.id else { return false }
    guard compareOptionals(lhs: lhs.title, rhs: rhs.title, compare: ==) else { return false }
    guard lhs.items == rhs.items else { return false }
    return true
}

// MARK: - AccountDetailsV3ListViewModel.Section.Item AutoEquatableForTest

extension AccountDetailsV3ListViewModel.Section.Item: @retroactive Equatable {}
public func == (lhs: AccountDetailsV3ListViewModel.Section.Item, rhs: AccountDetailsV3ListViewModel.Section.Item) -> Bool {
    guard lhs.id == rhs.id else { return false }
    guard lhs.avatar == rhs.avatar else { return false }
    guard lhs.title == rhs.title else { return false }
    guard compareOptionals(lhs: lhs.subtitle, rhs: rhs.subtitle, compare: ==) else { return false }
    guard lhs.keywords == rhs.keywords else { return false }
    return true
}

// MARK: - CreatePaymentRequestConfirmationViewModel AutoEquatableForTest

extension CreatePaymentRequestConfirmationViewModel: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestConfirmationViewModel, rhs: CreatePaymentRequestConfirmationViewModel) -> Bool {
    guard lhs.asset == rhs.asset else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.info == rhs.info else { return false }
    guard lhs.privacyNotice == rhs.privacyNotice else { return false }
    guard lhs.shareButtons == rhs.shareButtons else { return false }
    guard lhs.shouldShowExtendedFooter == rhs.shouldShowExtendedFooter else { return false }
    return true
}

// MARK: - CreatePaymentRequestConfirmationViewModel.ButtonViewModel AutoEquatableForTest

extension CreatePaymentRequestConfirmationViewModel.ButtonViewModel: @retroactive Equatable {}
public func == (
    lhs: CreatePaymentRequestConfirmationViewModel.ButtonViewModel,
    rhs: CreatePaymentRequestConfirmationViewModel.ButtonViewModel
) -> Bool {
    guard lhs.icon == rhs.icon else { return false }
    guard lhs.title == rhs.title else { return false }
    return true
}

// MARK: - CreatePaymentRequestConfirmationViewModel.LabelViewModel AutoEquatableForTest

extension CreatePaymentRequestConfirmationViewModel.LabelViewModel: @retroactive Equatable {}
public func == (
    lhs: CreatePaymentRequestConfirmationViewModel.LabelViewModel,
    rhs: CreatePaymentRequestConfirmationViewModel.LabelViewModel
) -> Bool {
    guard compareOptionals(lhs: lhs.text, rhs: rhs.text, compare: ==) else { return false }
    guard lhs.style == rhs.style else { return false }
    return true
}

// MARK: - CreatePaymentRequestFromContactSuccessViewModel AutoEquatableForTest

extension CreatePaymentRequestFromContactSuccessViewModel: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestFromContactSuccessViewModel, rhs: CreatePaymentRequestFromContactSuccessViewModel) -> Bool {
    guard lhs.asset == rhs.asset else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.message == rhs.message else { return false }
    guard lhs.buttonConfiguration == rhs.buttonConfiguration else { return false }
    return true
}

// MARK: - CreatePaymentRequestMethodManagementViewModel AutoEquatableForTest

extension CreatePaymentRequestMethodManagementViewModel: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestMethodManagementViewModel, rhs: CreatePaymentRequestMethodManagementViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.subtitle == rhs.subtitle else { return false }
    guard lhs.options == rhs.options else { return false }
    guard lhs.footerAction == rhs.footerAction else { return false }
    guard lhs.secondaryFooterAction == rhs.secondaryFooterAction else { return false }
    return true
}

// MARK: - CreatePaymentRequestMethodManagementViewModel.ActionOptionViewModel AutoEquatableForTest

extension CreatePaymentRequestMethodManagementViewModel.ActionOptionViewModel: @retroactive Equatable {}
public func == (
    lhs: CreatePaymentRequestMethodManagementViewModel.ActionOptionViewModel,
    rhs: CreatePaymentRequestMethodManagementViewModel.ActionOptionViewModel
) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard compareOptionals(lhs: lhs.subtitle, rhs: rhs.subtitle, compare: ==) else { return false }
    guard lhs.leadingViewModel == rhs.leadingViewModel else { return false }
    guard lhs.action == rhs.action else { return false }
    return true
}

// MARK: - CreatePaymentRequestMethodManagementViewModel.SwitchOptionViewModel AutoEquatableForTest

extension CreatePaymentRequestMethodManagementViewModel.SwitchOptionViewModel: @retroactive Equatable {}
public func == (
    lhs: CreatePaymentRequestMethodManagementViewModel.SwitchOptionViewModel,
    rhs: CreatePaymentRequestMethodManagementViewModel.SwitchOptionViewModel
) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard compareOptionals(lhs: lhs.subtitle, rhs: rhs.subtitle, compare: ==) else { return false }
    guard lhs.leadingViewModel == rhs.leadingViewModel else { return false }
    guard lhs.isOn == rhs.isOn else { return false }
    guard lhs.isEnabled == rhs.isEnabled else { return false }
    return true
}

// MARK: - CreatePaymentRequestPersonalPresenterInfo AutoEquatableForTest

extension CreatePaymentRequestPersonalPresenterInfo: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestPersonalPresenterInfo, rhs: CreatePaymentRequestPersonalPresenterInfo) -> Bool {
    guard compareOptionals(lhs: lhs.contact, rhs: rhs.contact, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.value, rhs: rhs.value, compare: ==) else { return false }
    guard lhs.selectedCurrency == rhs.selectedCurrency else { return false }
    guard lhs.eligibleBalances == rhs.eligibleBalances else { return false }
    guard lhs.selectedBalanceId == rhs.selectedBalanceId else { return false }
    guard compareOptionals(lhs: lhs.message, rhs: rhs.message, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.PWWAlert, rhs: rhs.PWWAlert, compare: ==) else { return false }
    guard lhs.paymentMethods == rhs.paymentMethods else { return false }
    return true
}

// MARK: - CreatePaymentRequestPersonalViewModel AutoEquatableForTest

extension CreatePaymentRequestPersonalViewModel: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestPersonalViewModel, rhs: CreatePaymentRequestPersonalViewModel) -> Bool {
    guard lhs.titleViewModel == rhs.titleViewModel else { return false }
    guard lhs.moneyInputViewModel == rhs.moneyInputViewModel else { return false }
    guard lhs.currencySelectorEnabled == rhs.currencySelectorEnabled else { return false }
    guard compareOptionals(lhs: lhs.message, rhs: rhs.message, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.alert, rhs: rhs.alert, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.nudge, rhs: rhs.nudge, compare: ==) else { return false }
    guard lhs.footerButtonEnabled == rhs.footerButtonEnabled else { return false }
    guard lhs.footerButtonTitle == rhs.footerButtonTitle else { return false }
    return true
}

// MARK: - CreatePaymentRequestPersonalViewModel.Alert AutoEquatableForTest

extension CreatePaymentRequestPersonalViewModel.Alert: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestPersonalViewModel.Alert, rhs: CreatePaymentRequestPersonalViewModel.Alert) -> Bool {
    guard lhs.style == rhs.style else { return false }
    guard lhs.viewModel == rhs.viewModel else { return false }
    return true
}

// MARK: - CreatePaymentRequestPersonalViewModel.Nudge AutoEquatableForTest

extension CreatePaymentRequestPersonalViewModel.Nudge: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestPersonalViewModel.Nudge, rhs: CreatePaymentRequestPersonalViewModel.Nudge) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.icon == rhs.icon else { return false }
    guard lhs.ctaTitle == rhs.ctaTitle else { return false }
    return true
}

// MARK: - CreatePaymentRequestPresenterInfo AutoEquatableForTest

extension CreatePaymentRequestPresenterInfo: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestPresenterInfo, rhs: CreatePaymentRequestPresenterInfo) -> Bool {
    guard compareOptionals(lhs: lhs.value, rhs: rhs.value, compare: ==) else { return false }
    guard lhs.selectedCurrency == rhs.selectedCurrency else { return false }
    guard lhs.eligibleBalances == rhs.eligibleBalances else { return false }
    guard lhs.selectedBalanceId == rhs.selectedBalanceId else { return false }
    guard compareOptionals(lhs: lhs.reference, rhs: rhs.reference, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.productDescription, rhs: rhs.productDescription, compare: ==) else { return false }
    guard lhs.paymentMethods == rhs.paymentMethods else { return false }
    return true
}

// MARK: - CreatePaymentRequestViewModel AutoEquatableForTest

extension CreatePaymentRequestViewModel: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestViewModel, rhs: CreatePaymentRequestViewModel) -> Bool {
    guard lhs.titleViewModel == rhs.titleViewModel else { return false }
    guard lhs.moneyInputViewModel == rhs.moneyInputViewModel else { return false }
    guard lhs.currencySelectorEnabled == rhs.currencySelectorEnabled else { return false }
    guard lhs.shouldShowPaymentLimitsCheckbox == rhs.shouldShowPaymentLimitsCheckbox else { return false }
    guard lhs.isLimitPaymentsSelected == rhs.isLimitPaymentsSelected else { return false }
    guard compareOptionals(lhs: lhs.productDescription, rhs: rhs.productDescription, compare: ==) else { return false }
    guard lhs.paymentMethodsOption == rhs.paymentMethodsOption else { return false }
    guard compareOptionals(lhs: lhs.nudge, rhs: rhs.nudge, compare: ==) else { return false }
    guard lhs.footerButtonEnabled == rhs.footerButtonEnabled else { return false }
    guard lhs.footerButtonTitle == rhs.footerButtonTitle else { return false }
    return true
}

// MARK: - CreatePaymentRequestViewModel.PaymentMethodsOption AutoEquatableForTest

extension CreatePaymentRequestViewModel.PaymentMethodsOption: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestViewModel.PaymentMethodsOption, rhs: CreatePaymentRequestViewModel.PaymentMethodsOption) -> Bool {
    guard lhs.viewModel == rhs.viewModel else { return false }
    return true
}

// MARK: - PayWithWiseInteractorImpl.BalanceFetchingResult AutoEquatableForTest

extension PayWithWiseInteractorImpl.BalanceFetchingResult: @retroactive Equatable {}
public func == (lhs: PayWithWiseInteractorImpl.BalanceFetchingResult, rhs: PayWithWiseInteractorImpl.BalanceFetchingResult) -> Bool {
    guard lhs.autoSelectionResult == rhs.autoSelectionResult else { return false }
    guard lhs.fundableBalances == rhs.fundableBalances else { return false }
    guard lhs.balances == rhs.balances else { return false }
    return true
}

// MARK: - PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult AutoEquatableForTest

extension PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult: @retroactive Equatable {}
public func == (
    lhs: PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult,
    rhs: PayWithWiseInteractorImpl.BalanceFetchingResult.AutoSelectionResult
) -> Bool {
    guard lhs.balance == rhs.balance else { return false }
    guard lhs.hasSameCurrencyBalance == rhs.hasSameCurrencyBalance else { return false }
    guard lhs.hasFunds == rhs.hasFunds else { return false }
    return true
}

// MARK: - PayWithWiseSuccessPromptViewModel AutoEquatableForTest

extension PayWithWiseSuccessPromptViewModel: @retroactive Equatable {}
public func == (lhs: PayWithWiseSuccessPromptViewModel, rhs: PayWithWiseSuccessPromptViewModel) -> Bool {
    guard lhs.asset == rhs.asset else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.message == rhs.message else { return false }
    guard lhs.primaryButtonTitle == rhs.primaryButtonTitle else { return false }
    return true
}

// MARK: - PaymentDetailsViewModel AutoEquatableForTest

extension PaymentDetailsViewModel: @retroactive Equatable {}
public func == (lhs: PaymentDetailsViewModel, rhs: PaymentDetailsViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard compareOptionals(lhs: lhs.alert, rhs: rhs.alert, compare: ==) else { return false }
    guard lhs.items == rhs.items else { return false }
    guard compareOptionals(lhs: lhs.footerAction, rhs: rhs.footerAction, compare: ==) else { return false }
    return true
}

// MARK: - PaymentDetailsViewModel.Alert AutoEquatableForTest

extension PaymentDetailsViewModel.Alert: @retroactive Equatable {}
public func == (lhs: PaymentDetailsViewModel.Alert, rhs: PaymentDetailsViewModel.Alert) -> Bool {
    guard lhs.viewModel == rhs.viewModel else { return false }
    guard lhs.style == rhs.style else { return false }
    return true
}

// MARK: - PaymentLinkAllPaymentsViewModel AutoEquatableForTest

extension PaymentLinkAllPaymentsViewModel: @retroactive Equatable {}
public func == (lhs: PaymentLinkAllPaymentsViewModel, rhs: PaymentLinkAllPaymentsViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.content == rhs.content else { return false }
    return true
}

// MARK: - PaymentLinkPaymentDetailsViewModel AutoEquatableForTest

extension PaymentLinkPaymentDetailsViewModel: @retroactive Equatable {}
public func == (lhs: PaymentLinkPaymentDetailsViewModel, rhs: PaymentLinkPaymentDetailsViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.sections == rhs.sections else { return false }
    return true
}

// MARK: - PaymentLinkPaymentDetailsViewModel.Section AutoEquatableForTest

extension PaymentLinkPaymentDetailsViewModel.Section: @retroactive Equatable {}
public func == (lhs: PaymentLinkPaymentDetailsViewModel.Section, rhs: PaymentLinkPaymentDetailsViewModel.Section) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.items == rhs.items else { return false }
    return true
}

// MARK: - PaymentLinkPaymentDetailsViewModel.Section.OptionItem AutoEquatableForTest

extension PaymentLinkPaymentDetailsViewModel.Section.OptionItem: @retroactive Equatable {}
public func == (
    lhs: PaymentLinkPaymentDetailsViewModel.Section.OptionItem,
    rhs: PaymentLinkPaymentDetailsViewModel.Section.OptionItem
) -> Bool {
    guard lhs.option == rhs.option else { return false }
    return true
}

// MARK: - PaymentLinkSharingDetails AutoEquatableForTest

extension PaymentLinkSharingDetails: @retroactive Equatable {}
public func == (lhs: PaymentLinkSharingDetails, rhs: PaymentLinkSharingDetails) -> Bool {
    guard lhs.paymentRequest == rhs.paymentRequest else { return false }
    guard compareOptionals(lhs: lhs.qrCodeImage, rhs: rhs.qrCodeImage, compare: ==) else { return false }
    return true
}

// MARK: - PaymentLinkSharingViewModel AutoEquatableForTest

extension PaymentLinkSharingViewModel: @retroactive Equatable {}
public func == (lhs: PaymentLinkSharingViewModel, rhs: PaymentLinkSharingViewModel) -> Bool {
    guard compareOptionals(lhs: lhs.qrCodeImage, rhs: rhs.qrCodeImage, compare: ==) else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.amount == rhs.amount else { return false }
    guard lhs.navigationOptions == rhs.navigationOptions else { return false }
    return true
}

// MARK: - PaymentLinkSharingViewModel.NavigationOption AutoEquatableForTest

extension PaymentLinkSharingViewModel.NavigationOption: @retroactive Equatable {}
public func == (lhs: PaymentLinkSharingViewModel.NavigationOption, rhs: PaymentLinkSharingViewModel.NavigationOption) -> Bool {
    guard lhs.viewModel == rhs.viewModel else { return false }
    return true
}

// MARK: - PaymentRequestDetailPaymentMethodsViewModel AutoEquatableForTest

extension PaymentRequestDetailPaymentMethodsViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestDetailPaymentMethodsViewModel, rhs: PaymentRequestDetailPaymentMethodsViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.summaries == rhs.summaries else { return false }
    return true
}

// MARK: - PaymentRequestDetailShareOptionsViewModel AutoEquatableForTest

extension PaymentRequestDetailShareOptionsViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestDetailShareOptionsViewModel, rhs: PaymentRequestDetailShareOptionsViewModel) -> Bool {
    guard lhs.paymentLink == rhs.paymentLink else { return false }
    guard lhs.options == rhs.options else { return false }
    return true
}

// MARK: - PaymentRequestDetailViewModel AutoEquatableForTest

extension PaymentRequestDetailViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestDetailViewModel, rhs: PaymentRequestDetailViewModel) -> Bool {
    guard lhs.header == rhs.header else { return false }
    guard lhs.sections == rhs.sections else { return false }
    guard compareOptionals(lhs: lhs.footer, rhs: rhs.footer, compare: ==) else { return false }
    return true
}

// MARK: - PaymentRequestDetailViewModel.FooterViewModel AutoEquatableForTest

extension PaymentRequestDetailViewModel.FooterViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestDetailViewModel.FooterViewModel, rhs: PaymentRequestDetailViewModel.FooterViewModel) -> Bool {
    guard lhs.primaryAction == rhs.primaryAction else { return false }
    guard compareOptionals(lhs: lhs.secondaryAction, rhs: rhs.secondaryAction, compare: ==) else { return false }
    guard lhs.configuration == rhs.configuration else { return false }
    return true
}

// MARK: - PaymentRequestDetailViewModel.HeaderViewModel AutoEquatableForTest

extension PaymentRequestDetailViewModel.HeaderViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestDetailViewModel.HeaderViewModel, rhs: PaymentRequestDetailViewModel.HeaderViewModel) -> Bool {
    guard lhs.icon == rhs.icon else { return false }
    guard lhs.iconStyle == rhs.iconStyle else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.subtitle == rhs.subtitle else { return false }
    return true
}

// MARK: - PaymentRequestDetailViewModel.SectionViewModel AutoEquatableForTest

extension PaymentRequestDetailViewModel.SectionViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestDetailViewModel.SectionViewModel, rhs: PaymentRequestDetailViewModel.SectionViewModel) -> Bool {
    guard lhs.header == rhs.header else { return false }
    guard lhs.items == rhs.items else { return false }
    return true
}

// MARK: - PaymentRequestDetailViewModel.SectionViewModel.OptionViewModel AutoEquatableForTest

extension PaymentRequestDetailViewModel.SectionViewModel.OptionViewModel: @retroactive Equatable {}
public func == (
    lhs: PaymentRequestDetailViewModel.SectionViewModel.OptionViewModel,
    rhs: PaymentRequestDetailViewModel.SectionViewModel.OptionViewModel
) -> Bool {
    guard lhs.option == rhs.option else { return false }
    return true
}

// MARK: - PaymentRequestOnboardingViewModel AutoEquatableForTest

extension PaymentRequestOnboardingViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestOnboardingViewModel, rhs: PaymentRequestOnboardingViewModel) -> Bool {
    guard lhs.titleText == rhs.titleText else { return false }
    guard lhs.subtitleText == rhs.subtitleText else { return false }
    guard lhs.image == rhs.image else { return false }
    guard lhs.summaryViewModels == rhs.summaryViewModels else { return false }
    guard lhs.footerButtonAction == rhs.footerButtonAction else { return false }
    return true
}

// MARK: - PaymentRequestOnboardingViewModel.SummaryViewModel AutoEquatableForTest

extension PaymentRequestOnboardingViewModel.SummaryViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestOnboardingViewModel.SummaryViewModel, rhs: PaymentRequestOnboardingViewModel.SummaryViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.description == rhs.description else { return false }
    guard lhs.icon == rhs.icon else { return false }
    return true
}

// MARK: - PaymentRequestSummaryList AutoEquatableForTest

extension PaymentRequestSummaryList: @retroactive Equatable {}
public func == (lhs: PaymentRequestSummaryList, rhs: PaymentRequestSummaryList) -> Bool {
    guard lhs.unpaid == rhs.unpaid else { return false }
    guard lhs.paid == rhs.paid else { return false }
    guard lhs.active == rhs.active else { return false }
    guard lhs.inactive == rhs.inactive else { return false }
    guard lhs.upcoming == rhs.upcoming else { return false }
    guard lhs.past == rhs.past else { return false }
    guard lhs.visibleState == rhs.visibleState else { return false }
    return true
}

// MARK: - PaymentRequestSummaryList.Unpaid AutoEquatableForTest

extension PaymentRequestSummaryList.Unpaid: @retroactive Equatable {}
public func == (lhs: PaymentRequestSummaryList.Unpaid, rhs: PaymentRequestSummaryList.Unpaid) -> Bool {
    guard lhs.closestToExpiry == rhs.closestToExpiry else { return false }
    guard lhs.mostRecentlyRequested == rhs.mostRecentlyRequested else { return false }
    guard lhs.visibleState == rhs.visibleState else { return false }
    return true
}

// MARK: - PaymentRequestSummaryList.Upcoming AutoEquatableForTest

extension PaymentRequestSummaryList.Upcoming: @retroactive Equatable {}
public func == (lhs: PaymentRequestSummaryList.Upcoming, rhs: PaymentRequestSummaryList.Upcoming) -> Bool {
    guard lhs.closestToExpiry == rhs.closestToExpiry else { return false }
    guard lhs.mostRecentlyRequested == rhs.mostRecentlyRequested else { return false }
    guard lhs.visibleState == rhs.visibleState else { return false }
    return true
}

// MARK: - PaymentRequestsListHeaderView.ViewModel AutoEquatableForTest

extension PaymentRequestsListHeaderView.ViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestsListHeaderView.ViewModel, rhs: PaymentRequestsListHeaderView.ViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard compareOptionals(lhs: lhs.segmentedControl, rhs: rhs.segmentedControl, compare: ==) else { return false }
    return true
}

// MARK: - PaymentRequestsListRadioOptionsViewModel AutoEquatableForTest

extension PaymentRequestsListRadioOptionsViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestsListRadioOptionsViewModel, rhs: PaymentRequestsListRadioOptionsViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.options == rhs.options else { return false }
    guard lhs.dismissOnSelection == rhs.dismissOnSelection else { return false }
    guard lhs.action == rhs.action else { return false }
    return true
}

// MARK: - PaymentRequestsListRadioOptionsViewModel.Action AutoEquatableForTest

extension PaymentRequestsListRadioOptionsViewModel.Action: @retroactive Equatable {}
public func == (lhs: PaymentRequestsListRadioOptionsViewModel.Action, rhs: PaymentRequestsListRadioOptionsViewModel.Action) -> Bool {
    guard lhs.title == rhs.title else { return false }
    return true
}

// MARK: - PaymentRequestsListViewModel.EmptyState AutoEquatableForTest

extension PaymentRequestsListViewModel.EmptyState: @retroactive Equatable {}
public func == (lhs: PaymentRequestsListViewModel.EmptyState, rhs: PaymentRequestsListViewModel.EmptyState) -> Bool {
    guard lhs.illustration == rhs.illustration else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.summaries == rhs.summaries else { return false }
    guard lhs.primaryButton == rhs.primaryButton else { return false }
    guard compareOptionals(lhs: lhs.secondaryButton, rhs: rhs.secondaryButton, compare: ==) else { return false }
    return true
}

// MARK: - PaymentRequestsListViewModel.PaymentRequests AutoEquatableForTest

extension PaymentRequestsListViewModel.PaymentRequests: @retroactive Equatable {}
public func == (lhs: PaymentRequestsListViewModel.PaymentRequests, rhs: PaymentRequestsListViewModel.PaymentRequests) -> Bool {
    guard lhs.navigationBarButtons == rhs.navigationBarButtons else { return false }
    guard lhs.header == rhs.header else { return false }
    guard lhs.content == rhs.content else { return false }
    guard lhs.isCreatePaymentRequestHidden == rhs.isCreatePaymentRequestHidden else { return false }
    return true
}

// MARK: - PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel AutoEquatableForTest

extension PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel: @retroactive Equatable {}
public func == (
    lhs: PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel,
    rhs: PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel
) -> Bool {
    guard compareOptionals(lhs: lhs.title, rhs: rhs.title, compare: ==) else { return false }
    guard lhs.icon == rhs.icon else { return false }
    return true
}

// MARK: - QRDownloadViewModel AutoEquatableForTest

extension QRDownloadViewModel: @retroactive Equatable {}
public func == (lhs: QRDownloadViewModel, rhs: QRDownloadViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.subtitle == rhs.subtitle else { return false }
    guard lhs.cameraDownloadOption == rhs.cameraDownloadOption else { return false }
    guard lhs.fileDownloadOption == rhs.fileDownloadOption else { return false }
    return true
}

// MARK: - QRDownloadViewModel.Option AutoEquatableForTest

extension QRDownloadViewModel.Option: @retroactive Equatable {}
public func == (lhs: QRDownloadViewModel.Option, rhs: QRDownloadViewModel.Option) -> Bool {
    guard lhs.viewModel == rhs.viewModel else { return false }
    return true
}

// MARK: - QuickpayCardViewModel AutoEquatableForTest

extension QuickpayCardViewModel: @retroactive Equatable {}
public func == (lhs: QuickpayCardViewModel, rhs: QuickpayCardViewModel) -> Bool {
    guard lhs.id == rhs.id else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.subtitle == rhs.subtitle else { return false }
    guard lhs.articleId == rhs.articleId else { return false }
    return true
}

// MARK: - QuickpayPayerViewModel AutoEquatableForTest

extension QuickpayPayerViewModel: @retroactive Equatable {}
public func == (lhs: QuickpayPayerViewModel, rhs: QuickpayPayerViewModel) -> Bool {
    guard lhs.businessName == rhs.businessName else { return false }
    guard lhs.subtitle == rhs.subtitle else { return false }
    guard lhs.moneyInputViewModel == rhs.moneyInputViewModel else { return false }
    guard compareOptionals(lhs: lhs.description, rhs: rhs.description, compare: ==) else { return false }
    return true
}

// MARK: - QuickpayViewModel AutoEquatableForTest

extension QuickpayViewModel: @retroactive Equatable {}
public func == (lhs: QuickpayViewModel, rhs: QuickpayViewModel) -> Bool {
    guard lhs.avatar == rhs.avatar else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.subtitle == rhs.subtitle else { return false }
    guard compareOptionals(lhs: lhs.footerAction, rhs: rhs.footerAction, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.nudge, rhs: rhs.nudge, compare: ==) else { return false }
    guard lhs.qrCode == rhs.qrCode else { return false }
    guard lhs.navigationBarButtons == rhs.navigationBarButtons else { return false }
    guard lhs.circularButtons == rhs.circularButtons else { return false }
    guard lhs.cardItems == rhs.cardItems else { return false }
    return true
}

// MARK: - QuickpayViewModel.ButtonViewModel AutoEquatableForTest

extension QuickpayViewModel.ButtonViewModel: @retroactive Equatable {}
public func == (lhs: QuickpayViewModel.ButtonViewModel, rhs: QuickpayViewModel.ButtonViewModel) -> Bool {
    guard lhs.icon == rhs.icon else { return false }
    guard lhs.title == rhs.title else { return false }
    return true
}

// MARK: - RequestMoneyContactPickerViewModel AutoEquatableForTest

extension RequestMoneyContactPickerViewModel: @retroactive Equatable {}
public func == (lhs: RequestMoneyContactPickerViewModel, rhs: RequestMoneyContactPickerViewModel) -> Bool {
    guard lhs.titleViewModel == rhs.titleViewModel else { return false }
    guard lhs.sections == rhs.sections else { return false }
    return true
}

// MARK: - RequestMoneyContactPickerViewModel.Section AutoEquatableForTest

extension RequestMoneyContactPickerViewModel.Section: @retroactive Equatable {}
public func == (lhs: RequestMoneyContactPickerViewModel.Section, rhs: RequestMoneyContactPickerViewModel.Section) -> Bool {
    guard compareOptionals(lhs: lhs.viewModel, rhs: rhs.viewModel, compare: ==) else { return false }
    guard lhs.isSectionHeaderHidden == rhs.isSectionHeaderHidden else { return false }
    guard lhs.cells == rhs.cells else { return false }
    return true
}

// MARK: - RequestMoneyPayWithWiseEducationViewModel AutoEquatableForTest

extension RequestMoneyPayWithWiseEducationViewModel: @retroactive Equatable {}
public func == (lhs: RequestMoneyPayWithWiseEducationViewModel, rhs: RequestMoneyPayWithWiseEducationViewModel) -> Bool {
    guard lhs.image == rhs.image else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.subtitle == rhs.subtitle else { return false }
    guard compareOptionals(lhs: lhs.description, rhs: rhs.description, compare: ==) else { return false }
    guard lhs.action == rhs.action else { return false }
    return true
}

// MARK: - RequestMoneyPayWithWiseEducationViewModel.MarkupLabel AutoEquatableForTest

extension RequestMoneyPayWithWiseEducationViewModel.MarkupLabel: @retroactive Equatable {}
public func == (
    lhs: RequestMoneyPayWithWiseEducationViewModel.MarkupLabel,
    rhs: RequestMoneyPayWithWiseEducationViewModel.MarkupLabel
) -> Bool {
    guard lhs.text == rhs.text else { return false }
    return true
}

// MARK: - RequestPaymentFromAnyoneViewModel AutoEquatableForTest

extension RequestPaymentFromAnyoneViewModel: @retroactive Equatable {}
public func == (lhs: RequestPaymentFromAnyoneViewModel, rhs: RequestPaymentFromAnyoneViewModel) -> Bool {
    guard lhs.titleViewModel == rhs.titleViewModel else { return false }
    guard lhs.qrCodeViewModel == rhs.qrCodeViewModel else { return false }
    guard lhs.doneAction == rhs.doneAction else { return false }
    guard lhs.primaryActionFooter == rhs.primaryActionFooter else { return false }
    guard lhs.secondaryActionFooter == rhs.secondaryActionFooter else { return false }
    return true
}

// MARK: - WisetagContactOnWiseViewModel AutoEquatableForTest

extension WisetagContactOnWiseViewModel: @retroactive Equatable {}
public func == (lhs: WisetagContactOnWiseViewModel, rhs: WisetagContactOnWiseViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard lhs.subtitle == rhs.subtitle else { return false }
    guard compareOptionals(lhs: lhs.inlineAlert, rhs: rhs.inlineAlert, compare: ==) else { return false }
    guard lhs.wisetagOption == rhs.wisetagOption else { return false }
    guard lhs.action == rhs.action else { return false }
    return true
}

// MARK: - WisetagContactOnWiseViewModel.Alert AutoEquatableForTest

extension WisetagContactOnWiseViewModel.Alert: @retroactive Equatable {}
public func == (lhs: WisetagContactOnWiseViewModel.Alert, rhs: WisetagContactOnWiseViewModel.Alert) -> Bool {
    guard lhs.viewModel == rhs.viewModel else { return false }
    guard lhs.style == rhs.style else { return false }
    return true
}

// MARK: - WisetagContactOnWiseViewModel.SwitchOption AutoEquatableForTest

extension WisetagContactOnWiseViewModel.SwitchOption: @retroactive Equatable {}
public func == (lhs: WisetagContactOnWiseViewModel.SwitchOption, rhs: WisetagContactOnWiseViewModel.SwitchOption) -> Bool {
    guard lhs.viewModel == rhs.viewModel else { return false }
    return true
}

// MARK: - WisetagHeaderViewModel AutoEquatableForTest

extension WisetagHeaderViewModel: @retroactive Equatable {}
public func == (lhs: WisetagHeaderViewModel, rhs: WisetagHeaderViewModel) -> Bool {
    guard lhs.avatar == rhs.avatar else { return false }
    guard lhs.title == rhs.title else { return false }
    return true
}

// MARK: - WisetagScannedProfileViewModel AutoEquatableForTest

extension WisetagScannedProfileViewModel: @retroactive Equatable {}
public func == (lhs: WisetagScannedProfileViewModel, rhs: WisetagScannedProfileViewModel) -> Bool {
    guard compareOptionals(lhs: lhs.header, rhs: rhs.header, compare: ==) else { return false }
    guard lhs.footer == rhs.footer else { return false }
    return true
}

// MARK: - WisetagScannedProfileViewModel.ButtonViewModel AutoEquatableForTest

extension WisetagScannedProfileViewModel.ButtonViewModel: @retroactive Equatable {}
public func == (lhs: WisetagScannedProfileViewModel.ButtonViewModel, rhs: WisetagScannedProfileViewModel.ButtonViewModel) -> Bool {
    guard lhs.icon == rhs.icon else { return false }
    guard lhs.title == rhs.title else { return false }
    guard lhs.enabled == rhs.enabled else { return false }
    return true
}

// MARK: - WisetagScannedProfileViewModel.FooterViewModel AutoEquatableForTest

extension WisetagScannedProfileViewModel.FooterViewModel: @retroactive Equatable {}
public func == (lhs: WisetagScannedProfileViewModel.FooterViewModel, rhs: WisetagScannedProfileViewModel.FooterViewModel) -> Bool {
    guard compareOptionals(lhs: lhs.buttons, rhs: rhs.buttons, compare: ==) else { return false }
    guard lhs.isLoading == rhs.isLoading else { return false }
    return true
}

// MARK: - WisetagScannedProfileViewModel.HeaderViewModel AutoEquatableForTest

extension WisetagScannedProfileViewModel.HeaderViewModel: @retroactive Equatable {}
public func == (lhs: WisetagScannedProfileViewModel.HeaderViewModel, rhs: WisetagScannedProfileViewModel.HeaderViewModel) -> Bool {
    guard lhs.title == rhs.title else { return false }
    guard compareOptionals(lhs: lhs.subtitle, rhs: rhs.subtitle, compare: ==) else { return false }
    guard compareOptionals(lhs: lhs.alert, rhs: rhs.alert, compare: ==) else { return false }
    return true
}

// MARK: - WisetagScannedProfileViewModel.HeaderViewModel.Alert AutoEquatableForTest

extension WisetagScannedProfileViewModel.HeaderViewModel.Alert: @retroactive Equatable {}
public func == (
    lhs: WisetagScannedProfileViewModel.HeaderViewModel.Alert,
    rhs: WisetagScannedProfileViewModel.HeaderViewModel.Alert
) -> Bool {
    guard lhs.style == rhs.style else { return false }
    guard lhs.viewModel == rhs.viewModel else { return false }
    return true
}

// MARK: - WisetagViewModel AutoEquatableForTest

extension WisetagViewModel: @retroactive Equatable {}
public func == (lhs: WisetagViewModel, rhs: WisetagViewModel) -> Bool {
    guard lhs.header == rhs.header else { return false }
    guard lhs.qrCode == rhs.qrCode else { return false }
    guard lhs.shareButtons == rhs.shareButtons else { return false }
    guard compareOptionals(lhs: lhs.footerAction, rhs: rhs.footerAction, compare: ==) else { return false }
    guard lhs.navigationBarButtons == rhs.navigationBarButtons else { return false }
    return true
}

// MARK: - WisetagViewModel.ButtonViewModel AutoEquatableForTest

extension WisetagViewModel.ButtonViewModel: @retroactive Equatable {}
public func == (lhs: WisetagViewModel.ButtonViewModel, rhs: WisetagViewModel.ButtonViewModel) -> Bool {
    guard lhs.icon == rhs.icon else { return false }
    guard lhs.title == rhs.title else { return false }
    return true
}

// MARK: - AutoEquatableForTest for Enums

// MARK: - CreatePaymentRequestFlowResult AutoEquatableForTest

extension CreatePaymentRequestFlowResult: @retroactive Equatable {}
public func == (lhs: CreatePaymentRequestFlowResult, rhs: CreatePaymentRequestFlowResult) -> Bool {
    switch (lhs, rhs) {
    case let (.success(lhsPaymentRequestId, lhsContext), .success(rhsPaymentRequestId, rhsContext)):
        if lhsPaymentRequestId != rhsPaymentRequestId { return false }
        if lhsContext != rhsContext { return false }
        return true
    case (.aborted, .aborted):
        return true
    default: return false
    }
}

// MARK: - CreatePaymentRequestMethodManagementViewModel.OptionViewModel AutoEquatableForTest

extension CreatePaymentRequestMethodManagementViewModel.OptionViewModel: @retroactive Equatable {}
public func == (
    lhs: CreatePaymentRequestMethodManagementViewModel.OptionViewModel,
    rhs: CreatePaymentRequestMethodManagementViewModel.OptionViewModel
) -> Bool {
    switch (lhs, rhs) {
    case let (.switchOptionViewModel(lhs), .switchOptionViewModel(rhs)):
        lhs == rhs
    case let (.payWithWiseOptionViewModel(lhs), .payWithWiseOptionViewModel(rhs)):
        lhs == rhs
    case let (.actionOptionViewModel(lhs), .actionOptionViewModel(rhs)):
        lhs == rhs
    default: false
    }
}

// MARK: - PayWithWiseAnalyticsEvent AutoEquatableForTest

extension PayWithWiseAnalyticsEvent: @retroactive Equatable {}
public func == (lhs: PayWithWiseAnalyticsEvent, rhs: PayWithWiseAnalyticsEvent) -> Bool {
    switch (lhs, rhs) {
    case let (
        .balanceSelected(
            lhsRequestCurrency,
            lhsPaymentCurrency,
            lhsIsSameCurrency,
            lhsRequestCurrencyBalanceExists,
            lhsRequestCurrencyBalanceHasEnough
        ),
        .balanceSelected(
            rhsRequestCurrency,
            rhsPaymentCurrency,
            rhsIsSameCurrency,
            rhsRequestCurrencyBalanceExists,
            rhsRequestCurrencyBalanceHasEnough
        )
    ):
        if lhsRequestCurrency != rhsRequestCurrency { return false }
        if lhsPaymentCurrency != rhsPaymentCurrency { return false }
        if lhsIsSameCurrency != rhsIsSameCurrency { return false }
        if lhsRequestCurrencyBalanceExists != rhsRequestCurrencyBalanceExists { return false }
        if lhsRequestCurrencyBalanceHasEnough != rhsRequestCurrencyBalanceHasEnough { return false }
        return true
    case let (.balanceSelectorOpened(lhs), .balanceSelectorOpened(rhs)):
        return lhs == rhs
    case (.declineConfirmed, .declineConfirmed):
        return true
    case let (.declineTapped(lhs), .declineTapped(rhs)):
        return lhs == rhs
    case let (
        .loaded(
            lhsRequestCurrency,
            lhsPaymentCurrency,
            lhsIsSameCurrency,
            lhsRequestCurrencyBalanceExists,
            lhsRequestCurrencyBalanceHasEnough,
            lhsErrorCode,
            lhsErrorMessage
        ),
        .loaded(
            rhsRequestCurrency,
            rhsPaymentCurrency,
            rhsIsSameCurrency,
            rhsRequestCurrencyBalanceExists,
            rhsRequestCurrencyBalanceHasEnough,
            rhsErrorCode,
            rhsErrorMessage
        )
    ):
        if lhsRequestCurrency != rhsRequestCurrency { return false }
        if lhsPaymentCurrency != rhsPaymentCurrency { return false }
        if lhsIsSameCurrency != rhsIsSameCurrency { return false }
        if lhsRequestCurrencyBalanceExists != rhsRequestCurrencyBalanceExists { return false }
        if lhsRequestCurrencyBalanceHasEnough != rhsRequestCurrencyBalanceHasEnough { return false }
        if lhsErrorCode != rhsErrorCode { return false }
        if lhsErrorMessage != rhsErrorMessage { return false }
        return true
    case let (.loadedWithError(lhsErrorCode, lhsErrorKey), .loadedWithError(rhsErrorCode, rhsErrorKey)):
        if lhsErrorCode != rhsErrorCode { return false }
        if lhsErrorKey != rhsErrorKey { return false }
        return true
    case let (
        .payAnotherWayTapped(lhsRequestCurrency, lhsRequestCurrencyBalanceExists, lhsRequestCurrencyBalanceHasEnough),
        .payAnotherWayTapped(rhsRequestCurrency, rhsRequestCurrencyBalanceExists, rhsRequestCurrencyBalanceHasEnough)
    ):
        if lhsRequestCurrency != rhsRequestCurrency { return false }
        if lhsRequestCurrencyBalanceExists != rhsRequestCurrencyBalanceExists { return false }
        if lhsRequestCurrencyBalanceHasEnough != rhsRequestCurrencyBalanceHasEnough { return false }
        return true
    case let (.payFailed(lhsPaymentRequestId, lhsMessage), .payFailed(rhsPaymentRequestId, rhsMessage)):
        if lhsPaymentRequestId != rhsPaymentRequestId { return false }
        if lhsMessage != rhsMessage { return false }
        return true
    case let (
        .payTapped(lhsRequestCurrency, lhsPaymentCurrency, lhsProfileType),
        .payTapped(rhsRequestCurrency, rhsPaymentCurrency, rhsProfileType)
    ):
        if lhsRequestCurrency != rhsRequestCurrency { return false }
        if lhsPaymentCurrency != rhsPaymentCurrency { return false }
        if lhsProfileType != rhsProfileType { return false }
        return true
    case let (.profileChanged(lhs), .profileChanged(rhs)):
        return lhs == rhs
    case let (
        .quoteCreated(lhsSuccess, lhsRequestCurrency, lhsPaymentCurrency, lhsAmount),
        .quoteCreated(rhsSuccess, rhsRequestCurrency, rhsPaymentCurrency, rhsAmount)
    ):
        if lhsSuccess != rhsSuccess { return false }
        if lhsRequestCurrency != rhsRequestCurrency { return false }
        if lhsPaymentCurrency != rhsPaymentCurrency { return false }
        if lhsAmount != rhsAmount { return false }
        return true
    case let (
        .paySucceed(lhsRequestType, lhsRequestCurrency, lhsPaymentCurrency),
        .paySucceed(rhsRequestType, rhsRequestCurrency, rhsPaymentCurrency)
    ):
        if lhsRequestType != rhsRequestType { return false }
        if lhsRequestCurrency != rhsRequestCurrency { return false }
        if lhsPaymentCurrency != rhsPaymentCurrency { return false }
        return true
    case let (.topUpCompleted(lhs), .topUpCompleted(rhs)):
        return lhs == rhs
    case (.topUpTapped, .topUpTapped):
        return true
    case let (.attachmentLoadingFailed(lhs), .attachmentLoadingFailed(rhs)):
        return lhs == rhs
    case (.viewAttachmentTapped, .viewAttachmentTapped):
        return true
    case (.viewDetailsTapped, .viewDetailsTapped):
        return true
    default: return false
    }
}

// MARK: - PayerScreenAnalyticsEvent AutoEquatableForTest

extension PayerScreenAnalyticsEvent: @retroactive Equatable {}
public func == (lhs: PayerScreenAnalyticsEvent, rhs: PayerScreenAnalyticsEvent) -> Bool {
    switch (lhs, rhs) {
    case (.startedLoggedIn, .startedLoggedIn):
        return true
    case let (.started(lhsContext, lhsPaymentRequestType, lhsCurrency), .started(rhsContext, rhsPaymentRequestType, rhsCurrency)):
        if lhsContext != rhsContext { return false }
        if lhsPaymentRequestType != rhsPaymentRequestType { return false }
        if lhsCurrency != rhsCurrency { return false }
        return true
    case let (.paymentMethodSelected(lhs), .paymentMethodSelected(rhs)):
        return lhs == rhs
    default: return false
    }
}

// MARK: - PaymentDetailsViewModel.Item AutoEquatableForTest

extension PaymentDetailsViewModel.Item: @retroactive Equatable {}
public func == (lhs: PaymentDetailsViewModel.Item, rhs: PaymentDetailsViewModel.Item) -> Bool {
    switch (lhs, rhs) {
    case let (.listItem(lhs), .listItem(rhs)):
        lhs == rhs
    case (.separator, .separator):
        true
    default: false
    }
}

// MARK: - PaymentLinkAllPaymentsViewModel.Content AutoEquatableForTest

extension PaymentLinkAllPaymentsViewModel.Content: @retroactive Equatable {}
public func == (lhs: PaymentLinkAllPaymentsViewModel.Content, rhs: PaymentLinkAllPaymentsViewModel.Content) -> Bool {
    switch (lhs, rhs) {
    case let (.empty(lhs), .empty(rhs)):
        lhs == rhs
    case let (.sections(lhs), .sections(rhs)):
        lhs == rhs
    default: false
    }
}

// MARK: - PaymentLinkPaymentDetailsViewModel.Section.Item AutoEquatableForTest

extension PaymentLinkPaymentDetailsViewModel.Section.Item: @retroactive Equatable {}
public func == (lhs: PaymentLinkPaymentDetailsViewModel.Section.Item, rhs: PaymentLinkPaymentDetailsViewModel.Section.Item) -> Bool {
    switch (lhs, rhs) {
    case let (.optionItem(lhs), .optionItem(rhs)):
        lhs == rhs
    case let (.listItem(lhs), .listItem(rhs)):
        lhs == rhs
    default: false
    }
}

// MARK: - PaymentLinkSharingViewAction AutoEquatableForTest

extension PaymentLinkSharingViewAction: @retroactive Equatable {}
public func == (lhs: PaymentLinkSharingViewAction, rhs: PaymentLinkSharingViewAction) -> Bool {
    switch (lhs, rhs) {
    case let (.shareLink(lhs), .shareLink(rhs)):
        lhs == rhs
    case let (.viewPaymentRequest(lhs), .viewPaymentRequest(rhs)):
        lhs == rhs
    default: false
    }
}

// MARK: - PaymentRequestDetailViewModel.SectionViewModel.ItemViewModel AutoEquatableForTest

extension PaymentRequestDetailViewModel.SectionViewModel.ItemViewModel: @retroactive Equatable {}
public func == (
    lhs: PaymentRequestDetailViewModel.SectionViewModel.ItemViewModel,
    rhs: PaymentRequestDetailViewModel.SectionViewModel.ItemViewModel
) -> Bool {
    switch (lhs, rhs) {
    case let (.listItem(lhs), .listItem(rhs)):
        lhs == rhs
    case let (.optionItem(lhs), .optionItem(rhs)):
        lhs == rhs
    default: false
    }
}

// MARK: - PaymentRequestsListViewModel AutoEquatableForTest

extension PaymentRequestsListViewModel: @retroactive Equatable {}
public func == (lhs: PaymentRequestsListViewModel, rhs: PaymentRequestsListViewModel) -> Bool {
    switch (lhs, rhs) {
    case let (.emptyState(lhs), .emptyState(rhs)):
        lhs == rhs
    case let (.paymentRequests(lhs), .paymentRequests(rhs)):
        lhs == rhs
    default: false
    }
}

// MARK: - PaymentRequestsListViewModel.PaymentRequests.Content AutoEquatableForTest

extension PaymentRequestsListViewModel.PaymentRequests.Content: @retroactive Equatable {}
public func == (
    lhs: PaymentRequestsListViewModel.PaymentRequests.Content,
    rhs: PaymentRequestsListViewModel.PaymentRequests.Content
) -> Bool {
    switch (lhs, rhs) {
    case let (.empty(lhs), .empty(rhs)):
        lhs == rhs
    case let (.sections(lhs), .sections(rhs)):
        lhs == rhs
    default: false
    }
}

// MARK: - ReceiveMethodNavigationAction AutoEquatableForTest

extension ReceiveMethodNavigationAction: @retroactive Equatable {}
public func == (lhs: ReceiveMethodNavigationAction, rhs: ReceiveMethodNavigationAction) -> Bool {
    switch (lhs, rhs) {
    case let (.order(lhsCurrency, lhsBalanceId, lhsMethodType), .order(rhsCurrency, rhsBalanceId, rhsMethodType)):
        if lhsCurrency != rhsCurrency { return false }
        if lhsBalanceId != rhsBalanceId { return false }
        if lhsMethodType != rhsMethodType { return false }
        return true
    case let (
        .query(lhsContext, lhsCurrency, lhsGroupId, lhsBalanceId, lhsMethodTypes),
        .query(rhsContext, rhsCurrency, rhsGroupId, rhsBalanceId, rhsMethodTypes)
    ):
        if lhsContext != rhsContext { return false }
        if lhsCurrency != rhsCurrency { return false }
        if lhsGroupId != rhsGroupId { return false }
        if lhsBalanceId != rhsBalanceId { return false }
        if lhsMethodTypes != rhsMethodTypes { return false }
        return true
    case let (.view(lhsId, lhsMethodType), .view(rhsId, rhsMethodType)):
        if lhsId != rhsId { return false }
        if lhsMethodType != rhsMethodType { return false }
        return true
    default: return false
    }
}

// MARK: - RequestMoneyContactPickerViewModel.Cell AutoEquatableForTest

extension RequestMoneyContactPickerViewModel.Cell: @retroactive Equatable {}
public func == (lhs: RequestMoneyContactPickerViewModel.Cell, rhs: RequestMoneyContactPickerViewModel.Cell) -> Bool {
    switch (lhs, rhs) {
    case (.search, .search):
        true
    case let (.optionItem(lhs), .optionItem(rhs)):
        lhs == rhs
    case let (.noContacts(lhs), .noContacts(rhs)):
        lhs == rhs
    case let (.contact(lhs), .contact(rhs)):
        lhs == rhs
    case let (.recentContacts(lhs), .recentContacts(rhs)):
        lhs == rhs
    case let (.nudge(lhs), .nudge(rhs)):
        lhs == rhs
    case (.spacingBetweenNudgeAndOption, .spacingBetweenNudgeAndOption):
        true
    default: false
    }
}

// MARK: - WisetagNextStep AutoEquatableForTest

extension WisetagNextStep: @retroactive Equatable {}
public func == (lhs: WisetagNextStep, rhs: WisetagNextStep) -> Bool {
    switch (lhs, rhs) {
    case (.showStory, .showStory):
        return true
    case (.showADFlow, .showADFlow):
        return true
    case let (.showWisetag(lhsImage, lhsStatus, lhsIsCardsEnabled), .showWisetag(rhsImage, rhsStatus, rhsIsCardsEnabled)):
        if lhsImage != rhsImage { return false }
        if lhsStatus != rhsStatus { return false }
        if lhsIsCardsEnabled != rhsIsCardsEnabled { return false }
        return true
    default: return false
    }
}

// MARK: -

// swiftlint:enable file_length
// swiftlint:enable cyclomatic_complexity
