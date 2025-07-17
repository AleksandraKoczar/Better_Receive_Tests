import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit
import WiseCore
import XCTest

final class AccountDetailsMultipleSelectionViewControllerTests: TWSnapshotTestCase {
    private enum Constants {
        static var currencyImage: UIImage { Icons.barChart.image }
    }

    private let presenter = AccountDetailsMultipleSelectionPresenterMock()
    private var viewController: AccountDetailsMultipleSelectionViewController!
    private var viewModel: AccountDetailsMultipleSelectionViewModel {
        .init(sections: [
            .init(
                title: "Section title",
                actionTitle: "Some action",
                items: [
                    .init(currencyCode: .AED, image: Constants.currencyImage, title: "AED title", description: "AED description"),
                    .init(currencyCode: .EUR, image: Constants.currencyImage, title: "EUR title", description: "EUR description"),
                    .init(currencyCode: .GBP, image: Constants.currencyImage, title: "GBP title", description: "GBP description"),
                    .init(currencyCode: .USD, image: Constants.currencyImage, title: "USD title", description: "USD description"),
                ]
            ),
        ])
    }

    private let headerViewModel = LargeTitleViewModel(
        title: "Multiple selection title",
        description: "Multiple selection description, that can be very long and go on multiple lines",
        searchFieldPlaceholder: "Search something"
    )

    override func setUp() {
        super.setUp()
        viewController = AccountDetailsMultipleSelectionViewController(presenter: presenter)
    }

    func testViewLoadedCallPresenter() {
        viewController.loadViewIfNeeded()
        XCTAssertTrue(presenter.startCalled)
    }

    func testViewButtonDisabled() throws {
        try XCTSkipAlways("Test is freezing, it started after we change configurating  `LargeTitleView` with `searchFieldPlaceholder`")
        viewController.configureHeader(viewModel: headerViewModel)
        viewController.updateList(viewModel: viewModel)
        viewController.updateButtonState(enabled: false)
        TWSnapshotVerifyViewController(viewController)
    }

    func testViewButtonEnabled() throws {
        try XCTSkipAlways("Test is freezing, it started after we change configurating  `LargeTitleView` with `searchFieldPlaceholder`")
        presenter.currenciesSelected = [.AED, .GBP]
        viewController.configureHeader(viewModel: headerViewModel)
        viewController.updateList(viewModel: viewModel)
        viewController.updateButtonState(enabled: true)
        TWSnapshotVerifyViewController(viewController)
    }

    func testSelectRow() {
        viewController.configureHeader(viewModel: headerViewModel)
        viewController.updateList(viewModel: viewModel)
        let indexPath = IndexPath(row: 0, section: 0)
        viewController.tableView(UITableView(), didSelectRowAt: indexPath)
        let expectedCurrencyToSelect = viewModel.sections[indexPath.section].items[indexPath.row]
        XCTAssertEqual(presenter.lastCurrencyTapped, expectedCurrencyToSelect.currencyCode)
    }

    func testDeselectRow() {
        viewController.configureHeader(viewModel: headerViewModel)
        viewController.updateList(viewModel: viewModel)
        let indexPath = IndexPath(row: 0, section: 0)
        viewController.tableView(UITableView(), didDeselectRowAt: indexPath)
        let expectedCurrencyToSelect = viewModel.sections[indexPath.section].items[indexPath.row]
        XCTAssertEqual(presenter.lastCurrencyTapped, expectedCurrencyToSelect.currencyCode)
    }

    func testSearchFieldTextChanged() {
        let value = "some value"
        let textField = UITextField()
        textField.text = value
        viewController.textFieldDidChangeSelection(textField)
        XCTAssertEqual(presenter.lastSearchQueryValue, value)
    }
}
