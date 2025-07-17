import AnalyticsKitTestingSupport
import DynamicFlow
import DynamicFlowKitTestingSupport
import NeptuneTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import WiseCore

final class RequestMoneyCardOnboardingFlowTests: TWTestCase {
    private let profileId = ProfileId(12345678)
    private var flowResult: RequestMoneyCardOnboardingFlowResult?

    private var flow: RequestMoneyCardOnboardingFlow!
    private var navigationController: MockNavigationController!
    private var analyticsTracker: StubAnalyticsTracker!
    private var paymentMethodsUseCase: PaymentMethodsUseCaseMock!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var dynamicFlowFactory: DynamicFlowFactoryMock!
    private var promptViewControllerFactory: RequestMoneyCardOnboardingPromptViewControllerFactoryMock!

    override func setUp() {
        super.setUp()
        navigationController = MockNavigationController()
        analyticsTracker = StubAnalyticsTracker()
        paymentMethodsUseCase = PaymentMethodsUseCaseMock()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        dynamicFlowFactory = DynamicFlowFactoryMock()
        promptViewControllerFactory = RequestMoneyCardOnboardingPromptViewControllerFactoryMock()
        let configuration = RequestMoneyCardOnboardingFlow.Configuration(
            source: .profileId(profileId),
            shouldShowAvailablePromptWhenFinished: true
        )
        flow = makeFlow(configuration: configuration)
        flow.onFinish { result, _ in self.flowResult = result }
    }

    override func tearDown() {
        flowResult = nil
        flow = nil
        navigationController = nil
        analyticsTracker = nil
        paymentMethodsUseCase = nil
        viewControllerPresenterFactory = nil
        dynamicFlowFactory = nil
        promptViewControllerFactory = nil
        super.tearDown()
    }

    func test_start_givenSourceIsLaunchpadPromotion_andCardIsAvailable_thenPresentCorrectPrompt() throws {
        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.available)
        let viewController = MockViewController()
        promptViewControllerFactory.makeCardAvailableReturnValue = viewController

