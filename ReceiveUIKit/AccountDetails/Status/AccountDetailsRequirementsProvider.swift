import BalanceKit

public protocol AccountDetailsRequirementsProvider: AnyObject {
    var requirements: [AccountDetailsRequirement] { get }
}
