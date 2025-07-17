import DeepLinkKit
import DeepLinkKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundationTestingSupport
import TWTestingSupportKit
import UIKit
import UserKitTestingSupport
import WiseCore

final class OwedPaymentRequestsDeepLinkUIFactoryTests: TWTestCase {
    private var flowFactory: PayWithWiseFlowFactoryMock!
    private var uiFactory: OwedPaymentRequestsDeepLinkUIFactory!
    private var mockFlow: MockFlow<Void>!

    private var paymentRequestId: PaymentRequestId {
        .init("abc")
    }

    private var profileId: ProfileId {
        .init(123)
    }

    override func setUp() {
        super.setUp()

        let profile = FakePersonalProfileInfo()
            .with(profileId: profileId)
            .asProfile()

        let userProvider = StubUserProvider()
        userProvider.addProfile(profile, asActive: true)

        flowFactory = .init()
        uiFactory = .init(
            flowFactory: flowFactory,
            userProvider: userProvider
        )
        mockFlow = .init()
        flowFactory.makeModalFlowWithPaymentRequestIdReturnValue = mockFlow
    }

    override func tearDown() {
        flowFactory = nil
        uiFactory = nil
        mockFlow = nil
        super.tearDown()
    }

    func testBuild_GivenOwedPaymentRequestsRoute_ThenReturnsFlow() {
        let deepLinkRoute = DeepLinkOwedPaymentRequestsRoute(id: paymentRequestId)

        let flow = uiFactory.build(
            for: deepLinkRoute,
            hostController: UINavigationController(),
            with: .canned
        )

        let arguments = flowFactory.makeModalFlowWithPaymentRequestIdReceivedArguments

        XCTAssertEqual(flowFactory.makeModalFlowWithPaymentRequestIdCallsCount, 1)
        XCTAssertEqual(arguments?.paymentRequestId, paymentRequestId)
        XCTAssertIdentical(flow, mockFlow)
    }

    func testBuild_GivenWrongDeepLinkRoute_ThenReturnsNil() {
        let deepLinkRoute = DeepLinkRouteMock()

        let flow = uiFactory.build(
            for: deepLinkRoute,
            hostController: UINavigationController(),
            with: .canned
        )

        XCTAssertNil(flow)
    }
}
