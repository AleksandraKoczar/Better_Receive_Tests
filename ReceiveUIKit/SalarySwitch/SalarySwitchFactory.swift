import BalanceKit
import Neptune
import TransferResources
import TWUI
import WiseCore

// sourcery: AutoMockable
protocol SalarySwitchFactory: AnyObject {
    func makeUpsellViewController(viewModel: UpsellViewModel) -> UIViewController
    func makeOptionsSelectionViewController(
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profileId: ProfileId,
        navigationHost: UINavigationController
    ) -> UIViewController
}

final class SalarySwitchFactoryImpl {
    private let analyticsFlowTracker: SalarySwitchFlowAnalyticsTracker
    private let onDismiss: () -> Void

    init(
        analyticsFlowTracker: SalarySwitchFlowAnalyticsTracker,
        onDismiss: @escaping () -> Void
    ) {
        self.analyticsFlowTracker = analyticsFlowTracker
        self.onDismiss = onDismiss
    }
}

// MARK: - SalarySwitchFactory

extension SalarySwitchFactoryImpl: SalarySwitchFactory {
    func makeUpsellViewController(viewModel: UpsellViewModel) -> UIViewController {
        let viewController = UpsellViewController(viewModel: viewModel)
        viewController.modalDismissAction = onDismiss
        return viewController
    }

    func makeOptionsSelectionViewController(
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profileId: ProfileId,
        navigationHost: UINavigationController
    ) -> UIViewController {
        let router = SalarySwitchOptionSelectionRouterImpl(
            navigationHost: navigationHost
        )
        let accountDetailsUseCase = AccountDetailsUseCaseFactory.makeUseCase()
        let accountOwnershipProofUseCase = AccountOwnershipProofUseCaseFactory.make()
        let presenter = SalarySwitchOptionSelectionPresenterImpl(
            balanceId: balanceId,
            currencyCode: currencyCode,
            profileId: profileId,
            router: router,
            accountDetailsUseCase: accountDetailsUseCase,
            accountOwnershipProofUseCase: accountOwnershipProofUseCase
        )
        let viewController = SalarySwitchOptionSelectionViewController(presenter: presenter)
        viewController.modalDismissAction = onDismiss
        return viewController
    }
}
