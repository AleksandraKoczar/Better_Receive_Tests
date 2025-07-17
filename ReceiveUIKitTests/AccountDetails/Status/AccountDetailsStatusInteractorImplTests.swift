import Combine
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWTestingSupportKit
import UserKitTestingSupport
import WiseCore

final class AccountDetailsStatusInteractorImplTests: TWTestCase {
    private let profile = FakeBusinessProfileInfo().asProfile()
    private let currency = CurrencyCode.GBP
    private var service: AccountDetailsStatusServiceMock!
    private var interactor: AccountDetailsStatusInteractorImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        service = AccountDetailsStatusServiceMock()
        interactor = AccountDetailsStatusInteractorImpl(
            service: service
        )
    }

    override func tearDownWithError() throws {
        service = nil
        interactor = nil
        try super.tearDownWithError()
    }

    func testStatus_whenInvokesService_thenProvidesCorrectParameters() throws {
        service.accountDetailsStatusClosure = { _, _ in
            .just(.build())
        }
        _ = try awaitPublisher(
            interactor.status(
                profileId: profile.id,
                currencyCode: currency
            )
        )

        XCTAssertEqual(service.accountDetailsStatusReceivedArguments?.profileId, profile.id)
        XCTAssertEqual(service.accountDetailsStatusReceivedArguments?.currency, currency)
    }

    func testStatus_whenServiceRespondsWithSuccess_thenResultHasValue() throws {
        service.accountDetailsStatusClosure = { _, _ in
            .just(.build())
        }
        let result = try awaitPublisher(
            interactor.status(
                profileId: profile.id,
                currencyCode: currency
            )
        )

        XCTAssertEqual(result.value, .build())
    }

    func testStatus_whenServiceRespondsWithError_thenResultHasError() throws {
        service.accountDetailsStatusClosure = { _, _ in
            .fail(with: NSError.canned)
        }
        let result = try awaitPublisher(
            interactor.status(
                profileId: profile.id,
                currencyCode: currency
            )
        )

        XCTAssertNotNil(result.error)
    }
}
