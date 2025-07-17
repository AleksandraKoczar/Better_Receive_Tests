import DeepLinkKitTestingSupport
import NeptuneTestingSupport
import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TravelHubKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

final class QuickpayFlowTests: TWTestCase {
    private let profile = FakeBusinessProfileInfo().asProfile()
    private var flowStarted = false
    private var flowResult: QuickpayFlowResult!
    private var flowDispatcher: TestFlowDispatcher!
    private var flow: QuickpayFlow!
    private var userProvider: StubUserProvider!
    private var featureService: StubFeatureService!
    private var viewControllerFactory: WisetagViewControllerFactoryMock!
    private var qrDownloadViewControllerFactory: QRDownloadViewControllerFactoryMock!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var navigationController: MockNavigationController!
    private var cameraRollPermissionFlowFactory: CameraRollPermissionFlowFactoryMock!
    private var accountDetailsFlowFactory: SingleAccountDetailsFlowFactoryMock!
    private var pasteboard: MockPasteboard!
    private var dismisser: FakeViewControllerDismisser!
    private var allDeepLinksUIFactory: AllDeepLinksUIFactoryMock!
    private var webViewControllerFactory: WebViewControllerFactoryMock.Type!
    private var feedbackFlowFactory: AutoSubmittingFeedbackFlowFactoryMock!
    private var feedbackService: FeedbackServiceMock!
    private var paymentMethodsDynamicFlowHandler: PaymentMethodsDynamicFlowHandlerMock!

    override func setUp() {
        super.setUp()
        userProvider = StubUserProvider()
        featureService = StubFeatureService()
        viewControllerFactory = WisetagViewControllerFactoryMock()
        qrDownloadViewControllerFactory = QRDownloadViewControllerFactoryMock()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        allDeepLinksUIFactory = AllDeepLinksUIFactoryMock()
        accountDetailsFlowFactory = SingleAccountDetailsFlowFactoryMock()
        navigationController = MockNavigationController()
        cameraRollPermissionFlowFactory = CameraRollPermissionFlowFactoryMock()
        dismisser = FakeViewControllerDismisser()
        pasteboard = MockPasteboard()
        feedbackFlowFactory = AutoSubmittingFeedbackFlowFactoryMock()
        feedbackService = FeedbackServiceMock()
        flowDispatcher = TestFlowDispatcher()
        paymentMethodsDynamicFlowHandler = PaymentMethodsDynamicFlowHandlerMock()
        webViewControllerFactory = WebViewControllerFactoryMock.self
        flow = QuickpayFlow(
            profile: profile,
            userProvider: userProvider,
            featureService: featureService,
            viewControllerFactory: viewControllerFactory,
            qrDownloadViewControllerFactory: qrDownloadViewControllerFactory,
            viewControllerPresenterFactory: viewControllerPresenterFactory,
            feedbackFlowFactory: feedbackFlowFactory,
            paymentMethodsDynamicFlowHandler: paymentMethodsDynamicFlowHandler,
            feedbackService: feedbackService,
            accountDetailsFlowFactory: accountDetailsFlowFactory,
            webViewControllerFactory: webViewControllerFactory,
            navigationController: navigationController,
            allDeepLinksUIFactory: allDeepLinksUIFactory,
            cameraRollPermissionFlowFactory: cameraRollPermissionFlowFactory,
            pasteboard: pasteboard,
            flowPresenter: .test(with: flowDispatcher)
        )
        flow.onStart { self.flowStarted = true }
        flow.onFinish { result, _ in self.flowResult = result }
    }

    override func tearDown() {
        flowStarted = false
        flowResult = nil
        flow = nil
        feedbackFlowFactory = nil
        feedbackService = nil
        flowDispatcher = nil
        viewControllerFactory = nil
        allDeepLinksUIFactory = nil
        viewControllerPresenterFactory = nil
        navigationController = nil
        pasteboard = nil
        qrDownloadViewControllerFactory = nil

        super.tearDown()
    }

    func test_start_givenEligibleForQuickpay() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makeQuickpayReturnValue = (viewController, QuickpayShareableLinkStatusUpdaterMock())

        flow.start()

