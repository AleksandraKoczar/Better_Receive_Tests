import AnalyticsKitTestingSupport
import Neptune
import NeptuneTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

final class SalarySwitchFlowTests: TWTestCase {
    private var flow: SalarySwitchFlow!
    private var navigationController: MockNavigationController!
    private var orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactoryMock!
    private var salarySwitchUpsellFactory: SalarySwitchUpsellFactoryMock!
    private var presenterFactory: FakeViewControllerPresenterFactory!
    private var articleFactory: HelpCenterArticleFactoryMock!

    override func setUp() {
        super.setUp()

        presenterFactory = FakeViewControllerPresenterFactory()
        navigationController = MockNavigationController()
        orderAccountDetailsFlowFactory = OrderAccountDetailsFlowFactoryMock()
        salarySwitchUpsellFactory = SalarySwitchUpsellFactoryMock()
        articleFactory = HelpCenterArticleFactoryMock()

        flow = SalarySwitchFlow(
            origin: .addMoney,
            accountDetailsRequirementStatus: .hasActiveAccountDetails(balanceId: BalanceId(64)),
            profile: FakePersonalProfileInfo().asProfile(),
            currencyCode: .GBP,
            presenterFactory: presenterFactory,
            host: navigationController,
            articleFactory: articleFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            salarySwitchUpsellFactory: salarySwitchUpsellFactory,
            analyticsTracker: StubAnalyticsTracker()
        )

        salarySwitchUpsellFactory.makePresenterReturnValue = SalarySwitchUpsellPresenterMock()
    }

    override func tearDown() {
        presenterFactory = nil
        navigationController = nil
        orderAccountDetailsFlowFactory = nil
        salarySwitchUpsellFactory = nil
        flow = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension SalarySwitchFlowTests {
    func testSalarySwitchFlow_WhenFlowStarted_ThenFlowStartHandlerInvoked() {
        let exp = expectation(description: #function)
        flow.onStart {
            exp.fulfill()
        }
        flow.start()

        waitForExpectations(timeout: .defaultExpectationTimeout)
    }

    func testSalarySwitchFlow_WhenFlowTerminated_ThenFlowFinishedHandlerInvoked() {
        let exp = expectation(description: #function)
        flow.onFinish { _, _ in
            exp.fulfill()
        }
        flow.start()
        flow.terminate()

        waitForExpectations(timeout: .defaultExpectationTimeout)
    }
}
