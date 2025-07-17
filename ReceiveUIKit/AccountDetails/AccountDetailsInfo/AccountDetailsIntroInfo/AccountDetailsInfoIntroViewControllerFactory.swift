import AnalyticsKit
import ApiKit
import BalanceKit
import DeepLinkKit
import ObjectModelKit
import PersistenceKit
import TWUI
import UIKit
import UserKit
import WiseCore

enum AccountDetailsInfoIntroViewControllerFactory {
    static func make(
        shouldShowDetailsSummary: Bool,
        navigationHost: UINavigationController,
        profile: Profile,
        currencyCode: CurrencyCode,
        receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type,
        accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        articleFactory: HelpCenterArticleFactory,
        feedbackService: FeedbackService,
        onDismiss: @escaping () -> Void
    ) -> UIViewController {
        let infoViewControllerFactory = AccountDetailsInfoViewControllerFactoryImpl(
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            articleFactory: articleFactory,
            feedbackService: feedbackService
        )

        let salarySwitchFlowFactory = SalarySwitchFlowFactoryImpl()

        let router = AccountDetailsInfoIntroRouterImpl(
            articleFactory: articleFactory,
            navigationHost: navigationHost,
            infoViewControllerFactory: infoViewControllerFactory,
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            salarySwitchFlowFactory: salarySwitchFlowFactory
        )
        let accountDetailsUseCase = AccountDetailsUseCaseFactory.makeUseCase()
        let presenter = AccountDetailsInfoIntroPresenterImpl(
            shouldShowDetailsSummary: shouldShowDetailsSummary,
            router: router,
            accountDetailsUseCase: accountDetailsUseCase,
            currencyCode: currencyCode,
            profile: profile,
            onDismiss: onDismiss
        )

        return AccountDetailsInfoIntroViewController(presenter: presenter)
    }
}
