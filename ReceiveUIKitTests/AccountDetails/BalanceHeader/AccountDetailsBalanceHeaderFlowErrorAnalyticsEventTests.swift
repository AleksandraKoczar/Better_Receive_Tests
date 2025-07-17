import AnalyticsKitTestingSupport
import BalanceKit
import BalanceKitTestingSupport
import Combine
import CombineSchedulers
import NeptuneTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKit
import UserKitTestingSupport

final class AccountDetailsBalanceHeaderFlowErrorAnalyticsEventTests: TWTestCase {
    private enum Keys {
        static let type = "Type"
        static let message = "Message"
        static let currency = "Currency"
        static let identifier = "Identifier"
    }

    enum MockError: LocalizedError {
        case dummy

        var errorDescription: String? {
            "Dummy"
        }
    }

    private var flow: AccountDetailsBalanceHeaderFlow!
    private var accountDetailsUseCase: AccountDetailsUseCaseMock!
    private var accountDetailsOrderUseCase: AccountDetailsOrderUseCaseMock!
    private var accountDetailsRequirementsUseCase: AccountDetailsRequirementsUseCaseMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var featureService: StubFeatureService!
    private var mockPublisher: CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>!

    override func setUp() {
        super.setUp()

        let orderAccountDetailsFlowFactory = OrderAccountDetailsFlowFactoryMock()
        orderAccountDetailsFlowFactory.makeFlowReturnValue = MockFlow<OrderAccountDetailsFlowResult>()
        let mockView = ViewControllerMock()
        mockView.makeRootInFakeWindow()
        accountDetailsOrderUseCase = AccountDetailsOrderUseCaseMock()

        accountDetailsRequirementsUseCase = AccountDetailsRequirementsUseCaseMock()
        accountDetailsRequirementsUseCase.requirementsReturnValue = .just([AccountDetailsRequirement.canned])

        let upsellFactory = AccountDetailsFlowUpsellFactoryMock()
        upsellFactory.makeReturnValue = UpsellViewController()
        upsellFactory.upsellSheetModelReturnValue = .canned

        let accountDetailsInfoViewControllerFactoryMock = AccountDetailsInfoViewControllerFactoryMock()
        accountDetailsInfoViewControllerFactoryMock
            .makeInfoViewControllerReturnValue = ViewControllerMock()

        let accountDetailsListFactoryMock = AccountDetailsListFactoryMock()
        let accountDetailsSplitterFactoryMock = AccountDetailsSplitterScreenViewControllerFactoryMock()
        accountDetailsListFactoryMock
            .makeMultiAccountDetailSameCurrencyViewControllerWithAccountDetailsReturnValue = ViewControllerMock()

        let multipleAccountDetailsOrderFlowFactory = MultipleAccountDetailsOrderFlowWithUpsellConfigurationFactoryMock()
        multipleAccountDetailsOrderFlowFactory.makeReturnValue = MockFlow<MultipleAccountDetailsOrderFlowResult>()

        analyticsTracker = StubAnalyticsTracker()
        featureService = StubFeatureService()

        accountDetailsUseCase = AccountDetailsUseCaseMock()
        mockPublisher = CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>(nil)
        accountDetailsUseCase.accountDetails = mockPublisher.eraseToAnyPublisher()

        flow = AccountDetailsBalanceHeaderFlow(
            canShowUpsell: true,
            canOrderMultipleAccountDetails: false,
            currencyCode: .GBP,
            profile: FakePersonalProfileInfo().asProfile(),
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
            navigationController: MockNavigationController(),
            analyticsTracker: analyticsTracker,
            featureService: featureService,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        flow = nil
        accountDetailsUseCase = nil
        accountDetailsOrderUseCase = nil
        accountDetailsRequirementsUseCase = nil
        mockPublisher = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension AccountDetailsBalanceHeaderFlowErrorAnalyticsEventTests {
    func test_fetchingOrders_GivenError_ThenEventNameAndPropertiesMatches() {
        accountDetailsOrderUseCase.ordersClosure = { _, _, completion in
            completion(.failure(UseCaseError.preconditionFailed))
        }

        flow.start()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Account Details Balance Header Flow - Error"
        )

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked as? [String: String],
            [
                Keys.type: "FetchingOrders",
                Keys.identifier: "BalanceKit.UseCaseError - 3",
                Keys.message: "preconditionFailedError",
            ]
        )
    }

    func test_fetchingAccountDetails_GivenError_ThenEventNameAndPropertiesMatches() {
        accountDetailsOrderUseCase.ordersClosure = { _, _, completion in
            completion(.success([AccountDetailsOrder.build()]))
        }

        mockPublisher.send(.recoverableError(MockError.dummy))

        flow.start()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Account Details Balance Header Flow - Error"
        )

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked as? [String: String],
            [
                Keys.type: "FetchingAccountDetails",
                Keys.identifier: "ReceiveUIKitTests.AccountDetailsBalanceHeaderFlowErrorAnalyticsEventTests.MockError - 0",
                Keys.message: "Dummy",
            ]
        )
    }

    func test_NoAccountDetailsForCurrency_GivenNoAccountDetailsForCurrency_ThenEventNameAndPropertiesMatches() {
        accountDetailsOrderUseCase.ordersClosure = { _, _, completion in
            completion(.success([AccountDetailsOrder.build()]))
        }

        mockPublisher.send(.loaded([AccountDetails.active(.build(currency: .cannedUSD))]))

        flow.start()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Account Details Balance Header Flow - Error"
        )

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked as? [String: String],
            [
                Keys.type: "NoAccountDetailsForCurrency",
                Keys.currency: "GBP",
            ]
        )
    }

    func test_fetchingAccountDetailsRequirements_GivenError_ThenEventNameAndPropertiesMatches() {
        accountDetailsOrderUseCase.ordersClosure = { _, _, completion in
            completion(.success([]))
        }

        mockPublisher.send(
            .loaded([
                AccountDetails.available(.build(
                    currency: .cannedGBP
                )),
            ])
        )

        accountDetailsRequirementsUseCase.requirementsReturnValue = .fail(with: .noActiveProfile)

        flow.start()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Account Details Balance Header Flow - Error"
        )

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked as? [String: String],
            [
                Keys.type: "FetchingRequirements",
                Keys.identifier: "BalanceKit.AccountDetailsError - 2",
                Keys.message: "No profile found when getting account details",
            ]
        )
    }
}
