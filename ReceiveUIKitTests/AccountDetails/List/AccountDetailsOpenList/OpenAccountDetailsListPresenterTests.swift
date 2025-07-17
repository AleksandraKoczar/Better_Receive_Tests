import AnalyticsKitTestingSupport
import ApiKit
import BalanceKit
import BalanceKitTestingSupport
import Combine
import DeepLinkKit
import HttpClientKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import UserKit
import UserKitTestingSupport
import WiseCore

final class OpenAccountDetailsListPresenterTests: TWTestCase {
    private var presenter: OpenAccountDetailsListPresenterImpl!
    private var accountDetailsUseCase: AccountDetailsUseCaseMock!
    private var mockPublisher: CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>!
    private var router = AccountDetailsListRouterMock()
    private var view = AccountDetailsListViewMock()
    private var analytics: StubAnalyticsTracker!
    private var receiveQueue: DispatchQueue!
    private var completion: CompletionSpy!

    private let userInfo = StubUserInfo()

    override func setUp() {
        super.setUp()
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.grantedPrivileges = [BalancePrivilege.manage]
        profileInfo.id = ProfileId(1)
        analytics = StubAnalyticsTracker()
        accountDetailsUseCase = AccountDetailsUseCaseMock()
        mockPublisher = CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>(nil)
        accountDetailsUseCase.accountDetails = mockPublisher.eraseToAnyPublisher()
        receiveQueue = DispatchQueue(label: "test queue")
        completion = CompletionSpy()

        let testPresenter = OpenAccountDetailsListPresenterImpl(
            accountDetailsUseCase: accountDetailsUseCase,
            pendingAccountDetailsOrderRoute: nil,
            router: router,
            profile: .personal(profileInfo),
            userInfo: userInfo,
            country: .cannedUK,
            leftNavigationButton: .backButton,
            receiveQueue: receiveQueue,
            analyticsTracker: analytics,
            completion: completion.completion,
            didDismissCompletion: {}
        )
        presenter = testPresenter
    }

    override func tearDown() {
        presenter = nil
        super.tearDown()
    }

    func test_protocolConformance() {
        XCTAssertNotNil(presenter as AccountDetailListPresenter)
    }

    func test_start_whenFetchAllAccountDetailsSuccessfully_shouldShowListOfAccountDetails() {
        // All AccountDetails: AUD, EUR, GBP, PLN, USD, TRY
        setupScreenWithAccountDetailsAndBalancesAccount()

        XCTAssertFalse(view.presentAlertCalled)
        XCTAssertEqual(view.configureHeaderReceivedViewModel?.title, L10n.AccountDetails.List.title)
        XCTAssertEqual(view.configureHeaderReceivedViewModel?.description?.text, L10n.AccountDetails.List.Subtitle.active)
        XCTAssertEqual(view.updateListReceivedSections?.count, 2)
        XCTAssertEqual(view.updateListReceivedSections?.first?.items.count, 3)
        XCTAssertEqual(view.updateListReceivedSections?[safe: 1]?.items.count, 3)
        XCTAssertEqual(analytics.lastMixpanelScreenNameTracked, "Bank details list")
    }

    func test_start_whenFetchOnlyActiveAccountDetailsSuccessfully_shouldShowCorrectNumberOfSections() {
        presenter.start(withView: view)
        mockPublisher.send(
            .loaded([
                MockLegacyAccountDetails.audOpen,
                MockLegacyAccountDetails.eurOpenOne,
            ])
        )
        receiveQueue.sync {}

        XCTAssertEqual(view.updateListReceivedSections?.count, 1)
        XCTAssertEqual(view.updateListReceivedSections?.first?.items.count, 2)
    }

