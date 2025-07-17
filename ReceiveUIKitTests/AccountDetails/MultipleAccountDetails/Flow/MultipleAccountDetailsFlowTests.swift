import AnalyticsKitTestingSupport
import BalanceKit
import DeepLinkKitTestingSupport
import Neptune
import NeptuneTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport
import WiseCore
import XCTest

final class MultipleAccountDetailsFlowTests: TWTestCase {
    private var flow: MultipleAccountDetailsFlow!
    private var navigationController: UINavigationController!
    private var userProvider: StubUserProvider!
    private var route: DeepLinkAccountDetailsRouteMock!
    private var loadAccountDetailsStatusFactory: LoadAccountDetailsStatusFactoryMock!
    private var loadAccountDetailsEligibilityFactory: LoadAccountDetailsEligibilityFactoryMock!
    private var multipleAccountDetailsIneligibilityFactory: MultipleAccountDetailsIneligibilityFactoryMock!
    private var multipleAccountDetailsOrderFlowFactory: MultipleAccountDetailsOrderFlowFactoryMock!
    private var profileCreationFlowFactory: MultipleAccountDetailsProfileCreationFlowFactoryMock!
    private var singleAccountDetailsFlowFactory: SingleAccountDetailsFlowFactoryMock!
    private var userOnboardingPreferencesService: UserOnboardingPreferencesServiceStub!
    private var analytics: StubAnalyticsFlowLegacyTracker!
    private let flowHandlerHelper = FlowHandlerHelper<AccountDetailsFlowResult>()
    private var flowDispatcher: TestFlowDispatcher!

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()
        userProvider = StubUserProvider()
        route = DeepLinkAccountDetailsRouteMock()
        userOnboardingPreferencesService = UserOnboardingPreferencesServiceStub()
        userOnboardingPreferencesService.set(
            registrationPreferences: RegistrationPreferences(
                profileType: .business,
                countryCode: .cannedUK
            )
        )
        loadAccountDetailsStatusFactory = {
            let factory = LoadAccountDetailsStatusFactoryMock()
            factory.makeReturnValue = UIViewController()
            return factory
        }()
        loadAccountDetailsEligibilityFactory = {
            let factory = LoadAccountDetailsEligibilityFactoryMock()
            factory.makeReturnValue = UIViewController()
            return factory
        }()
        multipleAccountDetailsIneligibilityFactory = {
            let factory = MultipleAccountDetailsIneligibilityFactoryMock()
            factory.makeViewReturnValue = UIViewController()
            return factory
        }()
        multipleAccountDetailsOrderFlowFactory = {
            let factory = MultipleAccountDetailsOrderFlowFactoryMock()
            factory.makeReturnValue = MockFlow<MultipleAccountDetailsOrderFlowResult>()
            return factory
        }()
        profileCreationFlowFactory = {
            let factory = MultipleAccountDetailsProfileCreationFlowFactoryMock()
            factory.makeReturnValue = MockFlow<MultipleAccountDetailsProfileCreationFlowResult>()
            return factory
        }()
        singleAccountDetailsFlowFactory = {
            let factory = SingleAccountDetailsFlowFactoryMock()
            factory.makeReturnValue = MockFlow<AccountDetailsFlowResult>()
            return factory
        }()
        analytics = StubAnalyticsFlowLegacyTracker()
        flowDispatcher = TestFlowDispatcher()
        flow = makeFlow()
    }

    override func tearDown() {
        flowDispatcher = nil
        analytics = nil
        singleAccountDetailsFlowFactory = nil
        profileCreationFlowFactory = nil
        multipleAccountDetailsOrderFlowFactory = nil
        multipleAccountDetailsIneligibilityFactory = nil
        loadAccountDetailsEligibilityFactory = nil
        loadAccountDetailsStatusFactory = nil
        route = nil
        userProvider = nil
        navigationController = nil
        flow = nil
        userOnboardingPreferencesService = nil
        super.tearDown()
    }

    func testStart_callsFlowStarted() {
        flow.start()
        XCTAssertTrue(flowHandlerHelper.flowStartedCalled)
        XCTAssertTrue(FirstTrackedEvent(
            MultipleAccountDetailsFlowStartedEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testStart_whenPersonalProfileExists_thenShowsSingleAccountDetailsFlow() {
        setupPersonalProfile()
        flow.start()
        XCTAssertTrue(flowDispatcher.lastFlowPresented is any Flow<AccountDetailsFlowResult>)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowSingleDetailsEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testStart_whenBusinessProfileExists_andHasNoBalancePrivilege_thenShowsSingleAccountDetailsFlow() {
        setupBusinessProfile()
        flow.start()
        XCTAssertTrue(flowDispatcher.lastFlowPresented is any Flow<AccountDetailsFlowResult>)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowSingleDetailsEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testStart_whenBusinessProfileExists_andHasBalancePrivilege_thenLoadsAccountDetailsStatus() {
        setupBalancePrivilegedBusinessProfile()
        flow.start()
        XCTAssertTrue(navigationController.viewControllers.last === loadAccountDetailsStatusFactory.makeReturnValue)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowLoadAccountDetailsStatusEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testStart_whenProfileNotExists_thenShowsProfileCreationFlow() {
        userProvider.profiles = []
        flow.start()
        XCTAssertTrue(flowDispatcher.lastFlowPresented is any Flow<MultipleAccountDetailsProfileCreationFlowResult>)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowCreateProfileEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testLoadAccountDetailsStatus_whenDismissed_thenFinishesFlow() throws {
        setupBalancePrivilegedBusinessProfile()
        flow.start()
        flow.route(action: LoadAccountDetailsStatusRouterAction.dismissed)
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .interrupted)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowFinishedEvent(result: .interrupted),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testLoadAccountDetailsStatus_whenAccountDetailsActive_thenShowsSingleAccountDetailsFlow() throws {
        setupBalancePrivilegedBusinessProfile()
        flow.start()
        flow.route(action: .loaded(.init(
            profile: try XCTUnwrap(userProvider.activeProfile),
            status: .active
        )))
        XCTAssertTrue(flowDispatcher.lastFlowPresented is any Flow<AccountDetailsFlowResult>)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowSingleDetailsEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testLoadAccountDetailsStatus_whenAccountDetailsInactive_thenLoadsAccountDetailsEligibility() throws {
        setupBalancePrivilegedBusinessProfile()
        flow.start()
        flow.route(action: .loaded(.init(
            profile: try XCTUnwrap(userProvider.activeProfile),
            status: .inactive
        )))
        XCTAssertTrue(navigationController.viewControllers.last === loadAccountDetailsEligibilityFactory.makeReturnValue)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowLoadEligibilityEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testLoadAccountDetailsEligibility_whenEligibleAndFeePending_thenShowsMultipleAccountDetailsOrderFlow() throws {
        setupBalancePrivilegedBusinessProfile()
        flow.start()
        flow.route(action: .loaded(.eligible(.init(
            profile: try XCTUnwrap(userProvider.activeProfile),
            requirements: [
                .build(
                    type: .fee(.canned, .canned),
                    status: .pendingUser
                ),
            ]
        ))))
        XCTAssertTrue(flowDispatcher.lastFlowPresented is any Flow<MultipleAccountDetailsOrderFlowResult>)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowOrderEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testLoadAccountDetailsEligibility_whenEligibleAndFeeNotRequired_thenShowsMultipleAccountDetailsOrderFlow() throws {
        setupBalancePrivilegedBusinessProfile()
        flow.start()
        flow.route(action: .loaded(.eligible(.init(
            profile: try XCTUnwrap(userProvider.activeProfile),
            requirements: [
                .build(
                    type: .verification,
                    status: .pendingUser
                ),
            ]
        ))))
        XCTAssertTrue(flowDispatcher.lastFlowPresented is any Flow<MultipleAccountDetailsOrderFlowResult>)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowOrderEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testLoadAccountDetailsEligibility_whenEligibleAndFeeInProgress_thenShowsSingleAccountDetailsOrderFlow() throws {
        setupBalancePrivilegedBusinessProfile()
        flow.start()
        flow.route(action: .loaded(.eligible(.init(
            profile: try XCTUnwrap(userProvider.activeProfile),
            requirements: [
                .build(
                    type: .fee(.canned, .canned),
                    status: .pendingTW
                ),
            ]
        ))))
        XCTAssertTrue(flowDispatcher.lastFlowPresented is any Flow<AccountDetailsFlowResult>)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowSingleDetailsEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testLoadAccountDetailsEligibility_whenNotEligible_thenShowsIneligibleView() throws {
        setupBusinessProfile()
        flow.start()
        flow.route(action: .loaded(.ineligible(try XCTUnwrap(userProvider.activeProfile))))
        XCTAssertTrue(navigationController.viewControllers.last === multipleAccountDetailsIneligibilityFactory.makeViewReturnValue)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowIneligibleEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testLoadAccountDetailsEligibility_whenNotEligibleAndProceedSelected_thenFinishesFlow() throws {
        setupBusinessProfile()
        let profile = try XCTUnwrap(userProvider.activeProfile)
        flow.start()
        flow.route(action: MultipleAccountDetailsIneligibilityRouterAction.proceed(profile))
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .completed(profile))
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowFinishedEvent(result: .completed),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testLoadAccountDetailsEligibility_whenDismissed_thenFinishesFlow() throws {
        setupBalancePrivilegedBusinessProfile()
        flow.start()
        flow.route(action: LoadAccountDetailsEligibilityRouterAction.dismissed)
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .interrupted)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowFinishedEvent(result: .interrupted),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowSingleAccountDetailsFlow_whenFlowFinishedSuccessfully_thenCallsFlowHandlerWithCompleted() throws {
        setupPersonalProfile()
        let profile = try XCTUnwrap(userProvider.activeProfile)
        let singleFlow = MockFlow<AccountDetailsFlowResult>()
        singleAccountDetailsFlowFactory.makeClosure = { _, _, _ in
            singleFlow
        }
        flow.start()
        singleFlow.flowHandler.flowFinished(result: .completed(profile), dismisser: nil)
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .completed(profile))
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowFinishedEvent(result: .completed),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowSingleAccountDetailsFlow_whenFlowInterrupted_thenCallsFlowHandlerWithInterrupted() {
        setupPersonalProfile()
        let singleFlow = MockFlow<AccountDetailsFlowResult>()
        singleAccountDetailsFlowFactory.makeClosure = { _, _, _ in
            singleFlow
        }
        flow.start()
        singleFlow.flowHandler.flowFinished(result: .interrupted, dismisser: nil)
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .interrupted)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowFinishedEvent(result: .interrupted),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowMultipleAccountDetailsOrderFlow_whenFlowFinishedSuccessfully_thenCallsFlowHandlerWithCompleted() throws {
        setupBalancePrivilegedBusinessProfile()
        let orderFlow = MockFlow<MultipleAccountDetailsOrderFlowResult>()
        multipleAccountDetailsOrderFlowFactory.makeClosure = { _, _ in
            orderFlow
        }
        flow.start()
        flow.route(action: .loaded(.eligible(.init(
            profile: try XCTUnwrap(userProvider.activeProfile),
            requirements: [
                .build(
                    type: .fee(.canned, .canned),
                    status: .pendingUser
                ),
            ]
        ))))
        orderFlow.flowHandler.flowFinished(result: .success, dismisser: nil)
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .completed(try XCTUnwrap(userProvider.activeProfile)))
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowFinishedEvent(result: .completed),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowMultipleAccountDetailsOrderFlow_whenFlowFinishedWithFailure_thenCallsFlowHandlerWithInterrupted() throws {
        setupBalancePrivilegedBusinessProfile()
        let orderFlow = MockFlow<MultipleAccountDetailsOrderFlowResult>()
        multipleAccountDetailsOrderFlowFactory.makeClosure = { _, _ in
            orderFlow
        }
        flow.start()
        flow.route(action: .loaded(.eligible(.init(
            profile: try XCTUnwrap(userProvider.activeProfile),
            requirements: [
                .build(
                    type: .fee(.canned, .canned),
                    status: .pendingUser
                ),
            ]
        ))))
        orderFlow.flowHandler.flowFinished(result: .failure, dismisser: nil)
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .interrupted)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowFinishedEvent(result: .interrupted),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowMultipleAccountDetailsOrderFlow_whenFlowFinishedWithDismiss_thenCallsFlowHandlerWithInterrupted() throws {
        setupBalancePrivilegedBusinessProfile()
        let orderFlow = MockFlow<MultipleAccountDetailsOrderFlowResult>()
        multipleAccountDetailsOrderFlowFactory.makeClosure = { _, _ in
            orderFlow
        }
        flow.start()
        flow.route(action: .loaded(.eligible(.init(
            profile: try XCTUnwrap(userProvider.activeProfile),
            requirements: [
                .build(
                    type: .fee(.canned, .canned),
                    status: .pendingUser
                ),
            ]
        ))))
        orderFlow.flowHandler.flowFinished(result: .dismissed, dismisser: nil)
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .interrupted)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowFinishedEvent(result: .interrupted),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowCreateProfileFlow_whenCreatedBusinessProfileWithBalancePrivilege_thenLoadsAccountDetailsStatus() {
        userProvider.profiles = []
        let profileFlow = MockFlow<MultipleAccountDetailsProfileCreationFlowResult>()
        profileCreationFlowFactory.makeClosure = { _, _ in
            profileFlow
        }
        flow.start()
        profileFlow.flowHandler.flowFinished(
            result: .completed(
                {
                    let info = FakeBusinessProfileInfo()
                    info.addPrivilege(BalancePrivilege.manage)
                    return info.asProfile()
                }()
            ),
            dismisser: nil
        )
        XCTAssertTrue(navigationController.viewControllers.last === loadAccountDetailsStatusFactory.makeReturnValue)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowLoadAccountDetailsStatusEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowCreateProfileFlow_whenCreatedBusinessProfileWithoutBalancePrivilege_thenShowsSingleAccountDetailsFlow() {
        userProvider.profiles = []
        let profileFlow = MockFlow<MultipleAccountDetailsProfileCreationFlowResult>()
        profileCreationFlowFactory.makeClosure = { _, _ in
            profileFlow
        }
        flow.start()
        profileFlow.flowHandler.flowFinished(
            result: .completed(FakeBusinessProfileInfo().asProfile()),
            dismisser: nil
        )
        XCTAssertTrue(flowDispatcher.lastFlowPresented is any Flow<AccountDetailsFlowResult>)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowSingleDetailsEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowCreateProfileFlow_whenCreatedPersonalProfile_thenShowsSingleAccountDetailsFlow() {
        userProvider.profiles = []
        let profileFlow = MockFlow<MultipleAccountDetailsProfileCreationFlowResult>()
        profileCreationFlowFactory.makeClosure = { _, _ in
            profileFlow
        }
        flow.start()
        profileFlow.flowHandler.flowFinished(
            result: .completed(FakePersonalProfileInfo().asProfile()),
            dismisser: nil
        )
        XCTAssertTrue(flowDispatcher.lastFlowPresented is any Flow<AccountDetailsFlowResult>)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowSingleDetailsEvent(),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowCreateProfileFlow_whenFlowFailes_thenCallsFlowHandlerWithInterrupted() {
        userProvider.profiles = []
        let profileFlow = MockFlow<MultipleAccountDetailsProfileCreationFlowResult>()
        profileCreationFlowFactory.makeClosure = { _, _ in
            profileFlow
        }
        flow.start()
        profileFlow.flowHandler.flowFinished(
            result: .interrupted,
            dismisser: nil
        )
        XCTAssertEqual(flowHandlerHelper.flowFinishedResult, .interrupted)
        XCTAssertTrue(LastTrackedEvent(
            MultipleAccountDetailsFlowFinishedEvent(result: .interrupted),
            in: analytics,
            with: MixpanelEventComparatorAdapter()
        ))
    }

    func testShowAccountDetailsFlow_givenPersonalPreference_thenCorrectFlowCalled() {
        userProvider.profiles = []
        userOnboardingPreferencesService.set(
            registrationPreferences: RegistrationPreferences(
                profileType: .personal,
                countryCode: .cannedUK
            )
        )
        flow.start()
        XCTAssertTrue(singleAccountDetailsFlowFactory.makeCalled)
    }
}

private extension MultipleAccountDetailsFlowTests {
    func makeFlow() -> MultipleAccountDetailsFlow {
        let flow = MultipleAccountDetailsFlow(
            navigationController: navigationController,
            route: route,
            invocationContext: AccountDetailsFlowInvocationContext.accountEducationViewDetails,
            loadAccountDetailsStatusFactory: loadAccountDetailsStatusFactory,
            loadAccountDetailsEligibilityFactory: loadAccountDetailsEligibilityFactory,
            multipleAccountDetailsIneligibilityFactory: multipleAccountDetailsIneligibilityFactory,
            multipleAccountDetailsOrderFlowFactory: multipleAccountDetailsOrderFlowFactory,
            profileCreationFlowFactory: profileCreationFlowFactory,
            singleAccountDetailsFlowFactory: singleAccountDetailsFlowFactory,
            viewControllerPresenterFactory: ViewControllerPresenterFactoryImpl(),
            userOnboardingPreferencesService: userOnboardingPreferencesService,
            flowPresenter: .test(with: flowDispatcher),
            analyticsFlowLegacyTracker: analytics,
            userProvider: userProvider
        )
        flow.flowHandler = flowHandlerHelper.flowHandler
        return flow
    }

    func setupBalancePrivilegedBusinessProfile() {
        userProvider.addBusinessProfile(
            {
                let info = FakeBusinessProfileInfo()
                info.addPrivilege(BalancePrivilege.manage)
                return info
            }(),
            asActive: true
        )
    }

    func setupBusinessProfile() {
        userProvider.addBusinessProfile(
            FakeBusinessProfileInfo(),
            asActive: true
        )
    }

    func setupPersonalProfile() {
        userProvider.addPersonalProfile(
            FakePersonalProfileInfo(),
            asActive: true
        )
    }
}

extension AccountDetailsFlowResult: @retroactive Equatable {
    public static func == (lhs: AccountDetailsFlowResult, rhs: AccountDetailsFlowResult) -> Bool {
        switch (lhs, rhs) {
        case let (.completed(lhsProfile), .completed(rhsProfile)):
            lhsProfile.id.value == rhsProfile.id.value
        case (.interrupted, .interrupted):
            true
        default:
            false
        }
    }
}
