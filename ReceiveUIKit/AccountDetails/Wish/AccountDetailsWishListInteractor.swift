import Combine
import WiseCore

public struct AccountDetailsWishListBalanceCurrency: Hashable {
    public let code: CurrencyCode
    public let hasAccountDetails: Bool

    public init(code: CurrencyCode, hasAccountDetails: Bool) {
        self.code = code
        self.hasAccountDetails = hasAccountDetails
    }
}

// sourcery: AutoMockable
public protocol AccountDetailsWishListInteractor {
    func currencies(for profileId: ProfileId?) -> AnyPublisher<[AccountDetailsWishListBalanceCurrency], Error>
}
