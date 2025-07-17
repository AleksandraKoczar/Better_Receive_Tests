import BalanceKit
import Foundation
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import XCTest

final class PixStatusCheckerTests: XCTestCase {
    // MARK: - isPixAvailableAccountDetails

    func test_isPixAvailableAccountDetails_returnsTrue_whenCurrencyIsBRL_andNotDeprecated() {
        let details = ActiveAccountDetails.build(currency: .BRL, isDeprecated: false)
        XCTAssertTrue(PixStatusChecker.isPixAvailableAccountDetails(accountDetails: details))
    }

    func test_isPixAvailableAccountDetails_returnsFalse_whenCurrencyIsNotBRL() {
        let details = ActiveAccountDetails.build(currency: .USD, isDeprecated: false)
        XCTAssertFalse(PixStatusChecker.isPixAvailableAccountDetails(accountDetails: details))
    }

    func test_isPixAvailableAccountDetails_returnsFalse_whenIsDeprecated() {
        let details = ActiveAccountDetails.build(currency: .BRL, isDeprecated: true)
        XCTAssertFalse(PixStatusChecker.isPixAvailableAccountDetails(accountDetails: details))
    }

    // MARK: - hasPixAliasRegistered

    func test_hasPixAliasRegistered_returnsTrue_whenRegisteredPixAliasExists() {
        let aliases = [
            ReceiveMethodAlias.build(state: .registered, aliasScheme: "PIX"),
            ReceiveMethodAlias.build(state: .registered, aliasScheme: "OTHER"),
        ]
        XCTAssertTrue(PixStatusChecker.hasPixAliasRegistered(aliases: aliases))
    }

    func test_hasPixAliasRegistered_returnsTrue_whenPendingRegistrationPixAliasExists() {
        let aliases = [
            ReceiveMethodAlias.build(state: .pendingRegistration, aliasScheme: "PIX"),
        ]
        XCTAssertTrue(PixStatusChecker.hasPixAliasRegistered(aliases: aliases))
    }

    func test_hasPixAliasRegistered_returnsFalse_whenNoPixAlias() {
        let aliases = [
            ReceiveMethodAlias.build(state: .registered, aliasScheme: "OTHER"),
        ]
        XCTAssertFalse(PixStatusChecker.hasPixAliasRegistered(aliases: aliases))
    }

    func test_hasPixAliasRegistered_returnsFalse_whenPixAliasNotRegisteredOrPending() {
        let aliases = [
            ReceiveMethodAlias.build(state: .unregistered, aliasScheme: "PIX"),
        ]
        XCTAssertFalse(PixStatusChecker.hasPixAliasRegistered(aliases: aliases))
    }
}
