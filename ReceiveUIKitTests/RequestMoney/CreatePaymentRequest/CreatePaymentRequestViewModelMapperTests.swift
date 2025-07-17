import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport
import WiseCore

final class CreatePaymentRequestViewModelMapperTests: TWTestCase {
    private let businessProfile = Profile.business(FakeBusinessProfileInfo())
    private let amount: Decimal = 0.07
    private let amountString = "0.07"
    private let currency = CurrencyCode.EUR
    private let balanceId = BalanceId(123)
    private let reference = "123456789"
    private let productDescription = LoremIpsum.medium
    private let paymentRequestId = PaymentRequestId("WXYZ-ABCD-1234-5678")

    private let mapper = CreatePaymentRequestViewModelMapperImpl()

    func test_make_forCreating_givenBusinessProfile_WithReusableDisabled_thenReturnCorrectModel() {
        let paymentRequestInfo = makePaymentRequestInfoForCreating()

        let viewModel = mapper.make(
            shouldShowPaymentLimitsCheckbox: false,
            isLimitPaymentsSelected: false,
            paymentRequestInfo: paymentRequestInfo,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: ._icon(Icons.fastFlag.image, badge: nil)),
                onTap: {}
            ),
            nudge: nil
        )

        let expected = makeViewModelForBusinessOnCreationForReusableDisabled()
        expectNoDifference(viewModel, expected)
    }

    func test_make_forCreating_givenBusinessProfile_WithSingleRequestType_thenReturnCorrectModel() {
        let paymentRequestInfo = makePaymentRequestInfoForCreating()

        let viewModel = mapper.make(
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: true,
            paymentRequestInfo: paymentRequestInfo,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: ._icon(Icons.fastFlag.image, badge: nil)),
                onTap: {}
            ),
            nudge: nil
        )

        let expected = makeViewModelForBusinessOnCreationForSingleUse()
        expectNoDifference(viewModel, expected)
    }

    func test_make_forCreating_givenBusinessProfile_withReusableRequestType_thenReturnCorrectModel() {
        let paymentRequestInfo = makePaymentRequestInfoForCreating()

        let viewModel = mapper.make(
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: false,
            paymentRequestInfo: paymentRequestInfo,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: ._icon(Icons.fastFlag.image, badge: nil)),
                onTap: {}
            ),
            nudge: nil
        )

        let expected = makeViewModelForBusinessOnCreationForReusable()
        expectNoDifference(viewModel, expected)
    }
}

// MARK: - Helpers

private extension CreatePaymentRequestViewModelMapperTests {
    func makePaymentRequestInfoForCreating() -> CreatePaymentRequestPresenterInfo {
        .init(
            value: amount,
            selectedCurrency: currency,
            eligibleBalances: .build(
                balances: [
                    .build(currency: currency),
                    .build(currency: .GBP),
                ]
            ),
            selectedBalanceId: balanceId,
            reference: reference,
            productDescription: productDescription,
            paymentMethods: [.card]
        )
    }

    func makeViewModelForBusinessOnCreationForReusableDisabled() -> CreatePaymentRequestViewModel {
        CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "Amount",
                shouldSupportDecimals: true,
                amount: amountString,
                placeholderAmount: nil,
                isEditable: true,
                currencyName: "EUR",
                currencyAccessibilityName: "Euro",
                flagImage: CurrencyCode("EUR").icon,
                panelText: .none
            ),
            currencySelectorEnabled: true,
            shouldShowPaymentLimitsCheckbox: false,
            isLimitPaymentsSelected: false,
            productDescription: productDescription,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: ._icon(Icons.fastFlag.image, badge: nil)),
                onTap: {}
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        )
    }

    func makeViewModelForBusinessOnCreationForSingleUse() -> CreatePaymentRequestViewModel {
        CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "Amount",
                shouldSupportDecimals: true,
                amount: amountString,
                placeholderAmount: nil,
                isEditable: true,
                currencyName: "EUR",
                currencyAccessibilityName: "Euro",
                flagImage: CurrencyCode("EUR").icon,
                panelText: .none
            ),
            currencySelectorEnabled: true,
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: true,
            productDescription: productDescription,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: ._icon(Icons.fastFlag.image, badge: nil)),
                onTap: {}
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        )
    }

    func makeViewModelForBusinessOnCreationForReusable() -> CreatePaymentRequestViewModel {
        CreatePaymentRequestViewModel(
            titleViewModel: LargeTitleViewModel(title: "Create payment link"),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "Amount",
                shouldSupportDecimals: true,
                amount: amountString,
                placeholderAmount: nil,
                isEditable: true,
                currencyName: "EUR",
                currencyAccessibilityName: "Euro",
                flagImage: CurrencyCode("EUR").icon,
                panelText: .none
            ),
            currencySelectorEnabled: true,
            shouldShowPaymentLimitsCheckbox: true,
            isLimitPaymentsSelected: false,
            productDescription: productDescription,
            paymentMethodsOption: .init(
                viewModel: .init(title: "Payment methods", avatar: ._icon(Icons.fastFlag.image, badge: nil)),
                onTap: {}
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create"
        )
    }
}
