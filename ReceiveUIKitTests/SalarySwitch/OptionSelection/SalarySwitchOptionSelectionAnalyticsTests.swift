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

final class SalarySwitchOptionSelectionAnalyticsTests: TWTestCase {
    private enum MockError: Error {
        case dummy
    }

    private enum Constants {
        static let eurAccountDetails = AccountDetails.active(.build(
            id: AccountDetailsId(1221),
            currency: .EUR,
            title: "account details",
            receiveOptions: [AccountDetailsReceiveOption.build(shareText: "Sharing")]
        ))
        static let profileId = ProfileId(128)
    }

    private var optionSelectionPresenter: SalarySwitchOptionSelectionPresenter!
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
        optionSelectionPresenter = SalarySwitchOptionSelectionPresenterImpl(
            balanceId: BalanceId(64),
            currencyCode: .EUR,
            profileId: ProfileId(123),
            router: router,
            accountDetailsUseCase: accountDetailsUseCase,
            accountOwnershipProofUseCase: accountOwnershipProofUseCase,
            analyticsTracker: analyticsTracker,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        optionSelectionPresenter = nil
        mockAccountDetailsPublisher = nil
        accountDetailsUseCase = nil
        accountOwnershipProofUseCase = nil
        analyticsTracker = nil
        router = nil
        view = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension SalarySwitchOptionSelectionAnalyticsTests {
    func testAnalytics_GivenViewStarted_ThenStartEventTriggered() throws {
        optionSelectionPresenter.start(view: view)

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Switch Salary Flow - Sharing Options - Started"
        )
    }

    func testAnalytics_GivenViewStarted_ThenStartEventHasCorrectProperties() throws {
        optionSelectionPresenter.start(view: view)

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked?["Currency"] as? String,
            "EUR"
        )
    }

    func testAnalytics_GivenFailure_ThenErrorEventTracked() throws {
        let error = MockError.dummy

        optionSelectionPresenter.start(view: view)
        mockAccountDetailsPublisher.send(.recoverableError(error))
        let expectedEvent = SalarySwitchFlowAnalytics.OptionsView.ErrorShown(
            message: error.localizedDescription
        )

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            expectedEvent.eventName
        )
    }

    func testAnalytics_GivenPOAOOptionSelected_ThenPropertiesMatch() {
        optionSelectionPresenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))
        view.documentInteractionControllerDelegate = StubDocumentInteractionViewController()
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(#function + ".pdf")
        accountOwnershipProofUseCase.accountOwnershipProofReturnValue = .just(path)

        optionSelectionPresenter.selectedOption(at: 1, sender: view)

        let descriptors = analyticsTracker.trackedMixpanelEvents("Switch Salary Flow - Sharing Options - Option Selected")
        let values = descriptors?.compactMap {
            $0.eventProperties()["Option"] as? String
        }

        XCTAssertEqual(
            values?.last,
            "PROOF_OF_ACCOUNT_OWNERSHIP"
        )
    }

    func testAnalytics_GivenShareAccountDetailsOptionSelected_ThenPropertiesMatch() {
        optionSelectionPresenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))

        optionSelectionPresenter.selectedOption(at: 0, sender: view)

        let descriptors = analyticsTracker.trackedMixpanelEvents("Switch Salary Flow - Sharing Options - Option Selected")
        let values = descriptors?.compactMap {
            $0.eventProperties()["Option"] as? String
        }

        XCTAssertEqual(
            values?.last,
            "SHARE_DETAILS"
        )
    }

    func testAnalytics_GivenShareAccountDetailsOptionSelected_ThenCurrencyPropertiesMatch() {
        optionSelectionPresenter.start(view: view)
        mockAccountDetailsPublisher.send(.loaded([Constants.eurAccountDetails]))

        optionSelectionPresenter.selectedOption(at: 0, sender: view)

        let descriptors = analyticsTracker.trackedMixpanelEvents("Switch Salary Flow - Sharing Options - Option Selected")
        let values = descriptors?.compactMap {
            $0.eventProperties()["Currency"] as? String
        }

        XCTAssertEqual(
            values?.last,
            "EUR"
        )
    }
}
