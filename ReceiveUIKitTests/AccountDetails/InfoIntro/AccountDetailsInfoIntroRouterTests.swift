import BalanceKit
import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundationTestingSupport
@preconcurrency import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import UserKit
import UserKitTestingSupport
@preconcurrency import XCTest

final class AccountDetailsInfoIntroRouterTests: TWTestCase {
    private var router: AccountDetailsInfoIntroRouter!
    private var navigationHost: MockNavigationController!
    private var infoViewControllerFactory: AccountDetailsInfoViewControllerFactoryMock!
    private var articleFactory: HelpCenterArticleFactoryMock!
    private var featureService: StubFeatureService!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        navigationHost = MockNavigationController()
        infoViewControllerFactory = AccountDetailsInfoViewControllerFactoryMock()
        articleFactory = HelpCenterArticleFactoryMock()
        featureService = StubFeatureService()
        router = AccountDetailsInfoIntroRouterImpl(
            articleFactory: articleFactory,
            navigationHost: navigationHost,
            infoViewControllerFactory: infoViewControllerFactory,
            receiveSpaceFactoryType: MockReceiveSpaceFactory.self,
            orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactoryMock(),
            salarySwitchFlowFactory: SalarySwitchFlowFactoryMock(),
            featureService: featureService
        )
    }

    @MainActor
    override func tearDown() async throws {
        router = nil
        navigationHost = nil
        infoViewControllerFactory = nil
        featureService = nil

        try await super.tearDown()
    }
}

// MARK: - Tests

extension AccountDetailsInfoIntroRouterTests {
    func testRoutingToAccountDetailsInfo_WhenRouterTriggered_ThenViewControlledShown() {
        featureService.stub(value: false, for: ReceiveKitFeatures.accountDetailsIAEnabled)
        let profile = FakePersonalProfileInfo().asProfile()
        let vc = UIViewController()
        infoViewControllerFactory.makeInfoViewControllerReturnValue = vc

        router.showAccountDetailsInfo(
            profile: profile,
            accountDetails: ActiveAccountDetails.build(id: .build(value: 52))
        )

        XCTAssertEqual(navigationHost.lastShownViewController, vc)
    }

    @MainActor
    func testRoutingToReceiveSpace_WhenRoutingTriggered_ThenViewControllerHasCorrectTag() {
        router.showReceiveMoney()

        XCTAssertEqual(
            navigationHost.lastPushedViewController?.view.tag,
            MockReceiveSpaceFactory.viewTag
        )
    }
}
