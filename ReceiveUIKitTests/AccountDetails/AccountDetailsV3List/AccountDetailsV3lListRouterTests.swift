import Foundation
import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

final class AccountDetailsV3lListRouterTests: TWTestCase {
    private let profile = FakeBusinessProfileInfo().asProfile()
    private var router: AccountDetailsV3ListRouterImpl!
    private var host: MockNavigationController!
    private var accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactoryMock!
    private var featureService: StubFeatureService!
    private var accountDetailsSplitterViewControllerFactory: AccountDetailsSplitterScreenViewControllerFactoryMock!
    private var accountDetailsInfoViewControllerFactory: AccountDetailsInfoViewControllerFactoryMock!

    override func setUp() {
        super.setUp()

        host = MockNavigationController()
        featureService = StubFeatureService()
        accountDetailsSplitterViewControllerFactory = AccountDetailsSplitterScreenViewControllerFactoryMock()
        accountDetailsInfoViewControllerFactory = AccountDetailsInfoViewControllerFactoryMock()
        accountDetailsCreationFlowFactory = ReceiveAccountDetailsCreationFlowFactoryMock()

        router = AccountDetailsV3ListRouterImpl(
            navigationHost: host,
            source: .accountDetailsList,
            accountDetailsInfoFactory: accountDetailsInfoViewControllerFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            accountDetailsSplitterViewControllerFactory: accountDetailsSplitterViewControllerFactory,
            profile: profile
        )

        trackForMemoryLeak(instance: router) { [weak self] in
            self?.router = nil
        }
    }

    override func tearDown() {
        router = nil
        host = nil
        accountDetailsCreationFlowFactory = nil
        accountDetailsSplitterViewControllerFactory = nil
        accountDetailsInfoViewControllerFactory = nil
        featureService = nil

        super.tearDown()
    }

    func test_handleAction_givenActionIsView() {
        accountDetailsInfoViewControllerFactory.makeAccountDetailsV3ViewControllerReturnValue = UIViewControllerMock()

        let accountDetailsId = AccountDetailsId(1)
        router.handleReceiveMethodAction(action: .view(id: accountDetailsId, methodType: .accountDetails))

        XCTAssertTrue(accountDetailsInfoViewControllerFactory.makeAccountDetailsV3ViewControllerCalled)
        XCTAssertEqual(
            accountDetailsInfoViewControllerFactory.makeAccountDetailsV3ViewControllerReceivedArguments?.accountDetailsId,
            accountDetailsId
        )
        XCTAssertEqual(
            accountDetailsInfoViewControllerFactory.makeAccountDetailsV3ViewControllerReceivedArguments?.invocationSource,
            .accountDetailsList
        )
    }

    func test_handleAction_givenActionIsQuery() {
        let currency = CurrencyCode("PLN")

        accountDetailsSplitterViewControllerFactory.makeReturnValue = UIViewControllerMock()
        router.handleReceiveMethodAction(action: .query(
            context: .list,
            currency: currency,
            groupId: nil,
            balanceId: nil,
            methodTypes: [.accountDetails]
        ))

        XCTAssertTrue(accountDetailsSplitterViewControllerFactory.makeCalled)
        XCTAssertEqual(
            accountDetailsSplitterViewControllerFactory.makeReceivedArguments?.currency,
            currency
        )
        XCTAssertEqual(
            accountDetailsSplitterViewControllerFactory.makeReceivedArguments?.host,
            host
        )
    }

    func test_handleAction_givenActionIsOrder() {
        let currency = CurrencyCode("PLN")
        let mockFlow = MockFlow<ReceiveAccountDetailsCreationFlowResult>()
        accountDetailsCreationFlowFactory.makeForReceiveReturnValue = mockFlow

        router.handleReceiveMethodAction(action: .order(currency: currency, balanceId: nil, methodType: .accountDetails))

        XCTAssertEqual(accountDetailsCreationFlowFactory.makeForReceiveCallsCount, 1)
        XCTAssertEqual(accountDetailsCreationFlowFactory.makeForReceiveReceivedArguments?.currencyCode, currency)
        XCTAssertTrue(mockFlow.startCalled)
    }
}
