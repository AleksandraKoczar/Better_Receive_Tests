import AnalyticsKitTestingSupport
import Neptune
import NeptuneTestingSupport
import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKit
import UserKitTestingSupport

final class PayWithWiseFlowTests: TWTestCase {
    private var flowFinished = false

    private var flow: PayWithWiseFlow!
    private var presenterFactory: FakeViewControllerPresenterFactory!
    private var viewControllerFactory: PayWithWiseViewControllerFactoryMock!
    private var requestMoneyFlowFactory: RequestMoneyFlowFactoryMock!
    private var analyticsTracker: StubAnalyticsTracker!

    override func setUp() {
        super.setUp()

        presenterFactory = FakeViewControllerPresenterFactory()
        viewControllerFactory = PayWithWiseViewControllerFactoryMock()
        viewControllerFactory.makeViewControllerReturnValue = UIViewController()
        requestMoneyFlowFactory = RequestMoneyFlowFactoryMock()
        analyticsTracker = StubAnalyticsTracker()
    }

    override func tearDown() {
        flowFinished = false
        flow = nil
        presenterFactory = nil
        viewControllerFactory = nil
        requestMoneyFlowFactory = nil
        analyticsTracker = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension PayWithWiseFlowTests {
    func testStart_GivenTrueForRedesignFeatureFlag_WhenFlowStarted_ThenV2ViewControllerCreated() {
        makeFlow()
        flow.start()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Pay with Wise - Started"
        )
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked?["IsSinglePagePayer"] as? String,
            "Yes"
        )
        XCTAssertTrue(viewControllerFactory.makeViewControllerCalled)
    }

    func testStartRequestMoneyFlow() {
        let mockFlow = MockFlow<Void>()
        requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessReturnValue = mockFlow

        makeFlow()
        flow.startRequestMoneyFlow(profile: FakePersonalProfileInfo().asProfile())

        XCTAssertEqual(requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessCallsCount, 1)
        XCTAssertTrue(mockFlow.startCalled)
    }

    func testStartRequestMoneyFlow_GivenRequestMoneyFinished_ThenCallFlowFinished() {
        let mockFlow = MockFlow<Void>()
        requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessReturnValue = mockFlow
        makeFlow()
        flow.startRequestMoneyFlow(profile: FakePersonalProfileInfo().asProfile())

        mockFlow.flowHandler.flowFinished(result: (), dismisser: nil)

        XCTAssertTrue(flowFinished)
    }
}

// MARK: - Helpers

private extension PayWithWiseFlowTests {
    func makeFlow(
        profile: Profile = FakePersonalProfileInfo().asProfile()
    ) {
        flow = PayWithWiseFlow(
            profile: profile,
            host: MockNavigationController(),
            presenterFactory: presenterFactory,
            viewControllerFactory: viewControllerFactory,
            requestMoneyFlowFactory: requestMoneyFlowFactory,
            analyticsTracker: analyticsTracker
        )
        flow.onFinish { _, _ in self.flowFinished = true }
    }
}
