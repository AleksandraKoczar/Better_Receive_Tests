import DeepLinkKit
import MacrosKit
import TWFoundation
import UIKit
import UserKit

@Init
public struct OwedPaymentRequestsDeepLinkUIFactory {
    private let flowFactory: PayWithWiseFlowFactory

    @Init(default: GOS[UserProviderKey.self])
    private let userProvider: UserProvider
}

extension OwedPaymentRequestsDeepLinkUIFactory: DeepLinkUIFactory {
    public func build(
        for route: DeepLinkRoute,
        hostController: UIViewController,
        with context: Context
    ) -> (any Flow<Void>)? {
        guard let route = route as? DeepLinkOwedPaymentRequestsRoute,
              let profile = userProvider.activeProfile else {
            return nil
        }

        return flowFactory.makeModalFlow(
            paymentRequestId: route.id,
            profile: profile,
            host: hostController
        )
    }
}
