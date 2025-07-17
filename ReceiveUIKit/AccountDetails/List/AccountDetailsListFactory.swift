import AnalyticsKit
import BalanceKit
import DeepLinkKit
import Prism
import ReceiveKit
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol AccountDetailsListFactory {
    func makeAccountDetailsV3ListViewController(
        profile: Profile,
        navigationHost: UINavigationController?
    ) -> UIViewController

    func makeOpenAccountDetailsListViewController(
        navigationHost: UIViewController?,
        pendingAccountDetailsOrderRoute: DeepLinkAccountDetailsRoute?,
        profile: Profile?,
        userInfo: UserInfo,
        leftNavigationButton: OpenAccountDetailsListLeftNavigationButton,
        country: Country?,
        notificationCenter: NotificationCenter,
        completion: @escaping (CurrencyCode) -> Void,
        didDismissCompletion: @escaping () -> Void
    ) -> UIViewController

    // sourcery: mockName = "makeMultiAccountDetailSameCurrencyViewControllerWithCurrency"
    func makeMultiAccountDetailSameCurrencyViewController(
        navigationHost: UIViewController?,
        profile: Profile,
        currencyCode: CurrencyCode,
        didDismissCompletion: (() -> Void)?
    ) -> UIViewController

    // sourcery: mockName = "makeMultiAccountDetailSameCurrencyViewControllerWithAccountDetails"
    func makeMultiAccountDetailSameCurrencyViewController(
        navigationHost: UIViewController?,
        profile: Profile,
        activeAccountDetailsList: [ActiveAccountDetails],
        didDismissCompletion: (() -> Void)?
    ) -> UIViewController
}

public struct AccountDetailsListFactoryImpl {
    private let orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    private let accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory
    private let receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type
    private let accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type
    private let accountDetailsWishListInteractor: AccountDetailsWishListInteractor
    private let articleFactory: HelpCenterArticleFactory
    private let feedbackService: FeedbackService

    public init(
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        accountDetailsWishListInteractor: AccountDetailsWishListInteractor,
        receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type,
        accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type,
        articleFactory: HelpCenterArticleFactory,
        feedbackService: FeedbackService
    ) {
        self.orderAccountDetailsFlowFactory = orderAccountDetailsFlowFactory
        self.accountDetailsCreationFlowFactory = accountDetailsCreationFlowFactory
        self.accountDetailsWishListInteractor = accountDetailsWishListInteractor
        self.receiveSpaceFactoryType = receiveSpaceFactoryType
        self.accountDetailsTipsFlowFactoryType = accountDetailsTipsFlowFactoryType
        self.articleFactory = articleFactory
        self.feedbackService = feedbackService
    }
}

extension AccountDetailsListFactoryImpl: AccountDetailsListFactory {
    public func makeAccountDetailsV3ListViewController(
        profile: Profile,
        navigationHost: UINavigationController?
    ) -> UIViewController {
        let accountDetailsInfoFactory = AccountDetailsInfoViewControllerFactoryImpl(
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            articleFactory: articleFactory,
            feedbackService: feedbackService
        )
        let splitterScreenFactory = AccountDetailsSplitterScreenViewControllerFactoryImpl(
            accountDetailsInfoFactory: accountDetailsInfoFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory
        )
        let router = AccountDetailsV3ListRouterImpl(
            navigationHost: navigationHost,
            source: .accountDetailsList,
            accountDetailsInfoFactory: accountDetailsInfoFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            accountDetailsSplitterViewControllerFactory: splitterScreenFactory,
            profile: profile
        )

        let prismTracker = MixpanelPrismTracker()
        let receiveMethodsNavigationTracking = ReceiveMethodsNavigationTrackingFactory().make(
            onTrack: prismTracker.trackEvent(name:properties:)
        )

        let presenter = AccountDetailsV3ListPresenterImpl(
            profile: profile,
            actionHandler: router,
            receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCaseFactory.make(),
            analyticsTracker: receiveMethodsNavigationTracking
        )

        return AccountDetailsV3ListViewController(presenter: presenter)
    }

