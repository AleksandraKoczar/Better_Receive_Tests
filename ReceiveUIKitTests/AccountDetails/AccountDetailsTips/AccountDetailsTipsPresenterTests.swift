import AnalyticsKitTestingSupport
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import WiseCore

final class AccountDetailsTipsPresenterTests: TWTestCase {
    private let articleId = "1234"
    private let href = "/article/1234"
    private let profileId = ProfileId(123)
    private let accountDetailsId = AccountDetailsId(789)

    private var presenter: AccountDetailsTipsPresenterImpl!
    private var accountDetailsTipsUseCase: AccountDetailsTipsUseCaseMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var router: AccountDetailsTipsRouterMock!
    private var view: AccountDetailsTipsViewMock!

    override func setUp() {
        super.setUp()
        accountDetailsTipsUseCase = AccountDetailsTipsUseCaseMock()
        analyticsTracker = StubAnalyticsTracker()
        router = AccountDetailsTipsRouterMock()
        view = AccountDetailsTipsViewMock()
        presenter = AccountDetailsTipsPresenterImpl(
            profileId: profileId,
            accountDetailsId: accountDetailsId,
            flowTracker: .init(
                contextIdentity: .cannedContext,
                analyticsTracker: analyticsTracker
            ),
            router: router,
            accountDetailsTipsUseCase: accountDetailsTipsUseCase
        )
    }

    override func tearDown() {
        presenter = nil
        accountDetailsTipsUseCase = nil
        view = nil
        super.tearDown()
    }

    @MainActor
    func test_Start_Success() async throws {
        let accountDetailsTips = AccountDetailsTips.build(
            title: LoremIpsum.short,
            alert: .build(
                message: LoremIpsum.medium,
                type: .warning
            ),
            summaries: [
                .build(
                    title: LoremIpsum.short,
                    icon: .money,
                    description: LoremIpsum.long
                ),
            ],
            help: .build(
                articleId: articleId,
                label: LoremIpsum.short,
                href: href
            ),
            ctaLabel: LoremIpsum.short
        )
        accountDetailsTipsUseCase.accountDetailsTipsReturnValue = accountDetailsTips

        await presenter.start(with: view)

        let expectedViewModel = UpsellViewModel(
            headerModel: .init(title: LoremIpsum.short),
            leadingView: StackInlineAlertView(viewModel: .init(message: LoremIpsum.medium)),
            items: [
                .init(
                    title: LoremIpsum.short,
                    description: LoremIpsum.long,
                    icon: Icons.money.image
                ),
            ],
            linkAction: .init(title: LoremIpsum.short),
            footerModel: .init(primaryAction: .init(title: LoremIpsum.short, handler: {}))
        )

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(view.configureCallsCount, 1)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        XCTAssertEqual(viewModel.headerModel, expectedViewModel.headerModel)
        XCTAssertTrue(viewModel.leadingView is StackInlineAlertView)
        XCTAssertEqual(viewModel.items, expectedViewModel.items)
        XCTAssertEqual(viewModel.linkAction, expectedViewModel.linkAction)

        let action = AccountDetailsTipsFlowAnalytics.Opened()
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            action.eventName
        )
    }

    @MainActor
    func test_Start_Failure() async throws {
        let error = MockError.dummy
        accountDetailsTipsUseCase.accountDetailsTipsThrowableError = error

        await presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(view.showErrorAlertCallsCount, 1)
    }

    @MainActor
    func test_CloseButtonTapped() {
        presenter.closeButtonTapped()

        XCTAssertEqual(router.dismissCallsCount, 1)
    }

    @MainActor
    func test_HelpLinkTapped() async throws {
        let accountDetailsTips = AccountDetailsTips.build(
            help: .build(href: href)
        )
        accountDetailsTipsUseCase.accountDetailsTipsReturnValue = accountDetailsTips

        await presenter.start(with: view)

        let helpLinkAction = try XCTUnwrap(view.configureReceivedViewModel?.linkAction)
        helpLinkAction.trigger()

        XCTAssertEqual(router.openCallsCount, 1)
        XCTAssertEqual(
            router.openReceivedUrl,
            Branding.current.url.appendingPathComponent(href)
        )

        let action = AccountDetailsTipsFlowAnalytics.HelpLinkClicked()
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            action.eventName
        )
    }
}
