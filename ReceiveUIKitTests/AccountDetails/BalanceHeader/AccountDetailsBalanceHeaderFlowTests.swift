import AnalyticsKitTestingSupport
import BalanceKit
import BalanceKitTestingSupport
import Combine
import CombineSchedulers
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
import WiseCore
import XCTest

final class AccountDetailsBalanceHeaderFlowTests: TWTestCase {
    private enum Constants {
        static let waitTime: TimeInterval = 0.8

        enum Tags {
            static let upsell = 256
            static let info = 512
            static let multiAccountDetails = 1024
        }
    }

    private var flow: AccountDetailsBalanceHeaderFlow!
    private var orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactoryMock!
    private var mockView: ViewControllerMock!
    private var accountDetailsUseCase: AccountDetailsUseCaseMock!
    private var accountDetailsOrderUseCase: AccountDetailsOrderUseCaseMock!
    private var accountDetailsRequirementsUseCase: AccountDetailsRequirementsUseCaseMock!
    private var upsellFactory: AccountDetailsFlowUpsellFactoryMock!
    private var accountDetailsInfoViewControllerFactoryMock: AccountDetailsInfoViewControllerFactoryMock!
    private var accountDetailsListFactoryMock: AccountDetailsListFactoryMock!
    private var accountDetailsSplitterFactoryMock: AccountDetailsSplitterScreenViewControllerFactoryMock!
    private var multipleAccountDetailsOrderFlowFactory: MultipleAccountDetailsOrderFlowWithUpsellConfigurationFactoryMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var navigationController: MockNavigationController!
    private var featureService: StubFeatureService!
    private var mockPublisher: CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>!

    override func setUp() {
        super.setUp()

        orderAccountDetailsFlowFactory = OrderAccountDetailsFlowFactoryMock()
        orderAccountDetailsFlowFactory.makeFlowReturnValue = MockFlow<OrderAccountDetailsFlowResult>()
        mockView = ViewControllerMock()
        mockView.makeRootInFakeWindow()
        accountDetailsOrderUseCase = AccountDetailsOrderUseCaseMock()
        accountDetailsSplitterFactoryMock = AccountDetailsSplitterScreenViewControllerFactoryMock()

        accountDetailsRequirementsUseCase = AccountDetailsRequirementsUseCaseMock()
        accountDetailsRequirementsUseCase.requirementsReturnValue = .just([AccountDetailsRequirement.canned])

        upsellFactory = AccountDetailsFlowUpsellFactoryMock()
        upsellFactory.makeReturnValue = UpsellViewController().with {
            $0.view.tag = Constants.Tags.upsell
        }
        upsellFactory.upsellSheetModelReturnValue = InfoSheetViewModel.canned

        accountDetailsInfoViewControllerFactoryMock = AccountDetailsInfoViewControllerFactoryMock()
        accountDetailsInfoViewControllerFactoryMock
            .makeInfoViewControllerReturnValue = ViewControllerMock().with {
                $0.view.tag = Constants.Tags.info
            }

        accountDetailsListFactoryMock = AccountDetailsListFactoryMock()
        accountDetailsListFactoryMock
            .makeMultiAccountDetailSameCurrencyViewControllerWithAccountDetailsReturnValue = ViewControllerMock().with {
                $0.view.tag = Constants.Tags.multiAccountDetails
            }

        multipleAccountDetailsOrderFlowFactory = MultipleAccountDetailsOrderFlowWithUpsellConfigurationFactoryMock()
        multipleAccountDetailsOrderFlowFactory.makeReturnValue = MockFlow<MultipleAccountDetailsOrderFlowResult>()

        analyticsTracker = StubAnalyticsTracker()
        featureService = StubFeatureService()

        accountDetailsUseCase = AccountDetailsUseCaseMock()
        mockPublisher = CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>(nil)
        accountDetailsUseCase.accountDetails = mockPublisher.eraseToAnyPublisher()
        navigationController = MockNavigationController()

        flow = makeFlow()
    }