        let pushPresenter = viewControllerPresenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertTrue(pushPresenter.presentedViewController === viewController)
        XCTAssertTrue(flowStarted)
    }

    func test_terminate() {
        flow.terminate()
        XCTAssertEqual(flowResult, .abort)
    }

    func test_showDiscoverabilitySheet() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makeManageQuickpayReturnValue = viewController
        let viewController2 = ViewControllerMock()
        viewControllerFactory.makeContactOnWiseReturnValue = viewController2
        let nickname = LoremIpsum.veryShort

        flow.showManageQuickpay(nickname: nickname)
        flow.showDiscoverability(nickname: nickname)

        let bottomSheetPresenter = viewControllerPresenterFactory.bottomSheetPresenter
        XCTAssertTrue(bottomSheetPresenter.presentCalled)
        XCTAssertTrue(bottomSheetPresenter.presentedViewController === viewController)
        let arguments = try XCTUnwrap(viewControllerFactory.makeContactOnWiseReceivedArguments)
        XCTAssertEqual(arguments.nickname, nickname)

        let presentedViewController = try XCTUnwrap(bottomSheetPresenter.presentedViewControllers[1])
        XCTAssertTrue(presentedViewController === viewController2)
    }

    func test_dismiss_givenShareableLinkIsDiscoverable_thenFlowFinish() throws {
        flow.dismiss(isShareableLinkDiscoverable: true)

        XCTAssertEqual(flowResult, .completed(isShareableLinkDiscoverable: true))
    }

    func test_dismiss_givenShareableLinkIsNotDiscoverable_thenFlowFinish() throws {
        flow.dismiss(isShareableLinkDiscoverable: false)

        XCTAssertEqual(flowResult, .completed(isShareableLinkDiscoverable: false))
    }

    func test_startDownload() throws {
        let image = UIImage()
        let viewController = ViewControllerMock()
        qrDownloadViewControllerFactory.makeDownloadBottomSheetReturnValue = viewController

        flow.startDownload(image: image)

        let bottomSheetPresenter = viewControllerPresenterFactory.bottomSheetPresenter
        XCTAssertTrue(bottomSheetPresenter.presentCalled)
        XCTAssertTrue(bottomSheetPresenter.presentedViewController === viewController)
        let arguments = try XCTUnwrap(qrDownloadViewControllerFactory.makeDownloadBottomSheetReceivedArguments)
        XCTAssertEqual(arguments.image, image)
    }

    func test_showManageQuickpay() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makeManageQuickpayReturnValue = viewController
        flow.showManageQuickpay(nickname: LoremIpsum.short)

        let bottomSheetPresenter = viewControllerPresenterFactory.bottomSheetPresenter
        XCTAssertTrue(bottomSheetPresenter.presentCalled)
        XCTAssertTrue(bottomSheetPresenter.presentedViewController === viewController)
        let arguments = try XCTUnwrap(viewControllerFactory.makeManageQuickpayReceivedArguments)
        XCTAssertEqual(arguments.nickname, LoremIpsum.short)
    }

    func test_showManageQuickpay_thenShowMethodsManagement() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makeManageQuickpayReturnValue = viewController
        let viewController2 = WebContentViewController(url: Branding.current.url)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = viewController2

        flow.showManageQuickpay(nickname: LoremIpsum.short)
        flow.showPaymentMethodsOnWeb()

        XCTAssertTrue(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationCalled)
        let arguments = try XCTUnwrap(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReceivedArguments)
        XCTAssertEqual(
            arguments.url,
            Branding.current.url.appendingPathComponent("/payments/method-management")
        )
        XCTAssertEqual(navigationController.presentInvokedCount, 1)
        let presentedViewController = try XCTUnwrap(navigationController.lastPresentedViewController as? TWNavigationController)
        XCTAssertTrue(presentedViewController.topViewController === viewController2)
    }

    func test_personaliseTapped_givenQuickpayABTestOn() throws {
        featureService.stub(value: true, for: ReceiveKitFeatures.quickpayToInPersonExperiment)
        viewControllerFactory.makeQuickpayReturnValue = (ViewControllerMock(), QuickpayShareableLinkStatusUpdaterMock())
        let viewController = UIViewControllerMock()
        viewControllerFactory.makeQuickpayInPersonReturnValue = (
            viewController,
            QuickpayShareableLinkStatusUpdaterMock()
        )

        flow.start()
        flow.personaliseTapped(status: .discoverable(urlString: "", nickname: ""))

        XCTAssertTrue(navigationController.lastPushedViewController == viewController)
    }

    func test_personaliseTapped_givenQuickpayABTestOff() throws {
        featureService.stub(value: false, for: ReceiveKitFeatures.quickpayToInPersonExperiment)
        viewControllerFactory.makeQuickpayReturnValue = (ViewControllerMock(), QuickpayShareableLinkStatusUpdaterMock())
        let viewController = UIViewControllerMock()
        viewControllerFactory.makeQuickpayPersonaliseReturnValue = viewController

        flow.start()
        flow.personaliseTapped(status: .discoverable(urlString: "", nickname: ""))

        XCTAssertTrue(navigationController.lastPushedViewController == viewController)
    }

    func test_feedbackTapped_thenStartFeedbackFlow_thenFlowFinishedWithSuccess() throws {
        let dismisser = FakeViewControllerDismisser()
        let mockFlow = MockFlow<AutoSubmittingFeedbackFlowResult>()
        let viewController = ViewControllerMock()
        viewControllerFactory.makeQuickpayReturnValue = (viewController, QuickpayShareableLinkStatusUpdaterMock())
        feedbackFlowFactory.makeReturnValue = mockFlow

        flow.start()
        flow.showFeedback(model: .canned, context: .canned, onSuccess: {})

        XCTAssertTrue(feedbackFlowFactory.makeCalled)
        XCTAssertTrue(mockFlow.startCalled)

        mockFlow.flowHandler.flowFinished(result: .success, dismisser: dismisser)

        XCTAssertTrue(dismisser.dismissCalled)
    }

    func test_cardNudgeTapped_thenStartDyanmicFlow() throws {
        let delegate = PaymentMethodsDelegateMock()
        let dynamicForms = [PaymentMethodDynamicForm.build(flowId: "", url: "")]

        flow.showDynamicFormsMethodManagement(dynamicForms, delegate: delegate)

        XCTAssertTrue(paymentMethodsDynamicFlowHandler.showDynamicFormsCalled)
    }
}
