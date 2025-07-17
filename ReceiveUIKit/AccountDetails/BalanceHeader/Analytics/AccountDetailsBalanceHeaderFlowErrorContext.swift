import TWFoundation
import WiseCore

enum AccountDetailsBalanceHeaderFlowErrorContext {
    case fetchingOrders(error: Error)
    case fetchingAccountDetails(error: Error)
    case noAccountDetailsForCurrency(currency: CurrencyCode)
    case fetchingRequirements(error: Error)
}