    public func makeOpenAccountDetailsListViewController(
        navigationHost: UIViewController?,
        pendingAccountDetailsOrderRoute: DeepLinkAccountDetailsRoute?,
        profile: Profile?,
        userInfo: UserInfo,
        leftNavigationButton: OpenAccountDetailsListLeftNavigationButton,
        country: Country?,
        notificationCenter: NotificationCenter,
        completion: @escaping (CurrencyCode) -> Void,
        didDismissCompletion: @escaping () -> Void
    ) -> UIViewController {
        let accountDetailsUseCase = AccountDetailsUseCaseFactory.makeUseCase()
        let accountDetailsInfoFactory = AccountDetailsInfoViewControllerFactoryImpl(
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            articleFactory: articleFactory,
            feedbackService: feedbackService
        )

        let router = AccountDetailsListRouterImpl(
            navigationHost: navigationHost,
            accountDetailsListFactory: self,
            accountDetailsWishListInteractor: accountDetailsWishListInteractor,
            accountDetailsInfoFactory: accountDetailsInfoFactory
        )
        let presenter = OpenAccountDetailsListPresenterImpl(
            accountDetailsUseCase: accountDetailsUseCase,
            pendingAccountDetailsOrderRoute: pendingAccountDetailsOrderRoute,
            router: router,
            profile: profile,
            userInfo: userInfo,
            country: country,
            leftNavigationButton: leftNavigationButton,
            completion: completion,
            didDismissCompletion: didDismissCompletion
        )
        return AccountDetailsListViewController(presenter: presenter)
    }

    public func makeMultiAccountDetailSameCurrencyViewController(
        navigationHost: UIViewController?,
        profile: Profile,
        activeAccountDetailsList: [ActiveAccountDetails],
        didDismissCompletion: (() -> Void)?
    ) -> UIViewController {
        makeMultiAccountDetailSameCurrencyViewController(
            navigationHost: navigationHost,
            profile: profile,
            source: .accountDetailsList(activeAccountDetailsList),
            didDismissCompletion: didDismissCompletion
        )
    }

    public func makeMultiAccountDetailSameCurrencyViewController(
        navigationHost: UIViewController?,
        profile: Profile,
        currencyCode: CurrencyCode,
        didDismissCompletion: (() -> Void)?
    ) -> UIViewController {
        makeMultiAccountDetailSameCurrencyViewController(
            navigationHost: navigationHost,
            profile: profile,
            source: .currencyCode(currencyCode),
            didDismissCompletion: didDismissCompletion
        )
    }
}

private extension AccountDetailsListFactoryImpl {
    func makeMultiAccountDetailSameCurrencyViewController(
        navigationHost: UIViewController?,
        profile: Profile,
        source: SingleCurrencyMultiAccountDetailsDisplaySource,
        didDismissCompletion: (() -> Void)?
    ) -> UIViewController {
        let accountDetailsUseCase = AccountDetailsUseCaseFactory.makeUseCase()
        let accountDetailsInfoFactory = AccountDetailsInfoViewControllerFactoryImpl(
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            articleFactory: articleFactory,
            feedbackService: feedbackService
        )
        let router = AccountDetailsListRouterImpl(
            navigationHost: navigationHost,
            accountDetailsListFactory: self,
            accountDetailsWishListInteractor: accountDetailsWishListInteractor,
            accountDetailsInfoFactory: accountDetailsInfoFactory
        )
        let presenter = SingleCurrencyMultiAccountDetailsPresenterImpl(
            router: router,
            profile: profile,
            source: source,
            useCase: accountDetailsUseCase,
            didDismissCompletion: didDismissCompletion
        )
        return AccountDetailsListViewController(presenter: presenter)
    }
}
