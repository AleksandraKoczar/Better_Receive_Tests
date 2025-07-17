import Foundation
import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class CreatePaymentRequestViewControllerTests: TWSnapshotTestCase {
    func test_screenWithSingleCurrency_andCheckboxEnabled() {
        let presenter = CreatePaymentRequestPresenterMock()
        let vc = CreatePaymentRequestViewController(presenter: presenter)

        vc.configure(with: CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: false,
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: true,
            productDescription: nil,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: .canned),
                onTap: {}
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }

    func test_screenWithSingleCurrency_andCheckboxDisabled() {
        let presenter = CreatePaymentRequestPresenterMock()
        let vc = CreatePaymentRequestViewController(presenter: presenter)

        vc.configure(with: CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: false,
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: false,
            productDescription: nil,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: .canned),
                onTap: {}
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }

    func test_screen_withSelectableCurrencies_andCheckboxEnabled() {
        let presenter = CreatePaymentRequestPresenterMock()
        let vc = CreatePaymentRequestViewController(presenter: presenter)

        vc.configure(with: CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: true,
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: true,
            productDescription: nil,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: .canned),
                onTap: {}
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }

    func test_screen_withProductDescirption_andCheckboxEnabled() {
        let presenter = CreatePaymentRequestPresenterMock()
        let vc = CreatePaymentRequestViewController(presenter: presenter)

        vc.configure(with: CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: true,
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: true,
            productDescription: "test",
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: .canned),
                onTap: {}
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }

    func test_screen_WithProductDescription_andCheckboxDisabled() {
        let presenter = CreatePaymentRequestPresenterMock()
        let vc = CreatePaymentRequestViewController(presenter: presenter)

        vc.configure(with: CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: true,
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: false,
            productDescription: "test",
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: .canned),
                onTap: {}
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }

    func test_screen_WithProductDescription_andCheckboxDisabled_andNudgeEnabled() {
        let presenter = CreatePaymentRequestPresenterMock()
        let vc = CreatePaymentRequestViewController(presenter: presenter)

        vc.configure(with: CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: true,
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: false,
            productDescription: "test",
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: .canned),
                onTap: {}
            ),
            nudge: .init(title: "Get cards", asset: .businessCard, ctaTitle: "Setup", onSelect: {}, onDismiss: {}),
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        ))
        vc.updateNudge(.init(title: "Get cards", asset: .businessCard, ctaTitle: "Setup", onSelect: {}, onDismiss: {}))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }
}
