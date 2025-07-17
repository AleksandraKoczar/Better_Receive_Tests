import BalanceKit
import Combine
import Foundation
@testable import Neptune
import Prism
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import UserKit
import UserKitTestingSupport
import WiseCore

@MainActor
final class AccountDetailsV3PresenterTests: TWTestCase {
    private var view: AccountDetailsV3ViewMock!
    private var presenter: AccountDetailsV3PresenterImpl!
    private var router: AccountDetailsInfoRouterMock!
    private var useCase: AccountDetailsV3UseCaseMock!
    private var payerPDFUseCase: AccountDetailsPayerPDFUseCaseMock!
    private var accountOwnershipProofUseCase: AccountOwnershipProofUseCaseMock!
    private var receiveMethodsAliasUseCase: ReceiveMethodsAliasUseCaseMock!
    private var analyticsTracker: ReceiveMethodsTrackingMock!
    private var accountDetailsSwitcherFactory: AccountDetailsV3SwitcherViewControllerFactoryMock!
    private var pasteboard: MockPasteboard!

    private lazy var accountDetails = AccountDetailsV3.build(
        id: .init(1),
        type: .accountDetails,
        currency: .PLN
    )

    private lazy var accountDetails2 = AccountDetailsV3.build(
        id: .init(10),
        type: .accountDetails,
        currency: .GBP
    )

    override func setUp() {
        super.setUp()

        router = AccountDetailsInfoRouterMock()
        useCase = AccountDetailsV3UseCaseMock()
        payerPDFUseCase = AccountDetailsPayerPDFUseCaseMock()
        accountOwnershipProofUseCase = AccountOwnershipProofUseCaseMock()
        receiveMethodsAliasUseCase = ReceiveMethodsAliasUseCaseMock()
        accountDetailsSwitcherFactory = AccountDetailsV3SwitcherViewControllerFactoryMock()
        analyticsTracker = ReceiveMethodsTrackingMock()
        view = AccountDetailsV3ViewMock()
        pasteboard = MockPasteboard()

        presenter = makePresenter()

        trackForMemoryLeak(instance: presenter) { [weak self] in
            self?.presenter = nil
            self?.accountDetailsSwitcherFactory.makeReceivedArguments = nil
            self?.accountDetailsSwitcherFactory.makeReceivedInvocations = []
            self?.accountDetailsSwitcherFactory = nil
        }
    }

    override func tearDown() {
        router = nil
        useCase = nil
        view = nil
        pasteboard = nil
        presenter = nil
        payerPDFUseCase = nil
        analyticsTracker = nil
        accountOwnershipProofUseCase = nil
        accountDetailsSwitcherFactory = nil

        super.tearDown()
    }