    func test_start_whenFetchOnlyAvailableAccountDetailsSuccessfully_shouldShowCorrectNumberOfSections() {
        presenter.start(withView: view)
        mockPublisher.send(
            .loaded([
                MockLegacyAccountDetails.gbpNotOpened,
                MockLegacyAccountDetails.plnPending,
                MockLegacyAccountDetails.usdNotOpened,
            ])
        )
        receiveQueue.sync {}

        XCTAssertEqual(view.updateListReceivedSections?.count, 1)
        XCTAssertEqual(view.updateListReceivedSections?.first?.items.count, 3)
    }

    func test_whenProfileDoesntHaveBalancePrivileges_onlyActiveBalancesAreAppended() {
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.id = ProfileId(1)

        presenter = OpenAccountDetailsListPresenterImpl(
            accountDetailsUseCase: accountDetailsUseCase,
            pendingAccountDetailsOrderRoute: nil,
            router: router,
            profile: .personal(profileInfo),
            userInfo: userInfo,
            country: .cannedUK,
            leftNavigationButton: .backButton,
            receiveQueue: receiveQueue,
            analyticsTracker: analytics,
            completion: { _ in },
            didDismissCompletion: {}
        )
        setupScreenWithAccountDetailsAndBalancesAccount()

        XCTAssertEqual(view.updateListReceivedSections?.first?.items.count, 3)
    }

    func test_start_whenFetchAllAccountDetailsFail_shouldShowErrorMessageAndEmptyList() {
        presenter.start(withView: view)
        mockPublisher.send(.recoverableError(UseCaseError.noActiveProfile))
        receiveQueue.sync {}

        XCTAssertTrue(view.presentAlertCalled)
        XCTAssertEqual(view.configureHeaderReceivedViewModel?.title, L10n.AccountDetails.List.title)
        XCTAssertEqual(view.configureHeaderReceivedViewModel?.description?.text, L10n.AccountDetails.List.Subtitle.active)
        XCTAssertNil(view.updateListReceivedSections)
    }

    func test_start_filteringIsEmpty_shouldShowFooterAndEmptyList() {
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.id = ProfileId(1)
        profileInfo.address = Address(
            street: "Hello",
            city: "Auckland",
            countryIso2Code: .init("NZ"),
            countryIso3Code: .init("NZL"),
            postCode: nil,
            state: ""
        )
        presenter = OpenAccountDetailsListPresenterImpl(
            accountDetailsUseCase: accountDetailsUseCase,
            pendingAccountDetailsOrderRoute: nil,
            router: router,
            profile: .personal(profileInfo),
            userInfo: userInfo,
            country: .cannedUK,
            leftNavigationButton: .backButton,
            receiveQueue: receiveQueue,
            analyticsTracker: analytics,
            completion: { _ in },
            didDismissCompletion: {}
        )

        setupScreenWithAccountDetailsAndBalancesAccount()

        presenter.updateSearchQuery("kaldmlakdmaldkmaldkmakd")

        XCTAssertFalse(view.presentAlertCalled)
        XCTAssertEqual(view.configureHeaderReceivedViewModel?.title, L10n.AccountDetails.List.title)
        XCTAssertEqual(view.configureHeaderReceivedViewModel?.description?.text, L10n.AccountDetails.List.Subtitle.active)
        XCTAssertEqual(view.updateListReceivedSections?.count, 1)
        XCTAssertNil(view.updateListReceivedSections?.first?.header)
        XCTAssertEqual(view.updateListReceivedSections?.first?.items.isEmpty, true)
        XCTAssertEqual(view.updateListReceivedSections?.first?.footer, "Looking for a different currency?")
    }

    func test_cellTapped_whenAccountDetailsOpenedAndOnlyOneAccountDetails_shouldShowExistingAccountDetails() {
        setupScreenWithAccountDetailsAndBalancesAccount()

        // Row 0 = AUD opened
        presenter.cellTapped(indexPath: IndexPath(row: 0, section: 0))

        XCTAssertEqual(router.showSingleAccountDetailsCallsCount, 1)
        XCTAssertEqual(router.showMultipleAccountDetailsCallsCount, 0)
        XCTAssertFalse(view.presentAlertCalled)
    }

