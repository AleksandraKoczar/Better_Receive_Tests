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
    // MARK: - Test Data
    
    private let personalProfile = FakePersonalProfileInfo().asProfile()
    private let businessProfile = FakeBusinessProfileInfo().asProfile()
    
    // MARK: - System Under Test
    
    private var flow: PayWithWiseFlow!
    private var flowFinished = false
    private var flowDismisser: ViewControllerDismisser?
    private var flowStarted = false
    
    // MARK: - Dependencies
    
    private var navigationController: MockNavigationController!
    private var presenterFactory: FakeViewControllerPresenterFactory!
    private var viewControllerFactory: PayWithWiseViewControllerFactoryMock!
    private var requestMoneyFlowFactory: RequestMoneyFlowFactoryMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var pushPresenter: FakeNavigationViewControllerPresenter!
    private var viewController: UIViewController!

    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()

        setupDependencies()
    }

    override func tearDown() {
        flowFinished = false
        flowStarted = false
        flow = nil
        flowDismisser = nil
        navigationController = nil
        presenterFactory = nil
        viewControllerFactory = nil
        requestMoneyFlowFactory = nil
        analyticsTracker = nil
        pushPresenter = nil
        viewController = nil

        super.tearDown()
    }
    
    // MARK: - Flow Initialization Tests
    
    func test_init_setsFlowNavigationDelegate() {
        // When
        makeFlow()
        
        // Then
        XCTAssertTrue(viewControllerFactory.setFlowNavigationDelegateCalled)
        XCTAssertIdentical(viewControllerFactory.setFlowNavigationDelegateReceivedDelegate as AnyObject, flow)
    }
    
    // MARK: - Flow Start Tests
    
    func test_start_createsViewController_andPresentsIt() {
        // Given
        makeFlow()
        
        // When
        flow.start()
        
        // Then
        XCTAssertTrue(viewControllerFactory.makeViewControllerCalled)
        XCTAssertEqual(viewControllerFactory.makeViewControllerReceivedInvocations.count, 1)
        XCTAssertEqual(viewControllerFactory.makeViewControllerReceivedArguments?.profile.id, personalProfile.id)
        
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertIdentical(pushPresenter.presentedViewController, viewController)
    }
    
    func test_start_tracksAnalyticsEvent_withCorrectProperties() {
        // Given
        makeFlow()
        
        // When
        flow.start()
        
        // Then
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Pay with Wise - Started"
        )
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked?["IsSinglePagePayer"] as? String,
            "Yes"
        )
    }
    
    func test_start_callsFlowStarted() {
        // Given
        makeFlow()
        flow.onStart {
            self.flowStarted = true
        }
        
        // When
        flow.start()
        
        // Then
        XCTAssertTrue(flowStarted)
    }
    
    // MARK: - Flow Termination Tests
    
    func test_terminate_callsFlowFinished_withCorrectParameters() {
        // Given
        makeFlow()
        
        // When
        flow.start() // Sets up the dismisser
        flow.terminate()
        
        // Then
        XCTAssertTrue(flowFinished)
        XCTAssertNotNil(flowDismisser)
    }
    
    func test_terminate_tracksFinishedAnalyticsEvent() {
        // Given
        makeFlow()
        
        // When
        flow.terminate()
        
        // Then
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Pay with Wise - Finished"
        )
    }
    
    // MARK: - Request Money Flow Tests
    
    func test_startRequestMoneyFlow_createsAndStartsFlow() {
        // Given
        let mockFlow = MockFlow<Void>()
        requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessReturnValue = mockFlow
        makeFlow()
        
        // When
        flow.startRequestMoneyFlow(profile: personalProfile)
        
        // Then
        XCTAssertEqual(requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessCallsCount, 1)
        XCTAssertEqual(requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessReceivedArguments?.profile.id, personalProfile.id)
        XCTAssertIdentical(
            requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessReceivedArguments?.navigationController, 
            navigationController
        )
        XCTAssertTrue(mockFlow.startCalled)
    }
    
    func test_startRequestMoneyFlow_whenFlowFinishes_finishesMainFlow() {
        // Given
        let mockFlow = MockFlow<Void>()
        requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessReturnValue = mockFlow
        makeFlow()
        flow.startRequestMoneyFlow(profile: personalProfile)
        let mockDismisser = ViewControllerDismisserMock()
        
        // When
        mockFlow.flowHandler.flowFinished(result: (), dismisser: mockDismisser)
        
        // Then
        XCTAssertTrue(flowFinished)
    }
    
    func test_startRequestMoneyFlow_whenFlowFinishes_clearsStoredFlow() {
        // Given
        let mockFlow = MockFlow<Void>()
        requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessReturnValue = mockFlow
        makeFlow()
        flow.startRequestMoneyFlow(profile: personalProfile)
        let mockDismisser = ViewControllerDismisserMock()
        
        // When
        mockFlow.flowHandler.flowFinished(result: (), dismisser: mockDismisser)
        
        // Then
        // Start a new flow to verify the previous one was cleared (otherwise we'd get a strong reference cycle warning)
        let newMockFlow = MockFlow<Void>()
        requestMoneyFlowFactory.makeFlowForPayWithWiseSuccessReturnValue = newMockFlow
        flow.startRequestMoneyFlow(profile: personalProfile)
        XCTAssertTrue(newMockFlow.startCalled)
    }
    
    // MARK: - Navigation Delegate Tests
    
    func test_dismissed_finishesFlow() {
        // Given
        makeFlow()
        flow.start()
        
        // When
        flow.dismissed(at: .singlePagePayer)
        
        // Then
        XCTAssertTrue(flowFinished)
    }
    
    func test_dismissed_passesCorrectDismisser() {
        // Given
        makeFlow()
        
        // When
        flow.start() // Sets up the dismisser
        flow.dismissed(at: .success)
        
        // Then
        XCTAssertTrue(flowFinished)
        XCTAssertNotNil(flowDismisser)
    }
    
    // MARK: - Profile Type Tests
    
    func test_start_withBusinessProfile_usesCorrectProfile() {
        // Given
        makeFlow(profile: businessProfile)
        
        // When
        flow.start()
        
        // Then
        XCTAssertEqual(viewControllerFactory.makeViewControllerReceivedArguments?.profile.id, businessProfile.id)
    }
    
    // MARK: - Helper Methods
    
    private func setupDependencies() {
        navigationController = MockNavigationController()
        presenterFactory = FakeViewControllerPresenterFactory()
        viewController = UIViewController()
        viewControllerFactory = PayWithWiseViewControllerFactoryMock()
        viewControllerFactory.makeViewControllerReturnValue = viewController
        requestMoneyFlowFactory = RequestMoneyFlowFactoryMock()
        analyticsTracker = StubAnalyticsTracker()
        
        pushPresenter = FakeNavigationViewControllerPresenter()
        presenterFactory.pushPresenter = pushPresenter
        pushPresenter.dismisser = ViewControllerDismisserMock()
    }
    
    private func makeFlow(
        profile: Profile = FakePersonalProfileInfo().asProfile()
    ) {
        flow = PayWithWiseFlow(
            profile: profile,
            host: navigationController,
            presenterFactory: presenterFactory,
            viewControllerFactory: viewControllerFactory,
            requestMoneyFlowFactory: requestMoneyFlowFactory,
            analyticsTracker: analyticsTracker
        )
        flow.onFinish { [weak self] _, dismisser in 
            self?.flowFinished = true
            self?.flowDismisser = dismisser
        }
    }
}