    func test_fetchAccountDetails_givenContentIsReady() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)

        presenter.start(with: view)

        XCTAssertEqual(view.loadingStateChangedReceivedInvocations.map { $0.isLoading }, [false])

        let configuredViewModel = view.configureReceivedInvocations.first

        XCTAssertEqual(configuredViewModel?.currency, CurrencyCode("PLN"))
        XCTAssertEqual(analyticsTracker.onLoadedCallsCount, 1)
    }

    func test_fetchAccountDetailsFails_thenShowError() {
        useCase.getAccountDetailsV3ReturnValue = .just(.error(MockError.dummy))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)

        presenter.start(with: view)

        XCTAssertEqual(view.loadingStateChangedReceivedInvocations.map { $0.failed }, [true])
    }

    func test_handleMarkupGivenModal_thenShowBottomsheet() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)

        presenter.start(with: view)
        let markup = AccountDetailsV3Markup.build(value: "test", action: .modal(.canned))
        presenter.handleExternalAction(action: markup.action)

        XCTAssertTrue(router.showBottomsheetAccountDetailsV3Called)
    }

    func test_handleMarkupGivenUrl_thenShowHelpArticle() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)

        presenter.start(with: view)
        let markup = AccountDetailsV3Markup.build(value: "test", action: .url(.canned))
        presenter.handleExternalAction(action: markup.action)

        XCTAssertTrue(router.showArticleCalled)
    }

    func test_handleMarkupGivenUrn_thenHandleGenericURN() throws {
        let expectedURN = try URN("urn:wise:com:bla:bla")
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)

        presenter.start(with: view)

        presenter.handleExternalAction(action: .urn(expectedURN))
        XCTAssertEqual(
            router.handleURIReceivedUri?.description,
            URI.urn(expectedURN).description
        )
    }

    func test_handleMarkupGivenUrnOnFooter_thenHandleGenericURN() throws {
        let expectedURN = try URN("urn:wise:com:bla:bla")
        let accountDetails = AccountDetailsV3.build(
            method: AccountDetailsV3Method.build(
                detailsFooter: AccountDetailsV3Method.AccountDetailsFooter.button(
                    AccountDetailsV3Method.AccountDetailsFooter.FooterButton.build(
                        action: AccountDetailsExternalAction.urn(expectedURN)
                    )
                )
            )
        )
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(false))
        presenter.start(with: view)

        guard case let .button(button) = view.configureReceivedModel?.method.detailsFooter else {
            XCTFail("Button does not exist")
            return
        }

        presenter.handleExternalAction(action: button.action)
        XCTAssertEqual(
            router.handleURIReceivedUri?.description,
            URI.urn(expectedURN).description
        )
    }

    func test_containerTapped() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)

        presenter.start(with: view)
        presenter.containerTapped(content: .canned)

        XCTAssertTrue(router.showDetailsCalled)
    }

    func test_copyAllDetails() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)
        view.activeView = UIView()

        presenter.start(with: view)

        presenter.handleHeaderAction(.share(.canned))

        router.showShareActionsAccountDetailsV3ReceivedArguments?.actions[1].handler()

        XCTAssertTrue(view.showConfirmationCalled)
        XCTAssertTrue(router.showShareActionsAccountDetailsV3Called)
        XCTAssertEqual(analyticsTracker.onCopyDetailsSelectedCallsCount, 1)
    }

    func test_handleCopy() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        view.activeView = UIView()
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)

        presenter.start(with: view)
        presenter.handleCopyAction(copyText: "Account number copied", feedbackText: "hello")

        XCTAssertTrue(view.showConfirmationCalled)
        XCTAssertEqual(pasteboard.clipboard.last, "Account number copied")
    }

    func test_showDownloadPDFSheet() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)
        view.activeView = UIView()

        presenter.start(with: view)
        presenter.handleHeaderAction(.share(.canned))
        router.showShareActionsAccountDetailsV3ReceivedArguments?.actions[2].handler()

        XCTAssertTrue(router.showDownloadPDFSheetCalled)
        XCTAssertEqual(analyticsTracker.onDownloadDetailsSelectedCallsCount, 1)
    }

    func test_shouldShowModal() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)
        view.activeView = UIView()

        presenter.start(with: view)
        presenter.handleHeaderAction(.share(.canned))
        router.showShareActionsAccountDetailsV3ReceivedArguments?.actions[2].handler()

        XCTAssertTrue(router.showDownloadPDFSheetCalled)
    }

    func testURNShareAction_GivenURNAction_ThenRouterReceivedTheURN() throws {
        let expectedUrnString = "urn:wise:bla:bla"
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        view.activeView = UIView()

        presenter.handleHeaderAction(.urn(.build(value: expectedUrnString)))

        XCTAssertEqual(router.handleURIReceivedUri, .urn(try URN(expectedUrnString)))
    }

    func test_currencySelectorTapped() throws {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)
        accountDetailsSwitcherFactory.makeReturnValue = UIViewControllerMock()
        view.activeView = UIView()

        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureNavigationBarReceivedModel)
        viewModel.onTap!()

        XCTAssertTrue(router.showSwitcherCalled)
    }

    func test_currencySelectorTapped_givenAccountDetailsSourceIsBalance_thenSwitcherNotCalled() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)
        view.activeView = UIView()

        presenter = makePresenter(invocationSource: .balanceHeaderAction)

        presenter.start(with: view)

        XCTAssertEqual(view.configureNavigationBarReceivedModel?.isOnTapEnabled, false)
        XCTAssertFalse(router.showSwitcherCalled)
    }

    func test_viewAction_thenViewConfiguredAgain() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)
        view.activeView = UIView()

        presenter.start(with: view)

        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails2))
        presenter.handleReceiveMethodAction(action: .view(id: .build(value: 10), methodType: .accountDetails))

        let configuredViewModel = view.configureReceivedInvocations[1]

        XCTAssertEqual(configuredViewModel.id, .build(value: 10))
        XCTAssertEqual(view.configureReceivedInvocations.count, 2)
        XCTAssertEqual(view.configureNavigationBarReceivedModel?.isOnTapEnabled, true)
        XCTAssertEqual(view.configureNavigationBarReceivedModel?.currency, .GBP)
        XCTAssertEqual(analyticsTracker.onLoadedCallsCount, 2)
    }

    func test_queryAction_thenRouterCalledWithQueryAction() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(.canned)
        view.activeView = UIView()

        presenter.start(with: view)
        presenter.handleReceiveMethodAction(action: .query(
            context: .list,
            currency: .SGD,
            groupId: nil,
            balanceId: nil,
            methodTypes: nil
        ))

        XCTAssertTrue(router.queryReceiveMethodCalled)
    }

    func test_orderAction_thenRouterCalledWithOrderAction() {
        useCase.getAccountDetailsV3ReturnValue = .just(.content(accountDetails))
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        view.activeView = UIView()

        presenter.start(with: view)
        presenter.handleReceiveMethodAction(action: .order(currency: .AUD, balanceId: nil, methodType: .accountDetails))
        XCTAssertTrue(router.orderReceiveMethodCalled)
    }
}