    func test_cellTapped_whenAccountDetailsOpenedAndMoreThanOneAccountDetails_shouldShowMultipleAccountDetails() {
        setupScreenWithAccountDetailsAndBalancesAccount()

        // Row 1 = EUR 2 account details opened
        presenter.cellTapped(indexPath: IndexPath(row: 1, section: 0))

        XCTAssertEqual(router.showSingleAccountDetailsCallsCount, 0)
        XCTAssertEqual(router.showMultipleAccountDetailsCallsCount, 1)
        XCTAssertEqual(router.showMultipleAccountDetailsReceivedInvocations.first?.0.count, 2)
        XCTAssertFalse(view.presentAlertCalled)
    }

    func test_cellTapped_whenAccountDetailsNotOpenedWithBalance_shouldShowExistingAccountDetails() {
        setupScreenWithAccountDetailsAndBalancesAccount()
        presenter.start(withView: view)

        // Row 2 = GBP notOpened -> GBP open
        presenter.cellTapped(indexPath: IndexPath(row: 0, section: 1))

        XCTAssertEqual(router.showMultipleAccountDetailsCallsCount, 0)
        XCTAssertEqual(completion.currencyCode, .GBP)
        XCTAssertFalse(view.presentAlertCalled)
    }

    func test_cellTapped_whenAccountDetailsNotOpenedWithBalance_shouldStartAccountDetailsRequirementsFlow() {
        setupScreenWithAccountDetailsAndBalancesAccount()

        // Row 2 = GBP notOpened -> GBP pending
        presenter.cellTapped(indexPath: IndexPath(row: 0, section: 1))

        XCTAssertEqual(router.showSingleAccountDetailsCallsCount, 0)
        XCTAssertEqual(router.showMultipleAccountDetailsCallsCount, 0)
        XCTAssertEqual(completion.currencyCode, .GBP)
        XCTAssertFalse(view.presentAlertCalled)
    }

    func test_cellTapped_whenAccountDetailsPendingWithBalance_shouldStartAccountDetailsRequirementsFlow() {
        setupScreenWithAccountDetailsAndBalancesAccount()

        // Row 2 = PLN pending -> PLN pending
        presenter.cellTapped(indexPath: IndexPath(row: 1, section: 1))

        XCTAssertEqual(router.showSingleAccountDetailsCallsCount, 0)
        XCTAssertEqual(router.showMultipleAccountDetailsCallsCount, 0)
        XCTAssertEqual(completion.currencyCode, .PLN)
        XCTAssertFalse(view.presentAlertCalled)
    }

    func test_setupNavigationLeftButton_whenBackButton_shouldShowArrowBack() {
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.grantedPrivileges = [BalancePrivilege.manage]
        profileInfo.id = ProfileId(1)
        presenter = OpenAccountDetailsListPresenterImpl(
            accountDetailsUseCase: accountDetailsUseCase,
            pendingAccountDetailsOrderRoute: nil,
            router: router,
            profile: .personal(profileInfo),
            userInfo: userInfo,
            country: .cannedUK,
            leftNavigationButton: .backButton,
            analyticsTracker: analytics,
            completion: { _ in },
            didDismissCompletion: {}
        )

        setupScreenWithAccountDetailsAndBalancesAccount()

        XCTAssertEqual(view.setupNavigationLeftButtonReceivedArguments?.buttonStyle, .arrow)
    }

    func test_whenLeftNavigationButtonIsBackAndTapped_shouldDismiss() {
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.grantedPrivileges = [BalancePrivilege.manage]
        profileInfo.id = ProfileId(1)
        presenter = OpenAccountDetailsListPresenterImpl(
            accountDetailsUseCase: accountDetailsUseCase,
            pendingAccountDetailsOrderRoute: nil,
            router: router,
            profile: .personal(profileInfo),
            userInfo: userInfo,
            country: .cannedUK,
            leftNavigationButton: .backButton,
            analyticsTracker: analytics,
            completion: { _ in },
            didDismissCompletion: {}
        )

        setupScreenWithAccountDetailsAndBalancesAccount()
        view.setupNavigationLeftButtonReceivedArguments?.buttonAction()

        XCTAssertEqual(router.dismissCallsCount, 1)
    }

