import DeepLinkKit
import MacrosKit
import Neptune
import TWFoundation
import UIKit
import WiseCore

@Mock
protocol PaymentRequestRefundFlowFactory {
    func make(
        paymentId: String,
        profileId: ProfileId,
        navigationController: UINavigationController
    ) -> any Flow<Void>
}

@Init
struct PaymentRequestRefundFlowFactoryImpl: PaymentRequestRefundFlowFactory {
    @Init(default: GOS[AllDeepLinksUIFactoryKey.self])
    private let allDeepLinksUIFactory: AllDeepLinksUIFactory

    @MainActor
    func make(
        paymentId: String,
        profileId: ProfileId,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        PaymentRequestRefundFlow(
            paymentId: paymentId,
            profileId: profileId,
            navigationController: navigationController,
            viewControllerPresenterFactory: ViewControllerPresenterFactoryImpl(),
            allDeepLinksUIFactory: allDeepLinksUIFactory,
            flowPresenter: .current
        )
    }
}
