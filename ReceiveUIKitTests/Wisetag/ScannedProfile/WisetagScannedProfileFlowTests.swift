import ContactsKit
import ContactsKitTestingSupport
import NeptuneTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import RecipientsKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKit
import UserKitTestingSupport
import WiseCore

final class WisetagScannedProfileFlowTests: TWTestCase {
    private let profile = FakePersonalProfileInfo().asProfile()
    private let nickname = "TaylorSwift"

    private let contact = Contact.build(
        id: Contact.Id.match("123", contactId: "100"),
        title: "title",
        subtitle: "subtitle",
        isVerified: true,
        isHighlighted: false,
        labels: [],
        hasAvatar: true,
        avatarPublisher: .canned,
        lastUsedDate: nil,
        nickname: "TaylorSwift"
    )

    private var webViewControllerFactory: WebViewControllerFactoryMock.Type!
    private var wisetagScannedProfileFlow: WisetagScannedProfileFlow!
    private var navigationController: MockNavigationController!
    private var requestMoneyFlowFactory: RequestMoneyFlowFactoryMock!
    private var transferFlowFactory: WisetagScannedProfileTransferFlowFactoryMock!
    private var viewControllerFactory: WisetagScannedProfileViewControllerFactoryMock!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var wisetagContactInteractor: WisetagContactInteractorMock!
    private var userProvider: StubUserProvider!
    private var presenter: WisetagScannedProfilePresenterMock!

    override func setUp() {
        super.setUp()
        navigationController = MockNavigationController()
        requestMoneyFlowFactory = RequestMoneyFlowFactoryMock()
        transferFlowFactory = WisetagScannedProfileTransferFlowFactoryMock()
        viewControllerFactory = WisetagScannedProfileViewControllerFactoryMock()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        presenter = WisetagScannedProfilePresenterMock()
        wisetagContactInteractor = WisetagContactInteractorMock()
        userProvider = StubUserProvider()
        webViewControllerFactory = WebViewControllerFactoryMock.self
        wisetagScannedProfileFlow = WisetagScannedProfileFlow(
            profile: profile,
            nickname: nickname,
            navigationController: navigationController,
            requestMoneyFlowFactory: requestMoneyFlowFactory,
            transferFlowFactory: transferFlowFactory,
            viewControllerFactory: viewControllerFactory,
            viewControllerPresenterFactory: viewControllerPresenterFactory,
            wisetagContactInteractor: wisetagContactInteractor,
            webViewControllerFactory: webViewControllerFactory,
            userProvider: userProvider,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        wisetagScannedProfileFlow = nil
        navigationController = nil
        requestMoneyFlowFactory = nil
        transferFlowFactory = nil
        viewControllerFactory = nil
        viewControllerPresenterFactory = nil
        wisetagContactInteractor = nil
        super.tearDown()
    }

    func test_start_givenPersonalPageType() {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .personal
        )
        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)

        let viewController = MockViewController()
        viewControllerFactory.makeScannedProfileReturnValue = (viewController, presenter)

        wisetagScannedProfileFlow.start()

        XCTAssertEqual(viewControllerFactory.makeScannedProfileCallsCount, 1)
        let bottomSheetPresenter = viewControllerPresenterFactory.bottomSheetPresenter
        XCTAssertTrue(bottomSheetPresenter.presentCalled)
        XCTAssertTrue(bottomSheetPresenter.presentedViewController === viewController)
        XCTAssertEqual(presenter.setBottomSheetCallsCount, 1)
    }

    func test_start_givenBusinessPageType() {
        let expectedProfileId = ProfileId(128)
        let expectedUserId = UserId(64)
        userProvider.activeProfile = FakeBusinessProfileInfo()
            .with(profileId: expectedProfileId)
            .asProfile()
        userProvider.user = StubUserInfo(userId: expectedUserId)

        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .business
        )

        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = WebContentViewController(url: URL(string: "https://abc.com")!)
        wisetagScannedProfileFlow.start()

        let receiveArguments = webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReceivedArguments
        let expectedURL = URL(string: "https://wise.com/pay/me/\(nickname)")

        XCTAssertEqual(
            receiveArguments?.url,
            expectedURL
        )

        XCTAssertEqual(
            receiveArguments?.userInfoForAuthentication.userId,
            expectedUserId
        )
        XCTAssertEqual(
            receiveArguments?.userInfoForAuthentication.profileId,
            expectedProfileId
        )
        XCTAssertTrue(
            webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationCalled
        )
    }

    func test_start_givenError_thenShowErrorModel() {
        wisetagContactInteractor.lookupContactReturnValue = .fail(with: MockError.dummy)
        wisetagScannedProfileFlow.start()

        XCTAssertEqual(wisetagContactInteractor.lookupContactCallsCount, 1)
        XCTAssertEqual(navigationController.presentInvokedCount, 1)
    }

    func test_dismiss() {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .personal
        )
        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)
        let viewController = MockViewController()
        viewControllerFactory.makeScannedProfileReturnValue = (viewController, presenter)

        wisetagScannedProfileFlow.start()
        wisetagScannedProfileFlow.dismiss()

        let dismisser = viewControllerPresenterFactory.bottomSheetPresenter.dismisser
        XCTAssertTrue(dismisser.dismissCalled)
    }

    func test_startRequestMoneyFlow_givenBalanceRecipient_thenStartTransferFlow() throws {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .personal
        )
        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)
        let viewController = MockViewController()
        viewControllerFactory.makeScannedProfileReturnValue = (viewController, presenter)
        wisetagScannedProfileFlow.start()

        wisetagScannedProfileFlow.sendMoney(.balanceRecipient(.canned), contactId: .canned)

        let dismisser = viewControllerPresenterFactory.bottomSheetPresenter.dismisser
        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(transferFlowFactory.startCallsCount, 1)
        let arguments = try XCTUnwrap(transferFlowFactory.startReceivedArguments)
        XCTAssertTrue(arguments.host === navigationController)
    }

    func test_startSendMoneyFlow_givenRecipient_thenStartTransferFlow() throws {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .personal
        )
        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)
        let viewController = MockViewController()
        viewControllerFactory.makeScannedProfileReturnValue = (viewController, presenter)
        wisetagScannedProfileFlow.start()

        wisetagScannedProfileFlow.sendMoney(.recipient(.canned), contactId: .canned)

        let dismisser = viewControllerPresenterFactory.bottomSheetPresenter.dismisser
        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(transferFlowFactory.startCallsCount, 1)
        let arguments = try XCTUnwrap(transferFlowFactory.startReceivedArguments)
        XCTAssertTrue(arguments.host === navigationController)
    }

    func test_startRequestMoneyFlow() {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .personal
        )
        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)
        let viewController = MockViewController()
        viewControllerFactory.makeScannedProfileReturnValue = (viewController, presenter)
        wisetagScannedProfileFlow.start()

        let requestMoneyFlow = MockFlow<Void>()
        requestMoneyFlowFactory.makeModalFlowForRecentContactReturnValue = requestMoneyFlow

        wisetagScannedProfileFlow.requestMoney(Contact.build(
            id: Contact.Id.match("123", contactId: "123"),
            title: "title",
            subtitle: "subtitle",
            isVerified: true,
            isHighlighted: false,
            labels: [],
            hasAvatar: true,
            avatarPublisher: .canned,
            lastUsedDate: nil,
            nickname: nil
        ))

        let dismisser = viewControllerPresenterFactory.bottomSheetPresenter.dismisser

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(requestMoneyFlowFactory.makeModalFlowForRecentContactCallsCount, 1)
    }
}
