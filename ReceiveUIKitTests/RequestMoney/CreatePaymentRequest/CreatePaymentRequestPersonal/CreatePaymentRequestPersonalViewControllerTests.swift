import Foundation
import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class CreatePaymentRequestPersonalViewControllerTests: TWSnapshotTestCase {
    func test_screenWithSingleCurrency() {
        let vc = CreatePaymentRequestPersonalViewController(presenter: CreatePaymentRequestPersonalPresenterMock())
        vc.configure(with: CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(title: "This is the title", description: "the subtitle"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: false,
            message: LoremIpsum.long,
            alert: nil,
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Continue"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }

    func test_screen_withSelectableCurrencies() {
        let vc = CreatePaymentRequestPersonalViewController(presenter: CreatePaymentRequestPersonalPresenterMock())

        vc.configure(with: CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(title: "This is the title", description: "the subtitle"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: true,
            message: LoremIpsum.long,
            alert: nil,
            nudge: nil,
            footerButtonEnabled: true,
            footerButtonTitle: "Continue"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }

    func test_screen_personal() {
        let vc = CreatePaymentRequestPersonalViewController(presenter: CreatePaymentRequestPersonalPresenterMock())
        vc.configure(with: CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(title: "This is the title", description: "the subtitle"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: true,
            message: LoremIpsum.long,
            alert: nil,
            nudge: CreatePaymentRequestPersonalViewModel.Nudge(
                title: "Get paid free and instantly, if your contact uses Pay with Wise.",
                icon: .wallet,
                ctaTitle: "Learn more"
            ),
            footerButtonEnabled: true,
            footerButtonTitle: "Continue"
        ))
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }

    func test_screen_personal_withContact_AndNudge_AndAlert() {
        let vc = CreatePaymentRequestPersonalViewController(presenter: CreatePaymentRequestPersonalPresenterMock())
        vc.configure(with: CreatePaymentRequestPersonalViewModel(
            titleViewModel: LargeTitleViewModel(title: "This is the title", description: "the subtitle"),
            moneyInputViewModel: MoneyInputViewModel(currencyName: CurrencyCode.EUR.value, flagImage: CurrencyCode.EUR.icon),
            currencySelectorEnabled: true,
            message: LoremIpsum.long,
            alert: CreatePaymentRequestPersonalViewModel.Alert(
                style: .warning,
                viewModel: InlineAlertViewModel(title: "title", message: "message", action: nil)
            ),
            nudge: CreatePaymentRequestPersonalViewModel.Nudge(
                title: "Get paid free and instantly, if your contact uses Pay with Wise.",
                icon: .wallet,
                ctaTitle: "Learn more"
            ),
            footerButtonEnabled: true,
            footerButtonTitle: "Continue"
        ))
        vc.configureContact(
            with: OptionViewModel(
                title: "Wise acc",
                subtitle: "Jane Doe",
                avatar: AvatarViewModel.icon(Icons.giftBox.image)
            )
        )
        TWSnapshotVerifyViewController(vc.navigationWrapped())
    }
}
