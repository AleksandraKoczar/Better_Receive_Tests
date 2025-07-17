import Foundation
import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class CreatePaymentRequestPersonalBottomSheetViewControllerTests: TWSnapshotTestCase {
    func test_screenWithSingleCurrency() {
        let vc = CreatePaymentRequestPersonalBottomSheetViewController(presenter: CreatePaymentRequestPersonalPresenterMock())
        vc.configure(with: CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(title: "This is the title", description: "the subtitle"),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "Amount",
                currencyName: CurrencyCode.EUR.value,
                flagImage: CurrencyCode.EUR.icon
            ),
            currencySelectorEnabled: false,
            message: LoremIpsum.long,
            alert: nil,
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create request"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }

    func test_screen_withSelectableCurrencies() {
        let vc = CreatePaymentRequestPersonalBottomSheetViewController(presenter: CreatePaymentRequestPersonalPresenterMock())

        vc.configure(with: CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(title: "This is the title", description: "the subtitle"),
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "Amount",
                currencyName: CurrencyCode.EUR.value,
                flagImage: CurrencyCode.EUR.icon
            ),
            currencySelectorEnabled: true,
            message: LoremIpsum.long,
            alert: CreatePaymentRequestPersonalViewModel.Alert(
                style: .neutral,
                viewModel: InlineAlertViewModel(title: "title", message: "message", action: nil)
            ),
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Create request"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }
}
