import BalanceKit
import Combine
import Foundation
@testable import ReceiveUIKit
import TransferResources
import TWFoundation
import TWTestingSupportKit
import WiseCore
import XCTest

final class AccountDetailsMultipleSelectionPresenterImplTests: TWTestCase {
    private var presenter: AccountDetailsMultipleSelectionPresenterImpl!
    private let interactor = AccountDetailsMultipleSelectionInteractorMock()
    private var lastRouterAction: AccountDetailsMultipleSelectionRouterAction?
    private var view = AccountDetailsMultipleSelectionViewMock()
    private let accountDetails: [AccountDetails] = [
        .available(.build(currency: .AED)),
        .active(.build(currency: .TRY)),
        .available(.build(currency: .EUR)),
        .available(.build(currency: .GBP)),
        .available(.build(currency: .USD)),
    ]

    override func setUp() {
        super.setUp()
        presenter = makePresenter()
    }

    override func tearDown() {
        presenter = nil
        super.tearDown()
    }

    func testStartWillUpdateView() throws {
        presenter.start(withView: view)
        let displayedHeaderViewModel = try XCTUnwrap(view.lastHeaderViewModel)
        XCTAssertEqual(
            displayedHeaderViewModel.title,
            "Choose your balances"
        )
        XCTAssertEqual(
            displayedHeaderViewModel.description?.text,
            L10n.AccountDetails.MultipleSelection.subtitle
        )
        XCTAssertEqual(
            displayedHeaderViewModel.searchFieldPlaceholder,
            "Search currencies"
        )

        interactor.accountDetailsSubject.send(.loading)
        XCTAssertTrue(view.showHudCalled)
        interactor.accountDetailsSubject.send(.loaded(accountDetails))
        XCTAssertTrue(view.hideHudCalled)
        let displayedViewModel = try XCTUnwrap(view.lastViewModel)
        XCTAssertEqual(displayedViewModel.sections.count, 1)
        let section = displayedViewModel.sections.first
        XCTAssertEqual(
            section?.title,
            "Choose one or more"
        )
        XCTAssertEqual(
            section?.items.count,
            accountDetails.availableDetails().count
        )
    }

    func testPreselectionAndReordering() throws {
        presenter = makePresenter(preselectedCurrencies: [.USD, .GBP])
        presenter.start(withView: view)

        interactor.accountDetailsSubject.send(
            .loaded([
                .available(.build(currency: .AED)),
                .available(.build(currency: .EUR)),
                .available(.build(currency: .GBP)),
                .available(.build(currency: .USD)),
            ])
        )
        let displayedViewModel = try XCTUnwrap(view.lastViewModel)
        let section = displayedViewModel.sections.first
        XCTAssertEqual(section?.items[0].currencyCode, .GBP)
        XCTAssertEqual(section?.items[1].currencyCode, .USD)
        XCTAssertTrue(presenter.isCurrencySelected(.GBP))
        XCTAssertTrue(presenter.isCurrencySelected(.USD))
    }

    func testSelectedCurrencyRemovedFromPreselection() {
        let accountDetails: [AccountDetails] = [
            .available(.build(currency: .AED)),
            .available(.build(currency: .EUR)),
            .available(.build(currency: .GBP)),
            .available(.build(currency: .USD)),
        ]
        presenter = makePresenter(preselectedCurrencies: [.USD, .GBP])
        presenter.start(withView: view)

        interactor.accountDetailsSubject.send(.loaded(accountDetails))
        XCTAssertTrue(presenter.isCurrencySelected(.USD))
        XCTAssertTrue(presenter.isCurrencySelected(.GBP))
        presenter.cellTapped(currencyCode: .USD)
        XCTAssertFalse(presenter.isCurrencySelected(.USD))
        XCTAssertTrue(presenter.isCurrencySelected(.GBP))
        interactor.accountDetailsSubject.send(.loaded(accountDetails))
        XCTAssertFalse(presenter.isCurrencySelected(.USD))
        XCTAssertTrue(presenter.isCurrencySelected(.GBP))
    }

    func testSelectAndDeselectCurrency() {
        presenter.start(withView: view)
        interactor.accountDetailsSubject.send(.loaded(accountDetails))

        view.lastViewModel = nil
        presenter.cellTapped(currencyCode: .AED)
        XCTAssertNotNil(view.lastViewModel)
        XCTAssertTrue(presenter.isCurrencySelected(.AED))
        XCTAssertFalse(presenter.isCurrencySelected(.EUR))
        XCTAssertTrue(view.buttonStateEnabled)

        view.lastViewModel = nil
        presenter.cellTapped(currencyCode: .AED)
        XCTAssertNotNil(view.lastViewModel)
        XCTAssertFalse(presenter.isCurrencySelected(.AED))
        XCTAssertFalse(presenter.isCurrencySelected(.EUR))
        XCTAssertFalse(view.buttonStateEnabled)
    }

    func testTapContinueButton() {
        presenter.start(withView: view)
        interactor.accountDetailsSubject.send(.loaded(accountDetails))

        presenter.cellTapped(currencyCode: .USD)
        presenter.cellTapped(currencyCode: .GBP)
        presenter.continueButtonTapped()

        let expectedAction = AccountDetailsMultipleSelectionRouterAction.currenciesSelected([.USD, .GBP])
        XCTAssertEqual(lastRouterAction, expectedAction)
    }

    func testSearchTextChanged() throws {
        presenter.start(withView: view)
        interactor.accountDetailsSubject.send(.loaded(accountDetails))

        view.lastViewModel = nil
        presenter.searchQueryUpdated("GBP")
        let filteredCurrenciesViewModel = try XCTUnwrap(view.lastViewModel)
        XCTAssertEqual(filteredCurrenciesViewModel.sections.first?.items.count, 1)
        XCTAssertEqual(filteredCurrenciesViewModel.sections.first?.items.first?.currencyCode, .GBP)
    }

    func testLearnMoreTapped() {
        presenter.start(withView: view)
        interactor.accountDetailsSubject.send(.loaded(accountDetails))

        presenter.sectionHeaderTapped()
        XCTAssertEqual(lastRouterAction, .learnMore)
    }

    func testSecondaryActionTapped() {
        presenter.start(withView: view)
        interactor.accountDetailsSubject.send(.loaded(accountDetails))

        presenter.secondaryActionTapped()
        switch lastRouterAction {
        case let .wishList(completion):
            completion()
        default:
            XCTFail()
        }

        XCTAssertEqual(
            view.snackBarPresentedMessage,
            L10n.AccountDetails.List.Request.Snack.title
        )
    }
}

extension AccountDetailsMultipleSelectionPresenterImplTests: AccountDetailsMultipleSelectionRouter {
    func route(action: AccountDetailsMultipleSelectionRouterAction) {
        lastRouterAction = action
    }

    private func makePresenter(
        preselectedCurrencies: [CurrencyCode] = []
    ) -> AccountDetailsMultipleSelectionPresenterImpl {
        .init(
            feeRequirement: nil,
            preselectedCurrencies: preselectedCurrencies,
            interactor: interactor,
            router: self,
            scheduler: .immediate
        )
    }
}
