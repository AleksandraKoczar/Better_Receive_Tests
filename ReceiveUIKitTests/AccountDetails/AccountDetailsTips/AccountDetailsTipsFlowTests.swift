import AnalyticsKitTestingSupport
import ApiKit
import ApiKitTestingSupport
import NeptuneTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import WiseCore

final class AccountDetailsTipsFlowTests: TWTestCase {
    private var flow: AccountDetailsTipsFlow!
    private var presenterFactory: FakeViewControllerPresenterFactory!
    private var analyticsTracker: StubAnalyticsTracker!
    private var urlOpener: UrlOpenerMock!
    private var articleFactory: HelpCenterArticleFactoryMock!

    override func setUp() {
        super.setUp()
        GOS[APIClientKey.self] = StubApiClient()
        presenterFactory = FakeViewControllerPresenterFactory()
        analyticsTracker = StubAnalyticsTracker()
        urlOpener = UrlOpenerMock()
        articleFactory = HelpCenterArticleFactoryMock()
        flow = AccountDetailsTipsFlow(
            profileId: .init(1234),
            accountDetailsId: .init(6789),
            currencyCode: .canned,
            navigationController: MockNavigationController(),
            articleFactory: articleFactory,
            presenterFactory: presenterFactory,
            analyticsTracker: analyticsTracker,
            urlOpener: urlOpener
        )
    }

    override func tearDown() {
        flow = nil
        presenterFactory = nil
        analyticsTracker = nil
        super.tearDown()
    }

    func test_Start() {
        flow.start()

        XCTAssertTrue(presenterFactory.makePushPresenterCalled)
        XCTAssertTrue(presenterFactory.pushPresenter.presentCalled)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            AccountDetailsTipsFlowAnalytics.eventName(for: .started)
        )
    }

    func test_Terminate() {
        flow.terminate()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            AccountDetailsTipsFlowAnalytics.eventName(for: .finished)
        )
    }

    func test_OpenURL() {
        urlOpener.canOpenURLReturnValue = true

        flow.open(url: Branding.current.url)

        XCTAssertEqual(urlOpener.canOpenURLCallsCount, 1)
        XCTAssertEqual(urlOpener.openCallsCount, 1)
    }
}
