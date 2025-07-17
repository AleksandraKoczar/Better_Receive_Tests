import AnalyticsKit
import AnalyticsKitTestingSupport
import BalanceKit
import BalanceKitTestingSupport
import Combine
import HttpClientKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWFoundation
import TWTestingSupportKit
import TWUITestingSupport
import UserKit
import WiseCore

final class SalarySwitchOptionSelectionPresenterTests: TWTestCase {
    private enum MockError: Error {
        case dummy
    }

    private enum Constants {
        static let eurAccountDetails = AccountDetails.active(.build(
            id: AccountDetailsId(1221),
            balanceId: BalanceId(64),
            currency: .EUR,
            title: "account details",
            receiveOptions: [AccountDetailsReceiveOption.build(shareText: "Sharing")]
        ))
        static let profileId = ProfileId(128)
    }

    private var presenter: SalarySwitchOptionSelectionPresenter!
    private var accountDetailsUseCase: AccountDetailsUseCaseMock!
    private var accountOwnershipProofUseCase: AccountOwnershipProofUseCaseMock!
    private var mockAccountDetailsPublisher: CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>!
    private var mockAccountOwnershipProofPublisher: CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>!

    private var router: SalarySwitchOptionSelectionRouterMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var view: SalarySwitchOptionSelectionViewMock!

    override func setUp() {
        super.setUp()

        view = SalarySwitchOptionSelectionViewMock()
        mockAccountDetailsPublisher = CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>(nil)
        accountDetailsUseCase = AccountDetailsUseCaseMock()
        accountDetailsUseCase.accountDetails = mockAccountDetailsPublisher.eraseToAnyPublisher()
        accountOwnershipProofUseCase = AccountOwnershipProofUseCaseMock()
        router = SalarySwitchOptionSelectionRouterMock()
        analyticsTracker = StubAnalyticsTracker()
        presenter = SalarySwitchOptionSelectionPresenterImpl(
            balanceId: BalanceId(64),
            currencyCode: .EUR,
            profileId: Constants.profileId,
            router: router,
            accountDetailsUseCase: accountDetailsUseCase,
            accountOwnershipProofUseCase: accountOwnershipProofUseCase,
            analyticsTracker: analyticsTracker,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        presenter = nil
        mockAccountDetailsPublisher = nil
        accountDetailsUseCase = nil
        accountOwnershipProofUseCase = nil
        router = nil
        view = nil

        super.tearDown()
    }
}

// MARK: - Start & load

extension SalarySwitchOptionSelectionPresenterTests {
    func testOptionsCount_WhenViewStarted_ThenOptionsCountIsCorrect() {
        presenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded([
            AccountDetails.active(ActiveAccountDetails.build(balanceId: BalanceId(64))),
        ]))
        XCTAssertEqual(
            view.configureReceivedViewModel?.sections.first?.options.count,
            2
        )
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

    func testLoadingAccountDetails_GivenDeprecatedAccountDetails_ThenActionsDontWork() {
        mockAccountDetailsPublisher.send(.loaded([
            AccountDetails.active(
                ActiveAccountDetails.build(
                    balanceId: BalanceId(64),
                    isDeprecated: true
                )
            ),
        ]))
        presenter.start(view: view)
        presenter.selectedOption(at: 0, sender: view)
        XCTAssertFalse(router.displayShareSheetCalled)
        presenter.selectedOption(at: 1, sender: view)
        XCTAssertFalse(router.displayOwnershipProofDocumentCalled)
    }

    func testLoadingAccountDetails_GivenAvailableAccountDetails_ThenActionsDontWork() {
        mockAccountDetailsPublisher.send(.loaded([AccountDetails.available(.canned)]))
        presenter.start(view: view)
        presenter.selectedOption(at: 0, sender: view)
        XCTAssertFalse(router.displayShareSheetCalled)
        presenter.selectedOption(at: 1, sender: view)
        XCTAssertFalse(router.displayOwnershipProofDocumentCalled)
    }
}

// MARK: - Display share sheet

extension SalarySwitchOptionSelectionPresenterTests {
    func testOptionSelection_WhenOptionSelected_ThenShareSheetDisplayed() {
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))
        presenter.start(view: view)
        XCTAssertEqual(router.displayShareSheetCallsCount, 0)
        presenter.selectedOption(at: 0, sender: view)
        XCTAssertEqual(router.displayShareSheetCallsCount, 1)
    }

    func testShareSheetContent_WhenOptionSelected_ThenShareTextsShouldMatch() {
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))
        presenter.start(view: view)

        presenter.selectedOption(at: 0, sender: view)
        XCTAssertEqual(
            router.displayShareSheetReceivedArguments?.content,
            Constants.eurAccountDetails.receiveOptions.first?.shareText ?? ""
        )
    }

    func testShareSheetContent_GivenDifferentCurrency_WhenOptionSelected_ThenShareTextsShouldBeNil() {
        presenter = SalarySwitchOptionSelectionPresenterImpl(
            balanceId: BalanceId(64),
            currencyCode: .GBP,
            profileId: Constants.profileId,
            router: router,
            accountDetailsUseCase: accountDetailsUseCase,
            accountOwnershipProofUseCase: accountOwnershipProofUseCase,
            analyticsTracker: analyticsTracker,
            scheduler: .immediate
        )
        mockAccountDetailsPublisher.send(.loaded([AccountDetails.canned]))
        presenter.start(view: view)
        presenter.selectedOption(at: 0, sender: view)
        XCTAssertEqual(
            router.displayShareSheetReceivedArguments?.content,
            nil
        )
    }
}