    func test_setupNavigationLeftButton_whenDismissButton_shouldShowX() {
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.grantedPrivileges = [BalancePrivilege.manage]
        profileInfo.id = ProfileId(1)
        presenter = OpenAccountDetailsListPresenterImpl(
            accountDetailsUseCase: accountDetailsUseCase,
            pendingAccountDetailsOrderRoute: nil,
            router: router,
            profile: .personal(profileInfo),
            userInfo: userInfo,
            country: .cannedUK,
            leftNavigationButton: .dismissButton,
            analyticsTracker: analytics,
            completion: { _ in },
            didDismissCompletion: {}
        )

        setupScreenWithAccountDetailsAndBalancesAccount()

        XCTAssertEqual(view.setupNavigationLeftButtonReceivedArguments?.buttonStyle, .cross)
    }

    func test_whenLeftNavigationButtonIsDismissAndTapped_shouldDismiss() {
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.grantedPrivileges = [BalancePrivilege.manage]
        profileInfo.id = ProfileId(1)
        presenter = OpenAccountDetailsListPresenterImpl(
            accountDetailsUseCase: accountDetailsUseCase,
            pendingAccountDetailsOrderRoute: nil,
            router: router,
            profile: .personal(profileInfo),
            userInfo: userInfo,
            country: .cannedUK,
            leftNavigationButton: .dismissButton,
            analyticsTracker: analytics,
            completion: { _ in },
            didDismissCompletion: {}
        )

        setupScreenWithAccountDetailsAndBalancesAccount()
        view.setupNavigationLeftButtonReceivedArguments?.buttonAction()

        XCTAssertEqual(router.dismissCallsCount, 1)
    }

    func test_pendingDeepLink() throws {
        // TODO: Christie Fix Test
        try XCTSkipAlways("Flakey Test")
        let components = DeepLinkURLComponents(
            path: ["account-details"],
            queryItems: [.init(name: "currency", value: "GBP")]
        )
        let deeplink = DeepLinkAccountDetailsRouteImpl(components: .url(components))
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.grantedPrivileges = [BalancePrivilege.manage]
        profileInfo.id = ProfileId(1)

        presenter = OpenAccountDetailsListPresenterImpl(
            accountDetailsUseCase: accountDetailsUseCase,
            pendingAccountDetailsOrderRoute: deeplink,
            router: router,
            profile: .personal(profileInfo),
            userInfo: userInfo,
            country: .cannedUK,
            leftNavigationButton: .dismissButton,
            receiveQueue: receiveQueue,
            analyticsTracker: analytics,
            completion: { _ in },
            didDismissCompletion: {}
        )

        setupScreenWithAccountDetailsAndBalancesAccount()

        XCTAssertEqual(completion.currencyCode, .GBP)
    }

