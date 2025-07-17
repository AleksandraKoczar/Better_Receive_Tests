import AnalyticsKitTestingSupport
import DynamicFlow
import DynamicFlowKitTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import WiseCore

final class ReceiveMethodsDFFlowTests: TWTestCase {
    private var flow: (any Flow<ReceiveMethodsDFFlowResult>)!
    private var flowDispatcher: TestFlowDispatcher!
    private var dynamicFlowFactory: DynamicFlowFactoryMock!
    private var accountDetailsUseCase: AccountDetailsV3UseCaseMock!

    override func setUp() {
        super.setUp()

        flowDispatcher = TestFlowDispatcher()
        dynamicFlowFactory = DynamicFlowFactoryMock()
        accountDetailsUseCase = AccountDetailsV3UseCaseMock()

        flow = ReceiveMethodsDFFlow(
            mode: .manage,
            accountDetailsId: AccountDetailsId(32),
            profileId: ProfileId(64),
            hostViewController: UIViewController(),
            accountDetailsUseCase: accountDetailsUseCase,
            dynamicFlowFactory: dynamicFlowFactory,
            flowPresenter: .test(with: flowDispatcher),
            analyticsTracker: StubAnalyticsTracker()
        )
    }

    override func tearDown() {
        flow = nil
        flowDispatcher = nil
        dynamicFlowFactory = nil
        accountDetailsUseCase = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension ReceiveMethodsDFFlowTests {
    func testStart_GivenManageMode_ThenFlowStartedWithCorrectParams() {
        flow.start()

        XCTAssertTrue(
            flowDispatcher.lastFlowPresented is (MockFlow<Result<ReceiveMethodsDFFlow.SuccessResult, FlowFailure>>)
        )

        XCTAssertEqual(
            dynamicFlowFactory.lastRestGwResource?.request.path,
            "/v1/profiles/{profileId}/receive-method/deposit-account/{accountDetailsId}/management/alias"
        )
    }

    func testStart_GivenModeRegistration_ThenCorrectPathPassed() {
        flow = ReceiveMethodsDFFlow(
            mode: .register,
            accountDetailsId: AccountDetailsId(32),
            profileId: ProfileId(64),
            hostViewController: UIViewController(),
            accountDetailsUseCase: accountDetailsUseCase,
            dynamicFlowFactory: dynamicFlowFactory,
            flowPresenter: .test(with: flowDispatcher),
            analyticsTracker: StubAnalyticsTracker()
        )
        flow.start()

        XCTAssertTrue(
            flowDispatcher.lastFlowPresented is (MockFlow<Result<ReceiveMethodsDFFlow.SuccessResult, FlowFailure>>)
        )

        XCTAssertEqual(
            dynamicFlowFactory.lastRestGwResource?.request.path,
            "/v1/profiles/{profileId}/receive-method/deposit-account/{accountDetailsId}/alias/registration-flow"
        )
    }

    func testTerminate() {
        var result: ReceiveMethodsDFFlowResult?
        flow.onFinish { _result, _ in
            result = _result
        }

        flow.start()
        flow.terminate()

        XCTAssertTrue(
            flowDispatcher.lastFlowPresented is (MockFlow<Result<ReceiveMethodsDFFlow.SuccessResult, FlowFailure>>)
        )
        XCTAssertTrue(
            flowDispatcher.lastFlowTerminated is (MockFlow<Result<ReceiveMethodsDFFlow.SuccessResult, FlowFailure>>)
        )
        XCTAssertEqual(result, .notApplicable)
    }

    func testAccountDetailsRefresh_WhenRefreshAccountDetailsCalled_ThenAccountDetailsRefreshed() {
        flow.start()
        XCTAssertFalse(accountDetailsUseCase.refreshCalled)
        dynamicFlowFactory.lastOnFlowCancelled?()
        XCTAssertTrue(accountDetailsUseCase.refreshCalled)
    }
}
