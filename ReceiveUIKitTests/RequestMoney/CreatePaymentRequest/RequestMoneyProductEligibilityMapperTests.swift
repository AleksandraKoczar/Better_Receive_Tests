import ReceiveKit
@testable import ReceiveUIKit
import TWTestingSupportKit

final class RequestMoneyProductEligibilityMapperTests: TWTestCase {
    func test_make_givenContainsSingleUseAndReusable_thenReturnCorrectProductEligibility() {
        let result = RequestMoneyProductEligibilityMapper.make(
            from: [
                .singleUse,
                .reusable,
                .invoice,
            ]
        )

        XCTAssertEqual(result, .singleUseAndReusable)
    }

    func test_make_givenContainsOnlySingleUse_thenReturnCorrectProductEligibility() {
        let result = RequestMoneyProductEligibilityMapper.make(from: [.singleUse, .invoice])

        XCTAssertEqual(result, .singleUse)
    }

    func test_make_givenContainsOnlyReusable_thenReturnCorrectProductEligibility() {
        let result = RequestMoneyProductEligibilityMapper.make(from: [.reusable, .invoice])

        XCTAssertEqual(result, .reusable)
    }

    func test_make_givenContainsNoSingleUseNorReusable_thenReturnCorrectProductEligibility() {
        let result = RequestMoneyProductEligibilityMapper.make(from: [.invoice])

        XCTAssertEqual(result, .ineligible)
    }
}
