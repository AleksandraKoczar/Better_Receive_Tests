import AnalyticsKitTestingSupport
import ApiKit
import BalanceKit
import BalanceKitTestingSupport
import HttpClientKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport
import WiseCore

final class AccountDetailSingleCurrencyPresenterTests: TWTestCase {
    private var presenter: AccountDetailListPresenter!
    private var router = AccountDetailsListRouterMock()
    private var view = AccountDetailsListViewMock()
    private var analytics: StubAnalyticsTracker!
    private var accountDetailsUseCase: AccountDetailsUseCaseMock!
    var profile: Profile {
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.id = ProfileId(0)
        return .personal(profileInfo)
    }

    override func setUp() {
        super.setUp()
        analytics = StubAnalyticsTracker()
        accountDetailsUseCase = AccountDetailsUseCaseMock()
        let testPresenter = SingleCurrencyMultiAccountDetailsPresenterImpl(
            router: router,
            profile: profile,
            source: .accountDetailsList([]),
            useCase: accountDetailsUseCase,
            analyticsTracker: analytics,
            didDismissCompletion: {}
        )
        presenter = testPresenter
    }

    override func tearDown() {
        presenter = nil
        analytics = nil
        accountDetailsUseCase = nil

        super.tearDown()
    }

    func test_protocolConformance() {
        XCTAssertNotNil(presenter as AccountDetailListPresenter)
    }

    func test_setUpNoDetails() {
        presenter = SingleCurrencyMultiAccountDetailsPresenterImpl(
            router: router,
            profile: profile,
            source: .accountDetailsList([]),
            useCase: accountDetailsUseCase,
            analyticsTracker: analytics,
            didDismissCompletion: nil
        )
        presenter.start(withView: view)

        XCTAssertEqual(analytics.lastMixpanelScreenNameTracked, "Bank details multiple currency list")
        XCTAssertNil(view.updateListReceivedSections)
    }

    func test_setUpNoDeprecated() {
        presenter = SingleCurrencyMultiAccountDetailsPresenterImpl(
            router: router,
            profile: profile,
            source: .accountDetailsList([
                ActiveAccountDetails.build(),
                ActiveAccountDetails.build(),
            ]),
            useCase: accountDetailsUseCase,
            analyticsTracker: analytics,
            didDismissCompletion: nil
        )
        presenter.start(withView: view)

        XCTAssertEqual(view.updateListReceivedSections?.count, 1)
    }

    func test_setUpOnlyDeprecated() {
        presenter = SingleCurrencyMultiAccountDetailsPresenterImpl(
            router: router,
            profile: profile,
            source: .accountDetailsList([
                ActiveAccountDetails.build(),
                ActiveAccountDetails.build(),
            ]),
            useCase: accountDetailsUseCase,
            analyticsTracker: analytics,
            didDismissCompletion: nil
        )
        presenter.start(withView: view)
        XCTAssertEqual(view.updateListReceivedSections?.count, 1)
    }

    func test_setUpBothDetailTypes() {
        presenter = SingleCurrencyMultiAccountDetailsPresenterImpl(
            router: router,
            profile: profile,
            source: .accountDetailsList([
                ActiveAccountDetails.build(),
                ActiveAccountDetails.build(),
            ]),
            useCase: accountDetailsUseCase,
            analyticsTracker: analytics,
            didDismissCompletion: nil
        )
        presenter.start(withView: view)

        XCTAssertEqual(view.updateListReceivedSections?.count, 1)

        XCTAssertNotNil(view.updateListReceivedSections?[0])
        XCTAssertEqual(view.updateListReceivedSections?[0].items.count, 2)
    }

    func test_tapThrough() {
        presenter = SingleCurrencyMultiAccountDetailsPresenterImpl(
            router: router,
            profile: profile,
            source: .accountDetailsList([
                ActiveAccountDetails.build(currency: .AUD, title: "Test name"),
                ActiveAccountDetails.build(currency: .AUD, title: "Test name 1"),
                ActiveAccountDetails.build(currency: .AUD, title: "Test name 2"),
                ActiveAccountDetails.build(currency: .AUD, title: "Test name 3"),
            ]),
            useCase: accountDetailsUseCase,
            analyticsTracker: analytics,
            didDismissCompletion: nil
        )

        presenter.start(withView: view)

        presenter.cellTapped(indexPath: IndexPath(row: 0, section: 0))
        XCTAssertEqual(router.showSingleAccountDetailsCallsCount, 1)

        presenter.cellTapped(indexPath: IndexPath(row: 1, section: 0))
        XCTAssertEqual(router.showSingleAccountDetailsCallsCount, 2)

        presenter.cellTapped(indexPath: IndexPath(row: 50, section: 0))
        XCTAssertEqual(router.showSingleAccountDetailsCallsCount, 2)
    }

    func testDepracatedOrder() {
        presenter = SingleCurrencyMultiAccountDetailsPresenterImpl(
            router: router,
            profile: profile,
            source: .accountDetailsList([
                ActiveAccountDetails.build(
                    currency: .AUD,
                    isDeprecated: true,
                    title: "1"
                ),
                ActiveAccountDetails.build(currency: .AUD, title: "2"),
                ActiveAccountDetails.build(
                    currency: .AUD,
                    title: "3",
                    receiveOptions: [
                        AccountDetailsReceiveOption.build(
                            alert: AccountDetailsAlert.build(
                                type: .warning
                            )
                        ),
                    ]
                ),
                ActiveAccountDetails.build(
                    currency: .AUD,
                    title: "4",
                    receiveOptions: [
                        AccountDetailsReceiveOption.build(
                            alert: AccountDetailsAlert.build(
                                type: .info
                            )
                        ),
                    ]
                ),
            ]),
            useCase: accountDetailsUseCase,
            analyticsTracker: analytics,
            didDismissCompletion: nil
        )
        presenter.start(withView: view)

        XCTAssertEqual(
            view.updateListReceivedSections?.first?.items[safe: 0]?.title, "4"
        )
        XCTAssertEqual(
            view.updateListReceivedSections?.first?.items[safe: 1]?.title, "2"
        )
        XCTAssertEqual(
            view.updateListReceivedSections?.first?.items[safe: 2]?.title, "1"
        )
        XCTAssertEqual(
            view.updateListReceivedSections?.first?.items[safe: 3]?.title, "3"
        )
    }
}
