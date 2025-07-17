import Foundation
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import WiseCore

final class ReceiveRestrictionPresenterTests: TWTestCase {
    private let profileId = ProfileId(123)

    private var presenter: ReceiveRestrictionPresenterImpl!
    private var useCase: ReceiveRestrictionUseCaseMock!
    private var router: ReceiveRestrictionRoutingDelegateMock!
    private var view: ReceiveRestrictionViewMock!

    override func setUp() {
        super.setUp()

        useCase = ReceiveRestrictionUseCaseMock()
        router = ReceiveRestrictionRoutingDelegateMock()
        view = ReceiveRestrictionViewMock()
        presenter = ReceiveRestrictionPresenterImpl(
            context: ReceiveRestrictionContext.canned,
            profileId: profileId,
            useCase: useCase,
            routingDelegate: router,
            scheduler: .immediate
        )
        trackForMemoryLeak(instance: presenter) { [weak self] in
            self?.presenter = nil
        }
    }

    override func tearDown() {
        presenter = nil
        router = nil
        useCase = nil
        view = nil

        super.tearDown()
    }
}

// MARK: - Loading screen

extension ReceiveRestrictionPresenterTests {
    func testLoadingScreen_GivenSuccessAndReceiveRestriction_CorrectValuesPassedToView() {
        let expectedBody = "Booooody"
        useCase.receiveRestrictionReturnValue = .just(ReceiveRestriction.build(body: expectedBody))
        presenter.start(view: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(view.configureReceivedViewModel?.body, expectedBody)
    }

    func testLoadingScreen_GivenError_ThenErrorStateShown() {
        let error = MockError.dummy
        useCase.receiveRestrictionReturnValue = .fail(with: error)
        presenter.start(view: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(
            view.showErrorStateReceivedArguments?.message,
            error.localizedDescription
        )
    }
}

// MARK: - URI Handling

extension ReceiveRestrictionPresenterTests {
    func testURIHandling_GivenIncorrectFormat_ThenNothingHappens() {
        let uriString = ""
        presenter.handleURI(string: uriString)

        XCTAssertFalse(router.handleURICalled)
    }

    func testURIHandling_GivenCorrectFormat_ThenNothingHappens() throws {
        let uriString = "https://abasdas.com"
        let url = try XCTUnwrap(URL(string: uriString))
        let expectedURI = URI.url(url)
        presenter.handleURI(string: uriString)

        XCTAssertEqual(router.handleURIReceivedUri, expectedURI)
    }
}

// MARK: - Dismiss

extension ReceiveRestrictionPresenterTests {
    func testDismisss_WhenDismissInvoked_ThenRouterReceivedDismiss() {
        presenter.dismiss()
        XCTAssertTrue(router.dismissCalled)
    }
}