    override func tearDown() {
        flow = nil
        mockView = nil
        accountDetailsUseCase = nil
        accountDetailsOrderUseCase = nil
        accountDetailsRequirementsUseCase = nil
        orderAccountDetailsFlowFactory = nil
        upsellFactory = nil
        accountDetailsInfoViewControllerFactoryMock = nil
        analyticsTracker = nil
        accountDetailsListFactoryMock = nil
        multipleAccountDetailsOrderFlowFactory = nil
        mockPublisher = nil
        navigationController = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension AccountDetailsBalanceHeaderFlowTests {
    func testFlowTerminate_WhenFlowTerminated_ThenHostDismissed() {
        flow.start()
        XCTAssertFalse(mockView.didDismissController)
        flow.terminate()
        XCTAssertTrue(mockView.didDismissController)
    }

    func testPresentingNavigationController_WhenRoutingStarted() {
        XCTAssertFalse(mockView.didPresentController)
        XCTAssertFalse((mockView.viewControllerPresented as? MockNavigationController)?.didShowHud ?? false)

        flow.start()

        XCTAssertTrue(mockView.didPresentController)
        XCTAssertTrue(presentedNavigationController.didShowHud)
    }

    func test_loadPrerequisiteSuccess_GivenAccountDetails_WhenRoutingStarted_ThenInfoViewControllerDisplayed() {
        featureService.stub(value: false, for: ReceiveKitFeatures.accountDetailsIAEnabled)
        prepareData(accountDetails: [.active(.build(currency: .GBP))])
        XCTAssertFalse(accountDetailsInfoViewControllerFactoryMock.makeInfoViewControllerCalled)

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertTrue(accountDetailsInfoViewControllerFactoryMock.makeInfoViewControllerCalled)
        XCTAssertEqual(lastSetViewControllerTag, Constants.Tags.info)
    }

    func testLoadPrerequisite_GivenOrdersError_WhenRoutingStarted_ThenInfoViewControllerDisplayed() {
        featureService.stub(value: false, for: ReceiveKitFeatures.accountDetailsIAEnabled)

        prepareData(
            accountDetails: [.active(.build(currency: .GBP))],
            orderResult: .failure(UseCaseError.noActiveProfile)
        )

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        // Can continue without the orders
        XCTAssertTrue(accountDetailsInfoViewControllerFactoryMock.makeInfoViewControllerCalled)
        XCTAssertEqual(lastSetViewControllerTag, Constants.Tags.info)
    }

    func testLoadPrerequisite_GivenOrdersErrorAndNoAcountDetails_WhenRoutingStarted_ThenUpsellDisplayed() {
        prepareData(
            accountDetails: [.available(.build(currency: .GBP))],
            orderResult: .failure(UseCaseError.noActiveProfile)
        )

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        // Can continue without the orders
        XCTAssertTrue(upsellFactory.makeCalled)
        XCTAssertEqual(
            lastSetViewControllerTag,
            Constants.Tags.upsell
        )
    }

    func testLoadPrerequisite_GivenAccountDetailsError_WhenRoutingStarted_ThenAlertControllerPresented() {
        mockPublisher.send(.recoverableError(UseCaseError.preconditionFailed))
        accountDetailsOrderUseCase.ordersClosure = { _, _, completion in
            completion(.success([.build()]))
        }

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertTrue(navigationController.lastPresentedViewController is UIAlertController)
    }

    func testLoadPrerequisite_GivenAccountDetailsError_WhenAlertDismissedThenAlertControllerButtonTapped_ThenNavigationControllerDismissed() throws {
        mockPublisher.send(.recoverableError(UseCaseError.preconditionFailed))
        accountDetailsOrderUseCase.ordersClosure = { _, _, completion in
            completion(.success([.build()]))
        }

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        let alertController = try XCTUnwrap(navigationController.lastPresentedViewController as? UIAlertController)
        XCTAssertEqual(navigationController.dismissInvokedCount, 0)
        alertController.tapButton(atIndex: 0)
        XCTAssertEqual(navigationController.dismissInvokedCount, 1)
    }

    func testShowMultipleActiveAccountDetails_GivenMultipleActiveAccountDetails_ThenMultiAccountDetailSameCurrencyViewControllerDisplayed() {
        prepareData(accountDetails: [
            .active(.build(currency: .GBP)),
            .active(.build(currency: .GBP)),
            .active(.build(currency: .GBP)),
        ])

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertTrue(
            analyticsTracker.lastItemTracked.debugDescription.contains("BalanceAccountDetailsEvent")
        )
        XCTAssertTrue(accountDetailsListFactoryMock.makeMultiAccountDetailSameCurrencyViewControllerWithAccountDetailsCalled)
        XCTAssertEqual(lastSetViewControllerTag, Constants.Tags.multiAccountDetails)
    }

    func testShowSingleActiveAccountDetails_GivenActiveAccountDetails_ThenInfoViewControllerDisplayed() {
        featureService.stub(value: false, for: ReceiveKitFeatures.accountDetailsIAEnabled)
        prepareData(accountDetails: [
            .active(.build(currency: .AUD)),
            .active(.build(currency: .GBP)),
            .active(.build(currency: .NZD)),
        ])

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertTrue(
            analyticsTracker.lastItemTracked.debugDescription.contains("BalanceAccountDetailsEvent")
        )
        XCTAssertTrue(accountDetailsInfoViewControllerFactoryMock.makeInfoViewControllerCalled)
        XCTAssertEqual(lastSetViewControllerTag, Constants.Tags.info)
    }

    func testShowAvailableAccountDetails_GivenPendingFeeRequirement_AndCanOrderMultipleAccountDetails_ThenMakeMultipleAccountDetailsOrderFlowCalled() {
        flow = makeFlow(canOrderMultipleAccountDetails: true)
        preparePendingFeeData()

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertTrue(multipleAccountDetailsOrderFlowFactory.makeCalled)
        XCTAssertFalse(upsellFactory.makeCalled)
        XCTAssertFalse(orderAccountDetailsFlowFactory.makeFlowCalled)
    }

    func testShowAvailableAccountDetails_GivenNoFeeRequirement_AndCanOrderMultipleAccountDetails_ThenMakeMultipleAccountDetailsOrderFlowCalled() {
        flow = makeFlow(canOrderMultipleAccountDetails: true)
        prepareVerificationPendingData()

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertTrue(multipleAccountDetailsOrderFlowFactory.makeCalled)
        XCTAssertFalse(upsellFactory.makeCalled)
        XCTAssertFalse(orderAccountDetailsFlowFactory.makeFlowCalled)
    }

    func testShowAvailableAccountDetails_GivenOrderMultipleAccountDetailsDisabled_ThenMakeOrderAccountDetailsFlowCalled() {
        flow = makeFlow(canShowUpsell: false, canOrderMultipleAccountDetails: false)
        preparePendingFeeData()

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertFalse(multipleAccountDetailsOrderFlowFactory.makeCalled)
        XCTAssertFalse(upsellFactory.makeCalled)
        XCTAssertTrue(orderAccountDetailsFlowFactory.makeFlowCalled)
    }

    func testShowAvailableAccountDetails_GivenOrderInProgress_ThenMakeOrderAccountDetailsFlowCalled() {
        prepareData(
            accountDetails: [
                .available(.build(currency: .GBP)),
                .available(.build(currency: .NZD)),
                .available(.build(currency: .AUD)),
            ],
            orderResult: .success([
                .build(status: .pendingTW),
            ])
        )

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertFalse(multipleAccountDetailsOrderFlowFactory.makeCalled)
        XCTAssertFalse(upsellFactory.makeCalled)
        XCTAssertTrue(orderAccountDetailsFlowFactory.makeFlowCalled)
    }

    func testShowAvailableAccountDetails_GivenNoOrdersInProgress_ThenMakeUpsellCalled() {
        preparePendingUserData()

        flow.start()
        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertFalse(multipleAccountDetailsOrderFlowFactory.makeCalled)
        XCTAssertTrue(upsellFactory.makeCalled)
        XCTAssertTrue(mockView.viewControllerPresented?.children.first === upsellFactory.makeReturnValue)
        XCTAssertTrue(analyticsTracker.lastItemTracked is AccountDetailsUpsellPersonalAnalyticsScreen)
        XCTAssertFalse(orderAccountDetailsFlowFactory.makeFlowCalled)
    }

    func testShowAvailableAccountDetails_GivenUpsellDisabled_ThenMakeOrderAccountDetailsFlowCalled() {
        flow = makeFlow(canShowUpsell: false)
        preparePendingUserData()

        flow.start()
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        XCTAssertFalse(multipleAccountDetailsOrderFlowFactory.makeCalled)
        XCTAssertFalse(upsellFactory.makeCalled)
        XCTAssertTrue(orderAccountDetailsFlowFactory.makeFlowCalled)
    }

    func testShowMultipleAccountDetailsOrderFlow_GivenFlowFinishedSuccessfuly_ThenCallsFlowHandlerWithSuccess() {
        let flowHandlerHelper = FlowHandlerHelper<AccountDetailsBalanceHeaderFlowResult>()
        let mockFlow = MockFlow<MultipleAccountDetailsOrderFlowResult>()
        multipleAccountDetailsOrderFlowFactory.makeClosure = { _, _, _ in mockFlow }
        flow = makeFlow(canOrderMultipleAccountDetails: true)
        preparePendingFeeData()
        flow.start()
        flow.flowHandler = flowHandlerHelper.flowHandler

        mockFlow.flowHandler.flowFinished(result: .success, dismisser: nil)

        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .success)
    }

    func testShowMultipleAccountDetailsOrderFlow_GivenFlowFinishedUnsuccessfuly_ThenCallsFlowHandlerWithAborted() {
        let flowHandlerHelper = FlowHandlerHelper<AccountDetailsBalanceHeaderFlowResult>()
        let mockFlow = MockFlow<MultipleAccountDetailsOrderFlowResult>()
        multipleAccountDetailsOrderFlowFactory.makeClosure = { _, _, _ in mockFlow }
        flow = makeFlow(canOrderMultipleAccountDetails: true)
        preparePendingFeeData()
        flow.start()
        flow.flowHandler = flowHandlerHelper.flowHandler

        mockFlow.flowHandler.flowFinished(result: .failure, dismisser: nil)

        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .abortedWithError)
    }