    func testSnackBarPresentation_WhenFooterTapped_ThenSnackBarDisplayedWithDelay() {
        presenter.start(withView: view)
        mockPublisher.send(
            .loaded([
                MockLegacyAccountDetails.gbpNotOpened,
                MockLegacyAccountDetails.plnPending,
                MockLegacyAccountDetails.usdNotOpened,
            ])
        )
        presenter.footerTapped()
        receiveQueue.sync {}
        router.requestAccountDetailsReceivedArguments?.completion()
        let exp = expectation(description: #function)
        receiveQueue.asyncAfter(deadline: .now() + 0.5) {
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertTrue(view.presentSnackBarCalled)
    }

    private func setupScreenWithAccountDetailsAndBalancesAccount() {
        presenter.start(withView: view)
        mockPublisher.send(.loaded(MockLegacyAccountDetails.listOfAllAccountDetailsWithInitialValue))
        receiveQueue.sync {}
    }
}

/* Initial status:
 All AccountDetails: AUD, EUR, GBP, PLN, USD, TRY
 Account has the following AccountDetails: AUD (open), EUR (2 open), PLN (pending), TRY (deprecated)
 Account has balances for: AUD, EUR, GBP, PLN
 Account doesnt have balances for: USD
 */
extension OpenAccountDetailsListPresenterTests {
    enum MockLegacyAccountDetails {
        static let audOpen = createActiveAccountDetails(currency: .AUD)
        static let eurOpenOne = createActiveAccountDetails(currency: .EUR)
        static let eurOpenTwo = createActiveAccountDetails(currency: .EUR)
        static let gbpNotOpened = createAvailableAccountDetails(currency: .GBP)
        static let plnPending = createAvailableAccountDetails(currency: .PLN)
        static let usdNotOpened = createAvailableAccountDetails(currency: .USD)
        static let tryDeprecated = createActiveAccountDetails(currency: .TRY, isDeprecated: true)

        // All AccountDetails: AUD, EUR, GBP, PLN, USD
        static let listOfAllAccountDetailsWithInitialValue = [
            audOpen,
            eurOpenOne,
            eurOpenTwo,
            gbpNotOpened,
            plnPending,
            usdNotOpened,
            tryDeprecated,
        ]

        static let gbpOpen = createActiveAccountDetails(currency: .GBP)
        static let listOfAllAccountDetailsWithGBPOpened = [audOpen, eurOpenOne, eurOpenTwo, gbpOpen, plnPending, usdNotOpened]

        static let plnOpen = createActiveAccountDetails(currency: .PLN)
        static let listOfAllAccountDetailsWithPLNOpened = [audOpen, eurOpenOne, eurOpenTwo, gbpNotOpened, plnOpen, usdNotOpened]

        static let usdOpen = createActiveAccountDetails(currency: .USD)
        static let listOfAllAccountDetailsWithUSDOpened = [audOpen, eurOpenOne, eurOpenTwo, gbpNotOpened, plnOpen, usdOpen]
    }

    enum MockBalances {
        static let audOpen = createBalance(id: 10, currency: .AUD)
        static let eurOpen = createBalance(id: 30, currency: .EUR)
        static let gbpNotOpened = createBalance(id: 1, currency: .GBP)
        static let gbpOpen = createBalance(id: 1, currency: .GBP)
        static let plnPending = createBalance(id: 2, currency: .PLN)

        // Account has balances for: AUD, EUR, GBP, PLN
        static var account = Account.build(
            id: AccountId(11),
            profileId: ProfileId(12),
            recipientId: .build(value: 13),
            created: Date(),
            isActive: true
        )
        static var accountWithGBPOpen = Account.build(
            id: AccountId(11),
            profileId: ProfileId(12),
            recipientId: .build(value: 13),
            created: Date(),
            isActive: true
        )
    }

    private static func createBalance(id: Int64, currency: CurrencyCode) -> Balance {
        Balance.build(
            id: BalanceId(id),
            balanceType: .standard,
            totalWorth: 950.22,
            availableAmount: 950.22,
            currency: currency,
            created: Date(),
            updated: Date(),
            isVisible: true,
            investmentState: .notInvested
        )
    }

    private static func createActiveAccountDetails(
        currency: CurrencyCode = .GBP,
        isDeprecated: Bool = false
    ) -> AccountDetails {
        AccountDetails.active(.build(
            currency: currency,
            isDeprecated: isDeprecated,
            title: "New details"
        ))
    }

    private static func createAvailableAccountDetails(
        currency: CurrencyCode = .GBP,
        isDeprecated: Bool = false
    ) -> AccountDetails {
        AccountDetails.available(.build(
            currency: currency,
            isDeprecated: isDeprecated,
            title: "New details"
        ))
    }
}

private final class CompletionSpy {
    var currencyCode: CurrencyCode?

    lazy var completion: (CurrencyCode) -> Void = { currencyCode in
        self.currencyCode = currencyCode
    }
}
