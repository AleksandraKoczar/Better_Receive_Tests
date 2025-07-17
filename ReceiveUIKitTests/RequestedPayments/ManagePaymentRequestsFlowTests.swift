import AnalyticsKitTestingSupport
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

final class ManagePaymentRequestsFlowTests: TWTestCase {
    private let businessProfile = FakeBusinessProfileInfo().asProfile()
    private let personalProfile = FakePersonalProfileInfo().asProfile()

    private var flow: ManagePaymentRequestsFlow!
    private var featureService: StubFeatureService!
    private var viewControllerFactory: ManagePaymentRequestViewControllerFactoryMock!
    private var viewControllerPresenterFactory: FakeViewControllerPresenterFactory!

    override func setUp() {
        super.setUp()
        featureService = StubFeatureService()
        viewControllerFactory = ManagePaymentRequestViewControllerFactoryMock()
        viewControllerPresenterFactory = FakeViewControllerPresenterFactory()
        flow = makeFlow(
            shouldSupportInvoiceOnly: false,
            shouldShowMostRecentlyRequestedIfApplicable: false,
            profile: businessProfile
        )
    }

    override func tearDown() {
        flow = nil
        featureService = nil
        viewControllerFactory = nil
        viewControllerPresenterFactory = nil
        super.tearDown()
    }

    func test_start_givenReusableLinkIsEnabled_andBusinessProfile_thenShowPaymentRequestList() throws {
        featureService.stub(value: true, for: ReceiveKitFeatures.reusablePaymentLinksEnabled)
        let viewController = ViewControllerMock()
        viewControllerFactory.makePaymentRquestListReturnValue = viewController

        flow.start()

        let arguments = try XCTUnwrap(viewControllerFactory.makePaymentRquestListReceivedArguments)
        XCTAssertEqual(arguments.supportedPaymentRequestType, .singleUseAndReusable)
        XCTAssertEqual(arguments.visibleState, .active)
        let pushPresenter = viewControllerPresenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertTrue(pushPresenter.presentedViewController === viewController)
    }

    func test_start_givenReusableLinkIsDisabled_andBusinessProfile_thenShowPaymentRequestList() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makePaymentRquestListReturnValue = viewController

        flow.start()

        let arguments = try XCTUnwrap(viewControllerFactory.makePaymentRquestListReceivedArguments)
        XCTAssertEqual(arguments.supportedPaymentRequestType, .singleUseOnly)
        XCTAssertEqual(arguments.visibleState, .unpaid(.closestToExpiry))
        let pushPresenter = viewControllerPresenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertTrue(pushPresenter.presentedViewController === viewController)
    }

    func test_start_givenPersonalProfile_thenShowPaymentRequestList() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makePaymentRquestListReturnValue = viewController

        flow = makeFlow(
            shouldSupportInvoiceOnly: false,
            shouldShowMostRecentlyRequestedIfApplicable: false,
            profile: personalProfile
        )
        flow.start()

        let arguments = try XCTUnwrap(viewControllerFactory.makePaymentRquestListReceivedArguments)
        XCTAssertEqual(arguments.supportedPaymentRequestType, .singleUseOnly)
        XCTAssertEqual(arguments.visibleState, .unpaid(.closestToExpiry))
        let pushPresenter = viewControllerPresenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertTrue(pushPresenter.presentedViewController === viewController)
    }

    func test_start_givenPersonalProfile_andShouldShowMostRecentlyRequested_thenShowPaymentRequestList() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makePaymentRquestListReturnValue = viewController

        flow = makeFlow(
            shouldSupportInvoiceOnly: false,
            shouldShowMostRecentlyRequestedIfApplicable: true,
            profile: personalProfile
        )
        flow.start()

        let arguments = try XCTUnwrap(viewControllerFactory.makePaymentRquestListReceivedArguments)
        XCTAssertEqual(arguments.supportedPaymentRequestType, .singleUseOnly)
        XCTAssertEqual(arguments.visibleState, .unpaid(.mostRecentlyRequested))
        let pushPresenter = viewControllerPresenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertTrue(pushPresenter.presentedViewController === viewController)
    }

    func test_start_givenSupportInvoiceOnly_thenShowPaymentRequestList() throws {
        let viewController = ViewControllerMock()
        viewControllerFactory.makePaymentRquestListReturnValue = viewController

        flow = makeFlow(
            shouldSupportInvoiceOnly: true,
            shouldShowMostRecentlyRequestedIfApplicable: false,
            profile: businessProfile
        )
        flow.start()

        let arguments = try XCTUnwrap(viewControllerFactory.makePaymentRquestListReceivedArguments)
        XCTAssertEqual(arguments.supportedPaymentRequestType, .invoiceOnly)
        XCTAssertEqual(arguments.visibleState, .upcoming(.closestToExpiry))
        let pushPresenter = viewControllerPresenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.presentCalled)
        XCTAssertTrue(pushPresenter.presentedViewController === viewController)
    }
}

// MARK: - Helpers

private extension ManagePaymentRequestsFlowTests {
    func makeFlow(
        shouldSupportInvoiceOnly: Bool,
        shouldShowMostRecentlyRequestedIfApplicable: Bool,
        profile: Profile
    ) -> ManagePaymentRequestsFlow {
        ManagePaymentRequestsFlow(
            shouldSupportInvoiceOnly: shouldSupportInvoiceOnly,
            shouldShowMostRecentlyRequestedIfApplicable: shouldShowMostRecentlyRequestedIfApplicable,
            profile: profile,
            viewControllerFactory: viewControllerFactory,
            navigationController: MockNavigationController(),
            analyticsTracker: StubAnalyticsTracker(),
            featureService: featureService,
            presenterFactory: viewControllerPresenterFactory
        )
    }
}
