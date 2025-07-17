import AnalyticsKitTestingSupport
import BalanceKit
@testable import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit
@testable import TWUI
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

@MainActor
final class SalarySwitchUpsellPresenterTests: TWTestCase {
    private enum MockError: Error {
        case failed
    }

    private enum Constants {
        static let upsellContinueText = L10n.Account.Details.Receive.Salary.Upsell.button
        static let profile = FakePersonalProfileInfo().asProfile()
    }

    private var presenter: SalarySwitchUpsellPresenterImpl!
    private var useCase: SalarySwitchUpsellUseCaseMock!
    private var router: SalarySwitchUpsellRouterMock!
    private var analyticsTracker: StubAnalyticsTracker!

    override func setUp() {
        super.setUp()

        useCase = SalarySwitchUpsellUseCaseMock()
        router = SalarySwitchUpsellRouterMock()
        analyticsTracker = StubAnalyticsTracker()

        useCase.getUpsellContentReturnValue = .just(SwitchSalaryUpsellContent.canned)
    }

    override func tearDown() {
        presenter = nil
        router = nil
        useCase = nil
        analyticsTracker = nil

        super.tearDown()
    }
}

// MARK: - Tests

// MARK: Upsell

extension SalarySwitchUpsellPresenterTests {
    func testStart_WhenPresenterStarted_ThenUpsellDisplayed() {
        presenter = makePresenter()
        XCTAssertFalse(router.showUpsellCalled)
        presenter.start()
        XCTAssertTrue(router.showUpsellCalled)
    }
}

// MARK: Account details requirement status

extension SalarySwitchUpsellPresenterTests {
    func testOptionSelectionNavigation_GivenHasAccountDetails_WhenContinueTapped_ThenOptionSelectionDisplayed() {
        presenter = makePresenter(requirementStatus: .hasActiveAccountDetails(balanceId: BalanceId(64)))
        presenter.start()
        triggerUpsellContinueButton()

        XCTAssertTrue(router.showOptionSelectionCalled)
    }

    func testFlowNavigation_GivenAccountDetailsRequired_WhenContinueTapped_ThenRoutedToFlow() {
        presenter = makePresenter(
            requirementStatus: .needsAccountDetailsActivation
        )

        presenter.start()
        XCTAssertFalse(router.showOrderAccountDetailsFlowCalled)
        triggerUpsellContinueButton()
        XCTAssertTrue(router.showOrderAccountDetailsFlowCalled)
    }
}

// MARK: Hud & Error displaying

extension SalarySwitchUpsellPresenterTests {
    func testDisplayingHud_WhenPresenterStarted_ThenShowHudCalled() {
        presenter = makePresenter()
        XCTAssertFalse(router.showHudCalled)
        presenter.start()
        XCTAssertTrue(router.showHudCalled)
    }

    func testDisplayingHud_WhenPresenterStarted_ThenHideHudCalled() {
        presenter = makePresenter()
        XCTAssertFalse(router.hideHudCalled)
        presenter.start()
        XCTAssertTrue(router.hideHudCalled)
    }

    func testDisplayingAlert_GivenErrorUpsellContent_WhenPresenterStarted_ThenErrortMessagesMatch() {
        useCase.getUpsellContentReturnValue = .fail(with: MockError.failed)

        presenter = makePresenter()
        XCTAssertNil(router.showErrorAlertReceivedArguments?.message)
        presenter.start()
        XCTAssertEqual(
            router.showErrorAlertReceivedArguments?.message,
            MockError.failed.localizedDescription
        )
    }
}

// MARK: - Helpers

private extension SalarySwitchUpsellPresenterTests {
    func makePresenter(
        requirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus = .hasActiveAccountDetails(balanceId: BalanceId(64))
    ) -> SalarySwitchUpsellPresenterImpl {
        SalarySwitchUpsellPresenterImpl(
            profile: Constants.profile,
            currency: .GBP,
            accountDetailsRequirementStatus: requirementStatus,
            useCase: useCase,
            router: router,
            analyticsTracker: analyticsTracker,
            scheduler: .immediate
        )
    }

    func triggerUpsellContinueButton() {
        router.showUpsellReceivedViewModel!.footerModel?.primaryAction?.handler()
    }
}