    func testShowMultipleAccountDetailsOrderFlow_GivenFlowDismissed_ThenCallsFlowHandlerWithDismissed() {
        let flowHandlerHelper = FlowHandlerHelper<AccountDetailsBalanceHeaderFlowResult>()
        let mockFlow = MockFlow<MultipleAccountDetailsOrderFlowResult>()
        multipleAccountDetailsOrderFlowFactory.makeClosure = { _, _, _ in mockFlow }
        flow = makeFlow(canOrderMultipleAccountDetails: true)
        preparePendingFeeData()
        flow.start()
        flow.flowHandler = flowHandlerHelper.flowHandler

        mockFlow.flowHandler.flowFinished(result: .dismissed, dismisser: nil)

        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .dismissed)
    }

    func testShowMultipleAccountDetailsOrderFlow_GivenFlowFinished_ThenNavigationControllerDismissed() {
        let mockFlow = MockFlow<MultipleAccountDetailsOrderFlowResult>()
        multipleAccountDetailsOrderFlowFactory.makeClosure = { _, _, _ in mockFlow }
        flow = makeFlow(canOrderMultipleAccountDetails: true)
        preparePendingFeeData()
        flow.start()

        mockFlow.flowHandler.flowFinished(result: .success, dismisser: nil)

        XCTAssertEqual(navigationController.dismissInvokedCount, 1)
    }

    func testHidingHud_GivenNoAccountDetailsForCurrency_ThenHudHidden() {
        prepareData(accountDetails: [.active(.build(currency: .AUD))])
        flow.start()

        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()
        XCTAssertTrue(presentedNavigationController.didHideHud)
    }

    func testHidingHud_GiveRequirementsErrorAndEmptyOrders_ThenHudHidden() {
        prepareData(
            accountDetails: [
                .available(.build(currency: .GBP)),
            ],
            orderResult: .success([])
        )
        accountDetailsRequirementsUseCase.requirementsReturnValue = .fail(with: .noActiveProfile)
        flow.start()
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()
        XCTAssertTrue(presentedNavigationController.didHideHud)
    }

    func testBRLUpsell_GivenBrazillianCustomerAndBRL_ThenPixUpsellDisplayed() {
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.address = .build(countryIso3Code: Country.Iso3Code("brA"))
        upsellFactory.upsellForPixReturnValue = UpsellViewController().with {
            $0.view.tag = Constants.Tags.upsell + 1
        }
        prepareData(
            accountDetails: [.available(.build(currency: .BRL))],
            orderResult: .failure(UseCaseError.noActiveProfile)
        )

        flow = makeFlow(
            currencyCode: .BRL,
            profile: profileInfo.asProfile()
        )
        flow.start()

        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        // Can continue without the orders
        XCTAssertTrue(upsellFactory.upsellForPixCalled)
        XCTAssertEqual(
            lastSetViewControllerTag,
            Constants.Tags.upsell + 1
        )
    }

    func testBRLUpsell_GivenBrazillianCustomerAndGBP_ThenPixUpsellNotDisplayed() {
        let profileInfo = FakePersonalProfileInfo()
        profileInfo.address = .build(countryIso3Code: Country.Iso3Code("brA"))
        upsellFactory.upsellForPixReturnValue = UpsellViewController().with {
            $0.view.tag = Constants.Tags.upsell + 1
        }
        prepareData(
            accountDetails: [.available(.build(currency: .BRL))],
            orderResult: .failure(UseCaseError.noActiveProfile)
        )

        flow = makeFlow(
            currencyCode: .GBP,
            profile: profileInfo.asProfile()
        )
        flow.start()

        XCTAssertTrue(presentedNavigationController.didShowHud)
        waitLoading()

        XCTAssertTrue(presentedNavigationController.didHideHud)
        // Can continue without the orders
        XCTAssertFalse(upsellFactory.upsellForPixCalled)
        XCTAssertNotEqual(
            lastSetViewControllerTag,
            Constants.Tags.upsell + 1
        )
    }
}

