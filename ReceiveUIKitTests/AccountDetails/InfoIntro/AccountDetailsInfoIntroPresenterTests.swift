import AnalyticsKitTestingSupport
@testable import BalanceKit
import BalanceKitTestingSupport
import Combine
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWTestingSupportKit
import UserKitTestingSupport
import XCTest

final class AccountDetailsInfoIntroPresenterTests: TWTestCase {
    private enum MockError: LocalizedError {
        case dummy

        var errorDescription: String? {
            "Dummy"
        }
    }

    private enum Constants {
        static let accountDetailsDetailItem = AccountDetailsDetailItem.build(
            description: AccountDetailsDescription(
                title: "Title",
                body: "Description",
                cta: nil
            )
        )
    }

    private var presenter: AccountDetailsInfoIntroPresenter!
    private var view: AccountDetailsInfoIntroViewMock!
    private var router: AccountDetailsInfoIntroRouterMock!
    private var accountDetailsUseCase: AccountDetailsUseCaseMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var mockAccountDetailsPublisher: CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>!

    override func setUp() {
        super.setUp()

        view = AccountDetailsInfoIntroViewMock()
        router = AccountDetailsInfoIntroRouterMock()
        mockAccountDetailsPublisher = CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>(nil)

        accountDetailsUseCase = AccountDetailsUseCaseMock()
        accountDetailsUseCase.accountDetails = mockAccountDetailsPublisher.eraseToAnyPublisher()
        analyticsTracker = StubAnalyticsTracker()

        presenter = makePresenter(showSummary: true)
    }

    override func tearDown() {
        presenter = nil
        view = nil
        router = nil
        accountDetailsUseCase = nil
        mockAccountDetailsPublisher = nil
        analyticsTracker = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension AccountDetailsInfoIntroPresenterTests {
    func testLoadingAccountDetails_WhenViewStarted_ThenRowsCountMatch() {
        presenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded(Self.makeAccountDetails(repeatingDetailCount: 2)))

        XCTAssertEqual(view.configureReceivedViewModel?.infoViewModel?.rows.count, 2)
    }

    func testLoadingAccountDetails_GivenViewStarted_WhenMultipleRows_ThenMaxRowCountDisplayed() {
        presenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded(Self.makeAccountDetails(repeatingDetailCount: 5)))

        XCTAssertEqual(view.configureReceivedViewModel?.infoViewModel?.rows.count, 3)
    }

    func testLoadingAccountDetails_GivenViewStarted_WhenNoSummary_ThenNoRowsDisplayed() {
        presenter = makePresenter(showSummary: false)
        presenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded(Self.makeAccountDetails(repeatingDetailCount: 5)))

        XCTAssertNil(view.configureReceivedViewModel?.infoViewModel)
    }

    func testLoadingAccountDetails_WhenViewStarted_ThenHudShowCountIsCorrect() {
        mockAccountDetailsPublisher.send(.loading)
        XCTAssertEqual(view.showHudCallsCount, 0)
        presenter.start(view: view)
        XCTAssertEqual(view.showHudCallsCount, 1)
        mockAccountDetailsPublisher.send(.loading)
        XCTAssertEqual(view.showHudCallsCount, 2)
    }

    func testLoadingAccountDetails_WhenErrorReceived_ThenShowAlertCountIsCorrect() {
        mockAccountDetailsPublisher.send(.recoverableError(MockError.dummy))
        XCTAssertEqual(view.showErrorAlertCallsCount, 0)
        presenter.start(view: view)
        XCTAssertEqual(view.showErrorAlertCallsCount, 1)
        mockAccountDetailsPublisher.send(.recoverableError(MockError.dummy))
        XCTAssertEqual(view.showErrorAlertCallsCount, 2)
    }

    func testLoadingAccountDetails_WhenErrorReceived_ThenHudHidden() {
        mockAccountDetailsPublisher.send(.recoverableError(MockError.dummy))
        XCTAssertFalse(view.hideHudCalled)
        presenter.start(view: view)
        XCTAssertTrue(view.hideHudCalled)
    }

    func testLoadingAccountDetails_WhenAccountDetailsReceived_ThenHudHidden() {
        mockAccountDetailsPublisher.send(.loaded([AccountDetails.canned]))
        XCTAssertFalse(view.hideHudCalled)
        presenter.start(view: view)
        XCTAssertTrue(view.hideHudCalled)
    }
}

