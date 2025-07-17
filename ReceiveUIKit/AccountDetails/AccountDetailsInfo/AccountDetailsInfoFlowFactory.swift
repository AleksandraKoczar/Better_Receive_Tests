import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol AccountDetailsInfoFlowFactory {
    func make(
        invocationSource: AccountDetailsInfoInvocationSource,
        accountDetailsId: AccountDetailsId,
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void>

    func makeModalFlow(
        invocationSource: AccountDetailsInfoInvocationSource,
        accountDetailsId: AccountDetailsId,
        profile: Profile,
        rootViewController: UIViewController
    ) -> any Flow<Void>
}

public final class AccountDetailsInfoFlowFactoryImpl: AccountDetailsInfoFlowFactory {
    private let accountDetailsInfoViewControllerFactory: AccountDetailsInfoViewControllerFactory

    public init(accountDetailsInfoViewControllerFactory: AccountDetailsInfoViewControllerFactory) {
        self.accountDetailsInfoViewControllerFactory = accountDetailsInfoViewControllerFactory
    }

    public func make(
        invocationSource: AccountDetailsInfoInvocationSource,
        accountDetailsId: AccountDetailsId,
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        AccountDetailsInfoFlow(
            invocationSource: invocationSource,
            accountDetailsId: accountDetailsId,
            profile: profile,
            navigationController: navigationController,
            accountDetailsInfoViewControllerFactory: accountDetailsInfoViewControllerFactory,
            featureService: GOS[FeatureServiceKey.self]
        )
    }

    public func makeModalFlow(
        invocationSource: AccountDetailsInfoInvocationSource,
        accountDetailsId: AccountDetailsId,
        profile: Profile,
        rootViewController: UIViewController
    ) -> any Flow<Void> {
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen

        let flow = AccountDetailsInfoFlow(
            invocationSource: invocationSource,
            accountDetailsId: accountDetailsId,
            profile: profile,
            navigationController: navigationController,
            accountDetailsInfoViewControllerFactory: accountDetailsInfoViewControllerFactory,
            featureService: GOS[FeatureServiceKey.self]
        )

        return ModalPresentationFlow(
            flow: flow,
            rootViewController: rootViewController,
            flowController: navigationController
        )
    }
}
