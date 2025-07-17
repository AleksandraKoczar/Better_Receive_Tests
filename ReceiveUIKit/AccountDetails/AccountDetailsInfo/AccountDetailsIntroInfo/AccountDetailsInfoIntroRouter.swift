import BalanceKit
import LoggingKit
import Neptune
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsInfoIntroRouter: AnyObject {
    func showAccountDetailsInfo(
        profile: Profile,
        accountDetails: ActiveAccountDetails
    )

    func showSalarySwitch(
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profile: Profile
    )

    @MainActor
    func showReceiveMoney()
}

final class AccountDetailsInfoIntroRouterImpl {
    private let articleFactory: HelpCenterArticleFactory
    private let navigationHost: UINavigationController
    private let infoViewControllerFactory: AccountDetailsInfoViewControllerFactory
    private let receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type
    private let orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    private let salarySwitchFlowFactory: SalarySwitchFlowFactory
    private let featureService: FeatureService

    private var salarySwitchFlow: (any Flow<Void>)?

    init(
        articleFactory: HelpCenterArticleFactory,
        navigationHost: UINavigationController,
        infoViewControllerFactory: AccountDetailsInfoViewControllerFactory,
        receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        salarySwitchFlowFactory: SalarySwitchFlowFactory,
        featureService: FeatureService = GOS[FeatureServiceKey.self]
    ) {
        self.articleFactory = articleFactory
        self.navigationHost = navigationHost
        self.infoViewControllerFactory = infoViewControllerFactory
        self.receiveSpaceFactoryType = receiveSpaceFactoryType
        self.orderAccountDetailsFlowFactory = orderAccountDetailsFlowFactory
        self.salarySwitchFlowFactory = salarySwitchFlowFactory
        self.featureService = featureService
    }
}

// MARK: - AccountDetailsInfoIntroRouter

extension AccountDetailsInfoIntroRouterImpl: AccountDetailsInfoIntroRouter {
    func showAccountDetailsInfo(
        profile: Profile,
        accountDetails: ActiveAccountDetails
    ) {
        guard featureService.isOn(ReceiveKitFeatures.accountDetailsIAEnabled),
              featureService.isOn(ReceiveKitFeatures.accountDetailsIAReworkEnabled) else {
            let viewController = infoViewControllerFactory.makeInfoViewController(
                navigationHost: navigationHost,
                invocationSource: .accountDetailsIntro,
                profile: profile,
                activeAccountDetails: accountDetails,
                completion: nil
            )
            navigationHost.show(viewController, sender: nil)
            return
        }

        let viewController = infoViewControllerFactory.makeAccountDetailsV3ViewController(
            profile: profile,
            navigationHost: navigationHost,
            invocationSource: .accountDetailsIntro,
            accountDetailsId: accountDetails.id
        )
        navigationHost.show(viewController, sender: nil)
    }

    func showSalarySwitch(
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profile: Profile
    ) {
        salarySwitchFlow = salarySwitchFlowFactory.make(
            origin: .accountDetailsIntro,
            accountDetailsRequirementStatus: .hasActiveAccountDetails(balanceId: balanceId),
            profile: profile,
            currencyCode: currencyCode,
            host: navigationHost,
            articleFactory: articleFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory
        )

        salarySwitchFlow?.onFinish { [weak self] _, dismisser in
            guard let self else { return }
            dismisser?.dismiss()
            salarySwitchFlow = nil
        }
        salarySwitchFlow?.start()
    }

    func showReceiveMoney() {
        let vc = receiveSpaceFactoryType.make(
            navigationController: navigationHost,
            hasBalanceAccount: true
        )

        navigationHost.pushViewController(vc, animated: UIView.shouldAnimate)
    }
}
