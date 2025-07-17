import BalanceKit
import Neptune
import ReceiveKit
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsListRouter: AnyObject {
    func showSingleAccountDetails(_ accountDetails: ActiveAccountDetails, profile: Profile)
    func showMultipleAccountDetails(_ accountDetails: [ActiveAccountDetails], profile: Profile)

    func requestAccountDetails(country: Country?, completion: @escaping () -> Void)
    func dismiss()
}

final class AccountDetailsListRouterImpl: AccountDetailsListRouter {
    private weak var navigationHost: UIViewController?
    private let accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory
    private let accountDetailsListFactory: AccountDetailsListFactory
    private let accountDetailsWishListInteractor: AccountDetailsWishListInteractor
    private let featureService: FeatureService

    init(
        navigationHost: UIViewController?,
        accountDetailsListFactory: AccountDetailsListFactory,
        accountDetailsWishListInteractor: AccountDetailsWishListInteractor,
        accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory,
        featureService: FeatureService = GOS[FeatureServiceKey.self]
    ) {
        self.navigationHost = navigationHost
        self.accountDetailsListFactory = accountDetailsListFactory
        self.accountDetailsWishListInteractor = accountDetailsWishListInteractor
        self.accountDetailsInfoFactory = accountDetailsInfoFactory
        self.featureService = featureService
    }

    func showMultipleAccountDetails(_ accountDetails: [ActiveAccountDetails], profile: Profile) {
        let vc = accountDetailsListFactory.makeMultiAccountDetailSameCurrencyViewController(
            navigationHost: navigationHost,
            profile: profile,
            activeAccountDetailsList: accountDetails,
            didDismissCompletion: nil
        )
        navigationHost?.show(vc, sender: nil)
    }

    func showSingleAccountDetails(_ accountDetails: ActiveAccountDetails, profile: Profile) {
        if featureService.isOn(ReceiveKitFeatures.accountDetailsIAEnabled), featureService.isOn(ReceiveKitFeatures.accountDetailsIAReworkEnabled) {
            guard let navHost = navigationHost as? UINavigationController else { return }
            let vc = accountDetailsInfoFactory.makeAccountDetailsV3ViewController(
                profile: profile,
                navigationHost: navHost,
                invocationSource: .accountDetailsList,
                accountDetailsId: accountDetails.id
            )
            navigationHost?.show(vc, sender: nil)
        } else {
            guard let navHost = navigationHost as? UINavigationController else { return }
            let vc = accountDetailsInfoFactory.makeInfoViewController(
                navigationHost: navHost,
                invocationSource: .accountDetailsList,
                profile: profile,
                activeAccountDetails: accountDetails,
                completion: nil
            )
            navigationHost?.show(vc, sender: nil)
        }
    }

    func requestAccountDetails(
        country: Country?,
        completion: @escaping () -> Void
    ) {
        let vc = AccountDetailsWishFactory.makeViewController(
            country: country,
            interactor: accountDetailsWishListInteractor,
            completion: completion
        )
        navigationHost?.show(vc, sender: nil)
    }

    func dismiss() {
        guard let navigationHost = navigationHost as? UINavigationController, navigationHost.viewControllers.count > 1 else {
            self.navigationHost?.dismiss(animated: UIView.shouldAnimate)
            return
        }
        navigationHost.popToRootViewController(animated: UIView.shouldAnimate)
    }
}