// MARK: - Helpers

private extension AccountDetailsBalanceHeaderFlowTests {
    var presentedNavigationController: MockNavigationController {
        mockView.viewControllerPresented as! MockNavigationController
    }

    var lastSetViewControllerTag: Int? {
        navigationController.lastSetViewControllers?.first?.view.tag
    }

    func prepareData(
        accountDetails: [AccountDetails],
        orderResult: Result<[AccountDetailsOrder], UseCaseError> = .success([AccountDetailsOrder.build()])
    ) {
        mockPublisher.send(.loaded(accountDetails))

        accountDetailsOrderUseCase.ordersClosure = { _, _, completion in
            completion(orderResult)
        }
    }

    func preparePendingUserData() {
        prepareData(
            accountDetails: [
                .available(.build(currency: .GBP)),
                .available(.build(currency: .NZD)),
                .available(.build(currency: .AUD)),
            ],
            orderResult: .success([
                .build(status: .pendingUser),
            ])
        )
    }

    func preparePendingFeeData() {
        prepareData(
            accountDetails: [
                .available(.build(currency: .GBP)),
                .available(.build(currency: .NZD)),
                .available(.build(currency: .AUD)),
            ],
            orderResult: .success([
                .build(
                    status: .pendingUser,
                    requirements: [
                        .build(type: .fee(.canned, .canned), status: .pendingUser),
                        .build(type: .verification, status: .pendingUser),
                    ]
                ),
            ])
        )
    }

