import BalanceKit
import Foundation
import Neptune
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol OrderAccountDetailsFlowFactory {
    func makeFlow(
        source: OrderAccountDetailsFlowInvocationSource,
        orderSource: OrderAccountDetailsSource,
        navigationController: UINavigationController,
        profile: Profile,
        currency: CurrencyCode,
        shouldShowRequirements: Bool
    ) -> any Flow<OrderAccountDetailsFlowResult>

    func makeWrappedInModalPresentation(
        source: OrderAccountDetailsFlowInvocationSource,
        orderSource: OrderAccountDetailsSource,
        profile: Profile,
        currency: CurrencyCode,
        rootController: UIViewController
    ) -> any Flow<OrderAccountDetailsFlowResult>
}

extension OrderAccountDetailsFlowFactory {
    func makeFlow(
        source: OrderAccountDetailsFlowInvocationSource,
        orderSource: OrderAccountDetailsSource,
        navigationController: UINavigationController,
        profile: Profile,
        currency: CurrencyCode
    ) -> any Flow<OrderAccountDetailsFlowResult> {
        makeFlow(
            source: source,
            orderSource: orderSource,
            navigationController: navigationController,
            profile: profile,
            currency: currency,
            shouldShowRequirements: true
        )
    }
}