// MARK: - Analytics

extension AccountDetailsInfoIntroPresenterTests {
    func testAnalytics_WhenViewStarted_ThenEventNameMatches() {
        presenter.start(view: view)

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Account Details Intro - Started"
        )
    }

    func testAnalytics_GivenAccountDetailsWithDifferentCurrency_ThenErrorEventNameAndPropertiesMatches() {
        presenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded([AccountDetails.active(.build(currency: .EUR))]))

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Account Details Intro - Error Shown"
        )

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked as? [String: String],
            [
                "Type": "No Active Account Details For Currency",
                "Currency": "GBP",
                "Context": "Account Details Intro",
            ]
        )
    }

    func testAnalytics_GivenAccountDetailsRequestFailure_ThenErrorEventNameAndPropertiesMatches() {
        presenter.start(view: view)
        mockAccountDetailsPublisher.send(.recoverableError(MockError.dummy))

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Account Details Intro - Error Shown"
        )

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked as? [String: String],
            [
                "Type": "Fetch Error",
                "Message": "Dummy",
                "Context": "Account Details Intro",
            ]
        )
    }

    func testAnalytics_GivenEligibleAccountDetails_WhenInfoFooterActionTriggered_ThenEventNameMatches() {
        presenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded(Self.makeAccountDetails(repeatingDetailCount: 1)))

        view.configureReceivedViewModel?.infoViewModel?.footer?.action()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Account Details Intro - Account Details Expanded"
        )
    }

    @MainActor
    func testAnalytics_GivenEligibleAccountDetails_WhenReceiveSalaryNavigationActionTriggered_ThenEventNameMatches() {
        presenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded(Self.makeAccountDetails(repeatingDetailCount: 1)))

        view.configureReceivedViewModel?.navigationActions.first?.action()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Account Details Intro - Things You Can Do Option Selected"
        )

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked?["Option"] as? String,
            "Receive Salary"
        )
    }

    @MainActor
    func testAnalytics_GivenEligibleAccountDetails_WhenReceiveMoneyNavigationActionTriggered_ThenEventNameMatches() {
        presenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded(Self.makeAccountDetails(repeatingDetailCount: 1)))

        view.configureReceivedViewModel?.navigationActions[safe: 1]?.action()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked?["Option"] as? String,
            "Receive Money"
        )
    }
}

// MARK: - Helpers

private extension AccountDetailsInfoIntroPresenterTests {
    static func makeAccountDetails(repeatingDetailCount: Int) -> [AccountDetails] {
        let details = [AccountDetailsDetailItem](
            repeating: Constants.accountDetailsDetailItem,
            count: repeatingDetailCount
        )
        return [
            AccountDetails.active(.build(
                currency: .GBP,
                isDeprecated: false,
                receiveOptions: [
                    AccountDetailsReceiveOption.build(
                        details: details
                    ),
                ]
            )),
        ]
    }

    func makePresenter(showSummary: Bool) -> AccountDetailsInfoIntroPresenterImpl {
        AccountDetailsInfoIntroPresenterImpl(
            shouldShowDetailsSummary: showSummary,
            router: router,
            accountDetailsUseCase: accountDetailsUseCase,
            currencyCode: .GBP,
            profile: FakePersonalProfileInfo().asProfile(),
            onDismiss: {},
            analyticsTracker: analyticsTracker,
            scheduler: .immediate
        )
    }
}
