import Foundation
import WiseCore

// sourcery: AutoEquatableForTest
public struct QuickpayPayerData {
    public let value: Decimal
    public let currency: CurrencyCode
    public let description: String?
    public let businessQuickpay: String
}
