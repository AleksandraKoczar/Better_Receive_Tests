import Foundation
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol ReceiveAccountDetailsCreationFlowFactory {
    func makeForReceive(
        shouldClearNavigation: Bool,
        source: OrderAccountDetailsSource,
        currencyCode: CurrencyCode,
        profile: Profile,
        navigationHost: UINavigationController
    ) -> any Flow<ReceiveAccountDetailsCreationFlowResult>
}