        flow.start()

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        let pushPresenter = viewControllerPresenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertTrue(pushPresenter.presentedViewControllers.last === viewController)
        XCTAssertEqual(
            analyticsTracker.trackedMixpanelEventNames,
            [
                "Request Setup Flow - Started",
                "Request Setup Flow - Loaded",
            ]
        )
        let propertyValue = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["State"] as? String)
        XCTAssertEqual(propertyValue, "AVAILABILE")
    }

    func test_primaryActionOnAvailablePrompt_thenFlowIsCompleted() throws {
        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.available)
        promptViewControllerFactory.makeCardAvailableReturnValue = MockViewController()
        flow.start()

        let arguments = try XCTUnwrap(promptViewControllerFactory.makeCardAvailableReceivedArguments)
        arguments.primaryButtonAction(MockViewController())

        XCTAssertEqual(flowResult, .completed)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Request Setup Flow - Finished"
        )
        let propertyValue = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["isSuccess"] as? Bool)
        XCTAssertTrue(propertyValue)
    }

    func test_secondaryActionOnAvailablePrompt_thenFlowIsDismissed() throws {
        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.available)
        promptViewControllerFactory.makeCardAvailableReturnValue = MockViewController()
        flow.start()

        let arguments = try XCTUnwrap(promptViewControllerFactory.makeCardAvailableReceivedArguments)
        arguments.secondaryButtonAction(MockViewController())

        XCTAssertEqual(flowResult, .dismissed)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Request Setup Flow - Finished"
        )
        let propertyValue = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["isSuccess"] as? Bool)
        XCTAssertTrue(propertyValue)
    }

    func test_start_givenSourceIsLaunchpadPromotion_andCardIsIneligible_thenPresentCorrectPrompt() throws {
        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.ineligible)
        let viewController = MockViewController()
        promptViewControllerFactory.makeCardIneligibleReturnValue = viewController

        flow.start()

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        let pushPresenter = viewControllerPresenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertTrue(pushPresenter.presentedViewControllers.last === viewController)
        XCTAssertEqual(
            analyticsTracker.trackedMixpanelEventNames,
            [
                "Request Setup Flow - Started",
                "Request Setup Flow - Loaded",
            ]
        )
        let propertyValue = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["State"] as? String)
        XCTAssertEqual(propertyValue, "NOT_ELIGIBLE")
    }

    func test_primaryActionOnIneligiblePrompt_thenFlowIsDismissed() throws {
        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.ineligible)
        promptViewControllerFactory.makeCardIneligibleReturnValue = MockViewController()
        flow.start()

        let primaryButtonAction = try XCTUnwrap(promptViewControllerFactory.makeCardIneligibleReceivedPrimaryButtonAction)
        primaryButtonAction(MockViewController())

        XCTAssertEqual(flowResult, .dismissed)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Request Setup Flow - Finished"
        )
        let propertyValue = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["isSuccess"] as? Bool)
        XCTAssertFalse(propertyValue)
    }

    func test_start_givenSourceIsLaunchpadPromotion_andCardIsEligible_thenPresentOnboarding() throws {
        let dynamicForm = PaymentMethodAvailability.DynamicForm.build(
            flowId: LoremIpsum.veryShort,
            url: LoremIpsum.short
        )
        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.eligible(dynamicForms: [dynamicForm]))

        flow.start()

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        let resource = try XCTUnwrap(dynamicFlowFactory.lastRestGwResource)
        XCTAssertEqual(resource.request.path, dynamicForm.url)
        XCTAssertEqual(
            analyticsTracker.trackedMixpanelEventNames,
            [
                "Request Setup Flow - Started",
                "Request Setup Flow - Loaded",
            ]
        )
        let propertyValue = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["State"] as? String)
        XCTAssertEqual(propertyValue, "ELIGIBLE")
    }

    func test_start_givenSourceIsLaunchpadPromotion_butFetchCardAvailabilityFails_thenShowError() throws {
        paymentMethodsUseCase.cardAvailabilityReturnValue = .fail(with: MockError.dummy)

        flow.start()

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        XCTAssertTrue(navigationController.didShowDismissableAlertWithAction)
    }

    func test_dismissableAlertAction_thenFlowIsDismissed() throws {
        paymentMethodsUseCase.cardAvailabilityReturnValue = .fail(with: MockError.dummy)
        flow.start()

        let dismissAction = try XCTUnwrap(navigationController.showDismissableAlertReceivedDismissAction)
        dismissAction()

        XCTAssertEqual(flowResult, .dismissed)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Request Setup Flow - Finished"
        )
        let propertyValue = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["isSuccess"] as? Bool)
        XCTAssertFalse(propertyValue)
    }

    func test_start_givenSourceIsPaymentMethodSelection_thenPresentOnboarding() throws {
        let dynamicForm = PaymentMethodAvailability.DynamicForm.build(
            flowId: LoremIpsum.veryShort,
            url: LoremIpsum.short
        )
        let configuration = RequestMoneyCardOnboardingFlow.Configuration(
            source: .dynamicForms([dynamicForm]),
            shouldShowAvailablePromptWhenFinished: false
        )
        flow = makeFlow(configuration: configuration)

        flow.start()

        let resource = try XCTUnwrap(dynamicFlowFactory.lastRestGwResource)
        XCTAssertEqual(resource.request.path, dynamicForm.url)
        XCTAssertEqual(
            analyticsTracker.trackedMixpanelEventNames,
            ["Request Setup Flow - Started"]
        )
    }

    // MARK: - Helpers

    func makeFlow(
        configuration: RequestMoneyCardOnboardingFlow.Configuration
    ) -> RequestMoneyCardOnboardingFlow {
        RequestMoneyCardOnboardingFlow(
            configuration: configuration,
            navigationController: navigationController,
            analyticsTracker: analyticsTracker,
            paymentMethodsUseCase: paymentMethodsUseCase,
            viewControllerPresenterFactory: viewControllerPresenterFactory,
            dynamicFlowFactory: dynamicFlowFactory,
            promptViewControllerFactory: promptViewControllerFactory,
            scheduler: .immediate
        )
    }
}