// MARK: - Pix Alias Registration Navigation Tests

extension AccountDetailsV3PresenterTests {
    func test_PixAliasRegistrationNavigation_GivenNoAliasRegistered_ThenNavigatedCorrectlyJustOnce() {
        let profile = Profile.personal(
            FakePersonalProfileInfo()
                .with(privilege: BalancePrivilege.manage)
        )

        presenter = makePresenter(profile: profile)
        useCase.getAccountDetailsV3ReturnValue = .just(
            .content(AccountDetailsV3.build(
                id: .build(value: 64),
                currency: .BRL
            )
            )
        )
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        receiveMethodsAliasUseCase.aliasesReturnValue = .just([
            ReceiveMethodAlias.build(state: .unregistered, aliasScheme: "PIX"),
        ])

        presenter.start(with: view)
        XCTAssertEqual(router.showReceiveMethodAliasRegistrationReceivedArguments?.accountDetailsId.value, 64)

        XCTAssertEqual(router.showReceiveMethodAliasRegistrationCallsCount, 1)
        presenter.refresh()
        XCTAssertEqual(router.showReceiveMethodAliasRegistrationCallsCount, 1)
    }

    func test_PixAliasRegistrationNavigation_GivenProfileWithoutPriviledge_ThenNoNavigationHappened() {
        let profile = Profile.personal(
            FakePersonalProfileInfo()
        )

        presenter = makePresenter(profile: profile)
        useCase.getAccountDetailsV3ReturnValue = .just(
            .content(AccountDetailsV3.build(
                id: .build(value: 64),
                currency: .BRL
            )
            )
        )
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        receiveMethodsAliasUseCase.aliasesReturnValue = .just([
            ReceiveMethodAlias.build(state: .unregistered, aliasScheme: "PIX"),
        ])

        presenter.start(with: view)
        XCTAssertFalse(router.showReceiveMethodAliasRegistrationCalled)
    }

    func test_PixAliasRegistrationNavigation_GivenAliasPendingRegistration_ThenNoNavigationHappened() {
        useCase.getAccountDetailsV3ReturnValue = .just(
            .content(AccountDetailsV3.build(
                id: .build(value: 64),
                currency: .BRL
            )
            )
        )
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        receiveMethodsAliasUseCase.aliasesReturnValue = .just([
            ReceiveMethodAlias.build(state: .pendingRegistration, aliasScheme: "PIX"),
        ])

        presenter.start(with: view)
        XCTAssertFalse(router.showReceiveMethodAliasRegistrationCalled)
    }

    func test_PixAliasRegistrationNavigation_GivenDifferentCurrency_ThenNoNavigationHappened() {
        useCase.getAccountDetailsV3ReturnValue = .just(
            .content(AccountDetailsV3.build(
                id: .build(value: 64),
                currency: .THB
            )
            )
        )
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        receiveMethodsAliasUseCase.aliasesReturnValue = .just([
            ReceiveMethodAlias.build(state: .inactive, aliasScheme: "PIX"),
        ])

        presenter.start(with: view)
        XCTAssertFalse(router.showReceiveMethodAliasRegistrationCalled)
    }
}

// MARK: - Helpers

private extension AccountDetailsV3PresenterTests {
    func makePresenter(
        profile: Profile = .personal(FakePersonalProfileInfo()),
        invocationSource: AccountDetailsInfoInvocationSource = .accountDetailsList,
    ) -> AccountDetailsV3PresenterImpl {
        AccountDetailsV3PresenterImpl(
            invocationSource: invocationSource,
            accountDetailsId: .build(value: 5),
            profile: profile,
            accountDetailsUseCase: useCase,
            accountOwnershipProofUseCase: accountOwnershipProofUseCase,
            payerPDFUseCase: payerPDFUseCase,
            receiveMethodsAliasUseCase: receiveMethodsAliasUseCase,
            accountDetailsSwitcherFactory: accountDetailsSwitcherFactory,
            router: router,
            analyticsTracker: analyticsTracker,
            pasteboard: pasteboard,
            scheduler: .immediate
        )
    }
}
