import ApiKit
import ApiKitTestingSupport
import DeepLinkKitTestingSupport
import NeptuneTestingSupport
import PersistenceKit
import PersistenceKitTestingSupport
import ReceiveKit
@testable import ReceiveUIKit
import Testing
import TWFoundation
import TWFoundationTestingSupport
import TWUITestingSupport
import UserKitTestingSupport

@MainActor
struct PaymentRequestRefundFlowTests {
    private var flow: PaymentRequestRefundFlow!
    private var navigationController: MockNavigationController!
    private var flowHandlerHelper: FlowHandlerHelper<Void>!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var flowDispatcher: TestFlowDispatcher!

    init() {
        navigationController = MockNavigationController()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        GOS[APIClientKey.self] = StubApiClient()
        GOS[CoreDataAccessorKey.self] = PersistenceKitLoader.makeInMemoryDataAccessor()
        flowDispatcher = TestFlowDispatcher()

        let deepLinksUIFactory = AllDeepLinksUIFactoryMock()
        deepLinksUIFactory.buildReturnValue = MockFlow<Void>()

        flow = PaymentRequestRefundFlow(
            paymentId: "",
            profileId: .canned,
            navigationController: navigationController,
            viewControllerPresenterFactory: viewControllerPresenterFactory,
            allDeepLinksUIFactory: deepLinksUIFactory,
            flowPresenter: .test(with: flowDispatcher)
        )
        flowHandlerHelper = FlowHandlerHelper<Void>()
        flow.flowHandler = flowHandlerHelper.flowHandler
    }

    @Test
    func flowStarted() {
        flow.start()

        #expect(flowHandlerHelper.flowStartedCalled)
        #expect(viewControllerPresenterFactory.pushPresenter.presentedViewController is SwiftUIHostingController<CreateRefundView>)
    }

    @Test
    func reviewShown() {
        flow.start()
        flow.refundInitiated(.canned)

        #expect(viewControllerPresenterFactory.pushPresenter.presentedViewControllers.last is SwiftUIHostingController<ReviewRefundView>)
    }

    @Test
    func successShown() {
        flow.start()
        flow.showSuccess(refund: .canned)

        #expect(viewControllerPresenterFactory.pushPresenter.presentedViewControllers.last is
            PromptViewController)
    }

    @Test
    func failureShown() {
        flow.start()
        flow.showFailure()

        #expect(viewControllerPresenterFactory.pushPresenter.presentedViewControllers.last is
            PromptViewController)
    }

    @Test
    func topUpFlowShown() {
        flow.start()
        flow.topUp(balanceId: .canned, completion: {})

        #expect(flowDispatcher.lastFlowPresented is any Flow<Void>)
    }
}
