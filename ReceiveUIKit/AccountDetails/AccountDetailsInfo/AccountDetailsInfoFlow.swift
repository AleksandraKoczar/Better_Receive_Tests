import Neptune
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

final class AccountDetailsInfoFlow: Flow {
    typealias FlowResultType = Void

    private let viewControllerPresenterFactory: ViewControllerPresenterFactory
    private let navigationController: UINavigationController
    private let accountDetailsInfoViewControllerFactory: AccountDetailsInfoViewControllerFactory
    private let accountDetailsId: AccountDetailsId
    private let profile: Profile
    private let invocationSource: AccountDetailsInfoInvocationSource
    private let featureService: FeatureService
    private var dismisser: ViewControllerDismisser?

    var flowHandler: FlowHandler<FlowResultType> = .empty

    init(
        invocationSource: AccountDetailsInfoInvocationSource,
        accountDetailsId: AccountDetailsId,
        profile: Profile,
        navigationController: UINavigationController,
        accountDetailsInfoViewControllerFactory: AccountDetailsInfoViewControllerFactory,
        featureService: FeatureService,
        viewControllerPresenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl()
    ) {
        self.invocationSource = invocationSource
        self.accountDetailsId = accountDetailsId
        self.profile = profile
        self.navigationController = navigationController
        self.accountDetailsInfoViewControllerFactory = accountDetailsInfoViewControllerFactory
        self.featureService = featureService
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
    }

    func start() {
        guard featureService.isOn(ReceiveKitFeatures.accountDetailsIAEnabled),
              featureService.isOn(ReceiveKitFeatures.accountDetailsIAReworkEnabled) else {
            let accountDetailsController = accountDetailsInfoViewControllerFactory.makeInfoViewControllerForInfoFlow(
                navigationHost: navigationController,
                invocationSource: invocationSource,
                profile: profile,
                accountDetailsId: accountDetailsId,
                completion: terminate
            )

            let pushPresenter = viewControllerPresenterFactory.makePushPresenter(
                navigationController: navigationController
            )

            dismisser = pushPresenter.present(viewController: accountDetailsController) {
                self.flowHandler.flowStarted()
            }
            return
        }

        let viewController = accountDetailsInfoViewControllerFactory.makeAccountDetailsV3ViewController(
            profile: profile,
            navigationHost: navigationController,
            invocationSource: invocationSource,
            accountDetailsId: accountDetailsId
        )

        let pushPresenter = viewControllerPresenterFactory.makePushPresenter(
            navigationController: navigationController
        )

        dismisser = pushPresenter.present(viewController: viewController) {
            self.flowHandler.flowStarted()
        }
    }

    func terminate() {
        dismisser?.dismiss()
    }
}