// MARK: - Account ownership proof

extension SalarySwitchOptionSelectionPresenterTests {
    func testDisplayingProofDocument_GivenSucces_WhenOptionSelected_ThenDisplayDocumentCalled() throws {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(#function + ".pdf")

        try "Jane Doe"
            .data(using: .utf8)?
            .write(to: path)
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))
        let viewController = StubDocumentInteractionViewController()
        view.documentInteractionControllerDelegate = viewController
        presenter.start(view: view)
        accountOwnershipProofUseCase.accountOwnershipProofReturnValue = .just(path)

        XCTAssertFalse(router.displayOwnershipProofDocumentCalled)
        presenter.selectedOption(at: 1, sender: view)
        XCTAssertTrue(router.displayOwnershipProofDocumentCalled)
    }

    func testDisplayingProofDocument_GivenFailure_WhenOptionSelected_ThenShowErrorCalled() {
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))
        let viewController = StubDocumentInteractionViewController()
        view.documentInteractionControllerDelegate = viewController
        presenter.start(view: view)
        accountOwnershipProofUseCase.accountOwnershipProofReturnValue = .fail(
            with: .saveFailed(
                error: MockError.dummy
            )
        )

        XCTAssertFalse(view.showErrorAlertCalled)
        presenter.selectedOption(at: 1, sender: view)
        XCTAssertTrue(view.showErrorAlertCalled)
    }

    func testSaveDocumentError_GivenFailure_WhenOptionSelected_ThenErrorMessageIsCorrect() {
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))
        let viewController = StubDocumentInteractionViewController()
        view.documentInteractionControllerDelegate = viewController
        presenter.start(view: view)
        accountOwnershipProofUseCase.accountOwnershipProofReturnValue = .fail(
            with: .saveFailed(
                error: MockError.dummy
            )
        )

        XCTAssertNil(view.showErrorAlertReceivedArguments?.message)
        presenter.selectedOption(at: 1, sender: view)
        XCTAssertEqual(
            view.showErrorAlertReceivedArguments?.message,
            L10n.BalanceKit.Error.ProofOfAccountOwnership.saveFailed(MockError.dummy.localizedDescription)
        )
    }

    func testDownloadDocumentError_GivenFailure_WhenOptionSelected_ThenErrorMessageIsCorrect() {
        let error = ClientError(httpCode: 400)
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))
        let viewController = StubDocumentInteractionViewController()
        view.documentInteractionControllerDelegate = viewController
        presenter.start(view: view)
        accountOwnershipProofUseCase.accountOwnershipProofReturnValue = .fail(
            with: .downloadFailed(
                error: error
            )
        )

        XCTAssertNil(view.showErrorAlertReceivedArguments?.message)
        presenter.selectedOption(at: 1, sender: view)
        XCTAssertEqual(
            view.showErrorAlertReceivedArguments?.message,
            L10n.BalanceKit.Error.ProofOfAccountOwnership.downloadFailed(
                error.localizedDescription
            )
        )
    }

    func testDisplayingHud_GivenSuccess_WhenFetchingAccountOwnershipProof_ThenHudDisplayAndDismissed() throws {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(#function + ".pdf")

        try "Jane Doe"
            .data(using: .utf8)?
            .write(to: path)

        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))
        let viewController = StubDocumentInteractionViewController()
        view.documentInteractionControllerDelegate = viewController
        presenter.start(view: view)
        accountOwnershipProofUseCase.accountOwnershipProofReturnValue = .just(path)

        let hudShowCount = view.showHudCallsCount
        let hudHideCount = view.hideHudCallsCount
        presenter.selectedOption(at: 1, sender: view)
        XCTAssertEqual(view.hideHudCallsCount, hudHideCount + 1)
        XCTAssertEqual(view.showHudCallsCount, hudShowCount + 1)
    }

    func testDisplayingHud_GivenFailure_WhenFetchingAccountOwnershipProof_ThenHudDisplayAndDismissed() {
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))
        let viewController = StubDocumentInteractionViewController()
        view.documentInteractionControllerDelegate = viewController
        presenter.start(view: view)
        accountOwnershipProofUseCase.accountOwnershipProofReturnValue = .fail(
            with: .saveFailed(
                error: MockError.dummy
            )
        )

        let hudShowCount = view.showHudCallsCount
        let hudHideCount = view.hideHudCallsCount
        presenter.selectedOption(at: 1, sender: view)
        XCTAssertEqual(view.hideHudCallsCount, hudHideCount + 1)
        XCTAssertEqual(view.showHudCallsCount, hudShowCount + 1)
    }
}
