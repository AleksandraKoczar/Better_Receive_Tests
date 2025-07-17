import Neptune
import ReceiveKit
import TWFoundation
import TWUI
import UIKit
import WiseCore

final class ReceiveMethodsQRSharingFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private let balanceId: BalanceId
    private let accountDetailsId: AccountDetailsId
    private let profileId: ProfileId
    private let hostController: UIViewController
    private let viewControllerFactory: ReceiveMethodQRSharingViewControllerFactory
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory

    private var dismisser: ViewControllerDismisser?

    init(
        balanceId: BalanceId,
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId,
        hostController: UIViewController,
        viewControllerFactory: ReceiveMethodQRSharingViewControllerFactory = ReceiveMethodQRSharingViewControllerFactoryImpl(),
        viewControllerPresenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl()
    ) {
        self.balanceId = balanceId
        self.accountDetailsId = accountDetailsId
        self.profileId = profileId
        self.hostController = hostController
        self.viewControllerFactory = viewControllerFactory
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
    }

    func start() {
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        let viewController = viewControllerFactory.make(
            accountDetailsId: accountDetailsId,
            profileId: profileId,
            mode: .all,
            navigationController: navigationController
        )
        navigationController.setViewControllers([viewController], animated: false)
        dismisser = viewControllerPresenterFactory
            .makeModalPresenter(parent: hostController)
            .present(viewController: navigationController)
        flowHandler.flowStarted()
    }

    func terminate() {
        flowHandler.flowFinished(
            result: (),
            dismisser: dismisser
        )
    }
}
