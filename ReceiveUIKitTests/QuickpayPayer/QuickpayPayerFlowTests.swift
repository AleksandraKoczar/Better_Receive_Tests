import ContactsKit
import ContactsKitTestingSupport
import NeptuneTestingSupport
import Prism
import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TravelHubKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

final class QuicpayPayerFlowTests: TWTestCase {
    private var flow: QuickpayPayerFlow!

    private let profile = FakeBusinessProfileInfo().asProfile()
    private let quickpayLink = "TaylorSwift"
    private let amount = "10"
    private let currency = CurrencyCode("PLN")

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
        nickname: "nickname"
    )

    private var navigationController: MockNavigationController!
    private var viewControllerFactory: QuickpayPayerViewControllerFactoryMock!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!
    private var payWithWiseFlowFactory: PayWithWiseFlowFactoryMock!
    private var wisetagContactInteractor: WisetagContactInteractorMock!
    private var userProvider: StubUserProvider!
    private var urlOpener: UrlOpenerMock!
    private var analyticsTracker: QuickpayTrackingMock!

    override func setUp() {
        super.setUp()

        navigationController = MockNavigationController()
        viewControllerFactory = QuickpayPayerViewControllerFactoryMock()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        wisetagContactInteractor = WisetagContactInteractorMock()
        userProvider = StubUserProvider()
        payWithWiseFlowFactory = PayWithWiseFlowFactoryMock()
        urlOpener = UrlOpenerMock()
        analyticsTracker = QuickpayTrackingMock()

        flow = QuickpayPayerFlow(
            profile: profile,
            nickname: quickpayLink,
            amount: amount,
            currency: currency,
            description: "test",
            navigationController: navigationController,
            viewControllerFactory: viewControllerFactory,
            viewControllerPresenterFactory: viewControllerPresenterFactory,
            wisetagContactInteractor: wisetagContactInteractor,
            payWithWiseFlowFactory: payWithWiseFlowFactory,
            userProvider: userProvider,
            analyticsTracker: analyticsTracker,
            urlOpener: urlOpener,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        navigationController = nil
        viewControllerFactory = nil
        viewControllerPresenterFactory = nil
        wisetagContactInteractor = nil
        payWithWiseFlowFactory = nil
        urlOpener = nil

        super.tearDown()
    }

    func test_startGivenBusinessProfile_thenOpenBottomsheetWithPayerData() {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .business
        )
        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)

        let viewController = MockViewController()
        viewControllerFactory.makePayerBottomsheetReturnValue = viewController

        let pwwFlow = MockFlow<Void>()
        payWithWiseFlowFactory.makeModalFlowWithAcquiringPaymentKeyReturnValue = pwwFlow

        flow.start()

        XCTAssertEqual(wisetagContactInteractor.lookupContactCallsCount, 1)
        XCTAssertEqual(viewControllerFactory.makePayerBottomsheetCallsCount, 1)
        let bottomSheetPresenter = viewControllerPresenterFactory.bottomSheetPresenter
        XCTAssertTrue(bottomSheetPresenter.presentCalled)
        XCTAssertTrue(bottomSheetPresenter.presentedViewController === viewController)
        XCTAssertEqual(analyticsTracker.onLoadedCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onLoadedReceivedArguments?.isMatchFound, true)
    }

    func test_startGivenPersonalProfile_thenShowError() {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .personal
        )
        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)

        let pwwFlow = MockFlow<Void>()
        payWithWiseFlowFactory.makeModalFlowWithAcquiringPaymentKeyReturnValue = pwwFlow

        flow.start()

        XCTAssertEqual(wisetagContactInteractor.lookupContactCallsCount, 1)
        XCTAssertEqual(navigationController.presentInvokedCount, 1)

        XCTAssertEqual(analyticsTracker.onLoadedCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onLoadedReceivedArguments?.isMatchFound, false)
    }

    func test_startGivenError_thenShowError() {
        wisetagContactInteractor.lookupContactReturnValue = .fail(with: MockError.dummy)

        let pwwFlow = MockFlow<Void>()
        payWithWiseFlowFactory.makeModalFlowWithAcquiringPaymentKeyReturnValue = pwwFlow

        flow.start()
        XCTAssertEqual(wisetagContactInteractor.lookupContactCallsCount, 1)
        XCTAssertEqual(navigationController.presentInvokedCount, 1)

        XCTAssertEqual(analyticsTracker.onLoadedCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onLoadedReceivedArguments?.isMatchFound, false)
    }

    func test_dismiss() {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .business
        )
        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)
        let viewController = MockViewController()
        viewControllerFactory.makePayerBottomsheetReturnValue = viewController

        let pwwFlow = MockFlow<Void>()
        payWithWiseFlowFactory.makeModalFlowWithAcquiringPaymentKeyReturnValue = pwwFlow

        flow.start()
        flow.dismiss()

        let dismisser = viewControllerPresenterFactory.bottomSheetPresenter.dismisser
        XCTAssertTrue(dismisser.dismissCalled)
    }

    func test_startCurrencySelection() throws {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .business
        )
        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)
        let viewController = MockViewController()
        viewControllerFactory.makePayerBottomsheetReturnValue = viewController

        let pwwFlow = MockFlow<Void>()
        payWithWiseFlowFactory.makeModalFlowWithAcquiringPaymentKeyReturnValue = pwwFlow

        flow.start()

        flow.showCurrencySelector(activeCurrencies: [.PLN], selectedCurrency: nil, onCurrencySelected: { _ in })

        try XCTSkipAlways("todo - get visible controller from navigation")
    }

    func test_startPayWithWiseFlow() throws {
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .business
        )

        let receivedPayerData = QuickpayPayerData(
            value: 10, currency: .PLN, description: nil, businessQuickpay: "johnDoe"
        )

        wisetagContactInteractor.lookupContactReturnValue = .just(contactSearch)

        let viewController = MockViewController()
        viewControllerFactory.makePayerBottomsheetReturnValue = viewController

        let pwwFlow = MockFlow<Void>()
        payWithWiseFlowFactory.makeModalFlowWithAcquiringPaymentKeyReturnValue = pwwFlow

        flow.start()

        flow.navigateToPayWithWise(payerData: receivedPayerData)

        let dismisser = viewControllerPresenterFactory.bottomSheetPresenter.dismisser
        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(payWithWiseFlowFactory.makeModalFlowWithAcquiringPaymentKeyCallsCount, 1)
        let arguments = try XCTUnwrap(payWithWiseFlowFactory.makeModalFlowWithAcquiringPaymentKeyReceivedArguments)
        XCTAssertTrue(arguments.host === navigationController)
    }
}
