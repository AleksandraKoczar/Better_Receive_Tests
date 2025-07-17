@testable import ReceiveUIKit
import TWFoundation
import WiseCore

final class AccountDetailsMultipleSelectionPresenterMock: AccountDetailsMultipleSelectionPresenter {
    var startCalled = false
    var lastSearchQueryValue: String?
    var lastCurrencyTapped: CurrencyCode?
    var continueButtonTappedCalled = false
    var currenciesSelected: [CurrencyCode] = []
    var sectionHeaderTappedCalled = false
    var secondaryActionTappedCalled = false

    func start(withView view: AccountDetailsMultipleSelectionView) {
        startCalled = true
    }

    func searchQueryUpdated(_ text: String) {
        lastSearchQueryValue = text
    }

    func cellTapped(currencyCode: CurrencyCode) {
        lastCurrencyTapped = currencyCode
    }

    func continueButtonTapped() {
        continueButtonTappedCalled = true
    }

    func secondaryActionTapped() {
        secondaryActionTappedCalled = true
    }

    func sectionHeaderTapped() {
        sectionHeaderTappedCalled = true
    }

    func isCurrencySelected(_ currencyCode: CurrencyCode) -> Bool {
        currenciesSelected.contains(currencyCode)
    }
}