    func prepareVerificationPendingData() {
        prepareData(
            accountDetails: [
                .available(.build(currency: .GBP)),
                .available(.build(currency: .NZD)),
                .available(.build(currency: .AUD)),
            ],
            orderResult: .success([
                .build(
                    status: .pendingUser,
                    requirements: [
                        .build(type: .verification, status: .pendingUser),
                    ]
                ),
            ])
        )
    }

    func waitLoading() {
        wait(delay: Constants.waitTime)
    }

    func makeFlow(
        canShowUpsell: Bool = true,
        canOrderMultipleAccountDetails: Bool = false,
        currencyCode: CurrencyCode = .GBP,
        profile: Profile = FakePersonalProfileInfo().asProfile()
    ) -> AccountDetailsBalanceHeaderFlow {
        AccountDetailsBalanceHeaderFlow(
            canShowUpsell: canShowUpsell,
            canOrderMultipleAccountDetails: canOrderMultipleAccountDetails,
            currencyCode: currencyCode,
            profile: profile,
            host: mockView,
            accountDetailsUseCase: accountDetailsUseCase,
            accountDetailsOrderUseCase: accountDetailsOrderUseCase,
            accountDetailsRequirementsUseCase: accountDetailsRequirementsUseCase,
            upsellFactory: upsellFactory,
            accountDetailsInfoFactory: accountDetailsInfoViewControllerFactoryMock,
            accountDetailsListFactory: accountDetailsListFactoryMock,
            accountDetailsSplitterScreenFactory: accountDetailsSplitterFactoryMock,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            multipleAccountDetailsOrderFlowFactory: multipleAccountDetailsOrderFlowFactory,
            navigationController: navigationController,
            analyticsTracker: analyticsTracker,
            featureService: featureService,
            scheduler: .immediate
        )
    }
}
