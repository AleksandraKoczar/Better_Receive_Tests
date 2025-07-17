import BalanceKit
import Neptune
import NeptuneTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

final class SalarySwitchUpsellRouterTests: TWTestCase {
    private enum Constants {
        static let profile = FakePersonalProfileInfo().asProfile()
        static let currency = CurrencyCode.GBP
        static let articlePath = "help/articles/2949782"
        static let articleId = HelpCenterArticleId(rawValue: "2949782")
    }

    private var router: SalarySwitchUpsellRouter!
    private var navigationController: MockNavigationController!
    private var orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactoryMock!
    private var presenterFactory: FakeViewControllerPresenterFactory!
    private var factory: SalarySwitchFactoryMock!
    private var articleFactory: HelpCenterArticleFactoryMock!

    private var capturedDismisser: ViewControllerDismisser?

    override func setUp() {
        super.setUp()

        presenterFactory = FakeViewControllerPresenterFactory()
        navigationController = MockNavigationController()
        orderAccountDetailsFlowFactory = OrderAccountDetailsFlowFactoryMock()
        factory = SalarySwitchFactoryMock()
        articleFactory = HelpCenterArticleFactoryMock()

        router = SalarySwitchUpsellRouterImpl(
            host: navigationController,
            presenterFactory: presenterFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            factory: factory,
            articleFactory: articleFactory,
            dismisserCapturer: { [weak self] dismisser in
                self?.capturedDismisser = dismisser
            }
        )
    }

    override func tearDown() {
        router = nil
        presenterFactory = nil
        navigationController = nil
        orderAccountDetailsFlowFactory = nil
        articleFactory = nil
        factory = nil

        super.tearDown()
    }
}

// MARK: - Upsell

extension SalarySwitchUpsellRouterTests {
    func testRoutingToUpsell() throws {
        routeToUpsell()
        let navigationController = try XCTUnwrap(
            presenterFactory.modalPresenter.presentedViewControllers.first as? UINavigationController
        )

        XCTAssertTrue(navigationController.viewControllers.first is UpsellViewController)
    }

    func testDismisserCapturer_WhenUpsellDisplayed_ThenDismisserIsCaptured() throws {
        XCTAssertNil(capturedDismisser)
        routeToUpsell()
        XCTAssertNotNil(capturedDismisser)
    }
}

// MARK: - Order account details flow navigation

extension SalarySwitchUpsellRouterTests {
    func testRoutingOrderAccountDetailsFlow_WhenRoutingInvoked_ThenFlowStarted() throws {
        let stubFlow = MockFlow<OrderAccountDetailsFlowResult>()
        orderAccountDetailsFlowFactory.makeFlowReturnValue = stubFlow

        routeToUpsell()

        XCTAssertFalse(stubFlow.startCalled)
        router.showOrderAccountDetailsFlow(
            profile: Constants.profile,
            currency: Constants.currency
        )

        XCTAssertTrue(stubFlow.startCalled)
    }

    func testRoutingOrderAccountDetailsFlow_WhenFlowFinishInvoked_ThenDismisserCalled() throws {
        let stubFlow = createAndRouteToOrderAccountDetailsFlow()

        let dismisser = FakeViewControllerDismisser()

        XCTAssertFalse(dismisser.dismissCalled)
        stubFlow.flowHandler.flowFinished(result: .ordered, dismisser: dismisser)
        XCTAssertTrue(dismisser.dismissCalled)
    }

