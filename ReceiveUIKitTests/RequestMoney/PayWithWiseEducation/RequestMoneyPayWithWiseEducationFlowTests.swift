import NeptuneTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import TWUITestingSupport

final class RequestMoneyPayWithWiseEducationFlowTests: TWTestCase {
    private var flow: RequestMoneyPayWithWiseEducationFlow!
    private var educationviewControllerFactory: RequestMoneyPayWithWiseEducationViewControllerFactoryMock!
    private var viewControllerPresenter: FakeBottomSheetPresenter!

    private var flowStarted = false
    private var flowResult: RequestMoneyPayWithWiseEducationFlowResult?

    override func setUp() {
        super.setUp()
        educationviewControllerFactory = RequestMoneyPayWithWiseEducationViewControllerFactoryMock()
        viewControllerPresenter = FakeBottomSheetPresenter()
        flow = RequestMoneyPayWithWiseEducationFlow(
            educationviewControllerFactory: educationviewControllerFactory,
            viewControllerPresenter: viewControllerPresenter
        )
        flow.onStart { self.flowStarted = true }
        flow.onFinish { result, _ in self.flowResult = result }
    }

    override func tearDown() {
        flowStarted = false
        flowResult = nil
        flow = nil
        educationviewControllerFactory = nil
        viewControllerPresenter = nil
        super.tearDown()
    }

    func test_start() {
        let viewController = ViewControllerMock()
        educationviewControllerFactory.makeReturnValue = viewController

        flow.start()

        XCTAssertTrue(flowStarted)
        XCTAssertEqual(educationviewControllerFactory.makeCallsCount, 1)
        XCTAssertTrue(viewControllerPresenter.presentCalled)
        XCTAssertTrue(viewControllerPresenter.presentedViewController === viewController)
    }

    func test_terminate() {
        flow.terminate()

        XCTAssertEqual(flowResult, .cancelled)
    }

    func test_showInviteFriends() {
        flow.showInviteFriends()

        XCTAssertEqual(flowResult, .inviteFriendsSelected)
    }

    func test_dismiss() {
        flow.dismiss()

        XCTAssertEqual(flowResult, .cancelled)
    }
}
