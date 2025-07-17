import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport
import WiseCore

final class CreatePaymentRequestPersonalViewModelMapperTests: TWTestCase {
    private let amount: Decimal = 0.07
    private let amountString = "0.07"
    private let currency = CurrencyCode.GBP
    private let balanceId = BalanceId(123)
    private let message = LoremIpsum.long
    private let paymentRequestId = PaymentRequestId("WXYZ-ABCD-1234-5678")
    private let payerId = "beefblob-beef-blob-beef-blobbeefblob"

    private let mapper = CreatePaymentRequestPersonalViewModelMapperImpl()

    func test_make_forCreating_givenPersonalProfile_andNudgeDoesNotShow() {
        let paymentRequestInfo = makePaymentRequestInfoForCreating()
        let viewModel = mapper.make(
            contactName: "Jane Doe",
            paymentRequestInfo: paymentRequestInfo,
            shouldShowNudge: false
        )

        let expected = makeViewModelForPersonalOnCreation(nudge: nil)
        expectNoDifference(viewModel, expected)
    }

    func test_make_forCreating_givenPersonalProfile_andNudgeShows() {
        let paymentRequestInfo = makePaymentRequestInfoForCreating()
        let viewModel = mapper.make(
            contactName: "Jane Doe",
            paymentRequestInfo: paymentRequestInfo,
            shouldShowNudge: true
        )

        let expected = makeViewModelForPersonalOnCreation(
            nudge: .init(
                title: "Get paid free and instantly, if your contact uses Pay with Wise.",
                icon: .wallet,
                ctaTitle: "Learn more"
            )
        )
        expectNoDifference(viewModel, expected)
    }
}

// MARK: - Helpers

private extension CreatePaymentRequestPersonalViewModelMapperTests {
    func makePaymentRequestInfoForCreating() -> CreatePaymentRequestPersonalPresenterInfo {
        .init(
            contact: RequestMoneyContact.canned,
            value: amount,
            selectedCurrency: currency,
            eligibleBalances: .build(
                balances: [
                    .build(currency: currency),
                    .build(currency: .EUR),
                ],
                eligibilities: [
                    .build(currency: .PLN, eligibleForBalance: true, eligibleForAccountDetails: true),
                    .build(currency: .BRL, eligibleForBalance: true, eligibleForAccountDetails: true),
                ]
            ),
            selectedBalanceId: balanceId,
            message: message,
            paymentMethods: [.card]
        )
    }

    func makeViewModelForPersonalOnCreation(
        nudge: CreatePaymentRequestPersonalViewModel.Nudge?
    ) -> CreatePaymentRequestPersonalViewModel {
        CreatePaymentRequestPersonalViewModel(
            titleViewModel: .init(
                title: "What's your request for?",
                description: "We’ll share this with Jane Doe to pay you."
            ),
            moneyInputViewModel: .init(
                titleText: "Amount",
                amount: amountString,
                currencyName: currency.value,
                currencyAccessibilityName: currency.localizedCurrencyName,
                flagImage: currency.icon
            ),
            currencySelectorEnabled: true,
            message: message,
            alert: nil,
            nudge: nudge,
            footerButtonEnabled: true,
            footerButtonTitle: "Send request"
        )
    }
}