    func testRoutingOrderAccountDetailsFlow_WhenAccountDetailsOrdered_ThenNotificationReceived() throws {
        let stubFlow = createAndRouteToOrderAccountDetailsFlow()

        let exp = expectation(description: #function)

        let observer = NotificationCenter.default.addObserver(
            forName: .balancesNeedUpdate,
            object: nil,
            queue: nil
        ) { _ in
            exp.fulfill()
        }
        stubFlow.flowHandler.flowFinished(result: .ordered, dismisser: nil)
        waitForExpectations(timeout: .defaultExpectationTimeout)
        NotificationCenter.default.removeObserver(observer)
    }

    func testRoutingOrderAccountDetailsFlow_WhenAccountDetailsNotOrdered_ThenNoNotificationReceived() throws {
        let stubFlow = createAndRouteToOrderAccountDetailsFlow()

        let exp = expectation(description: #function)

        var notificationCount = 0
        let observer = NotificationCenter.default.addObserver(
            forName: .balancesNeedUpdate,
            object: nil,
            queue: nil
        ) { _ in
            notificationCount += 1
            exp.fulfill()
        }
        stubFlow.flowHandler.flowFinished(result: .accountDetailsOpen, dismisser: nil)
        stubFlow.flowHandler.flowFinished(result: .dismissed, dismisser: nil)
        stubFlow.flowHandler.flowFinished(result: .abortedWithError, dismisser: nil)
        stubFlow.flowHandler.flowFinished(result: .ordered, dismisser: nil)

        waitForExpectations(timeout: .defaultExpectationTimeout)
        NotificationCenter.default.removeObserver(observer)
        XCTAssertEqual(notificationCount, 1)
    }
}

// MARK: - Hud & Alerts

extension SalarySwitchUpsellRouterTests {
    func testShowingHud() {
        XCTAssertFalse(navigationController.didShowHud)
        router.showHud()
        XCTAssertTrue(navigationController.didShowHud)
    }

    func testHidingHud() {
        XCTAssertFalse(navigationController.didHideHud)
        router.hideHud()
        XCTAssertTrue(navigationController.didHideHud)
    }

    func testShowingErrorAlert_GivenTitleAndMessage_ThenBothMatches() {
        let title = "Error"
        let message = "Sth went wrong"
        router.showErrorAlert(title: title, message: message)
        XCTAssertEqual(navigationController.errorTitle, title)
        XCTAssertEqual(navigationController.errorMessage, message)
    }
}

// MARK: - Option Selection

extension SalarySwitchUpsellRouterTests {
    func testRoutingToOptionSelection_WhenRouting_ThenViewControllerTypeMatches() {
        factory.makeOptionsSelectionViewControllerReturnValue = SalarySwitchOptionSelectionViewController(
            presenter: SalarySwitchOptionSelectionPresenterMock()
        )

        routeToUpsell()
        router.showOptionSelection(
            balanceId: BalanceId(64),
            currency: Constants.currency,
            profileId: Constants.profile.id
        )

        XCTAssertTrue(presenterFactory.pushPresenter.presentedViewControllers.first is SalarySwitchOptionSelectionViewController)
    }
}

// MARK: - FAQ

extension SalarySwitchUpsellRouterTests {
    func testRoutingToFAQ_GivenPartialPath_ThenFullPathsMatch() {
        let contactFlow = MockFlow<Void>()
        articleFactory.isArticleLinkReturnValue = Constants.articleId
        articleFactory.makeArticleFlowReturnValue = contactFlow
        routeToUpsell()
        router.showFAQ(path: Constants.articlePath)
        XCTAssertTrue(contactFlow.startCalled)
    }

    func testRoutingToFAQ_GivenDummyViewController_ThenDummyPresented() {
        articleFactory.isArticleLinkReturnValue = Constants.articleId
        let contactFlow = MockFlow<Void>()
        articleFactory.makeArticleFlowReturnValue = contactFlow
        routeToUpsell()
        router.showFAQ(path: Constants.articlePath)
        XCTAssertTrue(contactFlow.startCalled)
    }
}

// MARK: - Helpers

private extension SalarySwitchUpsellRouterTests {
    func createAndRouteToOrderAccountDetailsFlow() -> MockFlow<OrderAccountDetailsFlowResult> {
        let stubFlow = MockFlow<OrderAccountDetailsFlowResult>()
        orderAccountDetailsFlowFactory.makeFlowReturnValue = stubFlow

        routeToUpsell()
        router.showOrderAccountDetailsFlow(
            profile: Constants.profile,
            currency: Constants.currency
        )
        return stubFlow
    }

    func routeToUpsell() {
        let viewModel = UpsellViewModel(
            headerModel: LargeTitleViewModel.empty,
            items: [],
            footerModel: nil
        )
        factory.makeUpsellViewControllerReturnValue = UpsellViewController(
            viewModel: viewModel
        )
        router.showUpsell(viewModel: viewModel)
    }
}

// MARK: - Helper Types

private class DummyViewController: UIViewController {}
