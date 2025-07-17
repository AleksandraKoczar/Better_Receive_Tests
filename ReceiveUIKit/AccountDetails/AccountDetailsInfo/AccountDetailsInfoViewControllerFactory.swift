import AnalyticsKit
import ApiKit
import BalanceKit
import DeepLinkKit
import Foundation
import ObjectModelKit
import PersistenceKit
import Prism
import ReceiveKit
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol AccountDetailsInfoViewControllerFactory {
    func makeAccountDetailsV3ViewController(
        profile: Profile,
        navigationHost: UINavigationController,
        invocationSource: AccountDetailsInfoInvocationSource,
        accountDetailsId: AccountDetailsId
    ) -> UIViewController

    func makeInfoViewController(
        navigationHost: UINavigationController,
        invocationSource: AccountDetailsInfoInvocationSource,
        profile: Profile,
        activeAccountDetails: ActiveAccountDetails,
        completion: (() -> Void)?
    ) -> UIViewController

    func makeDirectDebitInfoViewController(
        navigationHost: UINavigationController,
        invocationSource: AccountDetailsInfoInvocationSource,
        profile: Profile,
        activeAccountDetails: ActiveAccountDetails,
        completion: (() -> Void)?
    ) -> UIViewController

    func makeInfoViewControllerForInfoFlow(
        navigationHost: UINavigationController,
        invocationSource: AccountDetailsInfoInvocationSource,
        profile: Profile,
        accountDetailsId: AccountDetailsId,
        completion: (() -> Void)?
    ) -> UIViewController
}

public class AccountDetailsInfoViewControllerFactoryImpl {
    private let feedbackService: FeedbackService
    private let receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type
    private let accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type
    private let orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    private let accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory
    private let articleFactory: HelpCenterArticleFactory

    public init(
        receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type,
        accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        articleFactory: HelpCenterArticleFactory,
        feedbackService: FeedbackService
    ) {
        self.receiveSpaceFactoryType = receiveSpaceFactoryType
        self.accountDetailsTipsFlowFactoryType = accountDetailsTipsFlowFactoryType
        self.orderAccountDetailsFlowFactory = orderAccountDetailsFlowFactory
        self.accountDetailsCreationFlowFactory = accountDetailsCreationFlowFactory
        self.articleFactory = articleFactory
        self.feedbackService = feedbackService
    }
}

extension AccountDetailsInfoViewControllerFactoryImpl: AccountDetailsInfoViewControllerFactory {
    public func makeInfoViewController(
        navigationHost: UINavigationController,
        invocationSource: AccountDetailsInfoInvocationSource,
        profile: Profile,
        activeAccountDetails: ActiveAccountDetails,
        completion: (() -> Void)? = nil
    ) -> UIViewController {
        let accountDetailsUseCase = AccountDetailsUseCaseFactory.makeUseCase()
        return makeViewController(
            navigationHost: navigationHost,
            invocationSource: invocationSource,
            profile: profile,
            accountDetailsId: activeAccountDetails.id,
            activeAccountDetails: activeAccountDetails,
            accountDetailsType: .standard,
            accountDetailsUseCase: accountDetailsUseCase,
            completion: completion
        )
    }

    public func makeDirectDebitInfoViewController(
        navigationHost: UINavigationController,
        invocationSource: AccountDetailsInfoInvocationSource,
        profile: Profile,
        activeAccountDetails: ActiveAccountDetails,
        completion: (() -> Void)? = nil
    ) -> UIViewController {
        let accountDetailsUseCase = AccountDetailsContextUseCaseFactory.make(
            with: .directDebit,
            profile: profile
        )

        return makeViewController(
            navigationHost: navigationHost,
            invocationSource: invocationSource,
            profile: profile,
            accountDetailsId: activeAccountDetails.id,
            activeAccountDetails: activeAccountDetails,
            accountDetailsType: .directDebit,
            accountDetailsUseCase: accountDetailsUseCase,
            completion: completion
        )
    }

    public func makeAccountDetailsV3ViewController(
        profile: Profile,
        navigationHost: UINavigationController,
        invocationSource: AccountDetailsInfoInvocationSource,
        accountDetailsId: AccountDetailsId
    ) -> UIViewController {
        let prismTracker = MixpanelPrismTracker()
        let accountDetailsTracker = ReceiveMethodsTrackingFactory().make(
            onTrack: prismTracker.trackEvent(name:properties:)
        )
        let useCase = AccountDetailsV3UseCaseFactory.sharedUseCase
        let accountOwnershipProofUseCase = AccountOwnershipProofUseCaseFactory.make()
        let feedbackFlowFactory = AutoSubmittingFeedbackFlowFactoryImpl()
        let accountDetailsSwitcherFactory = AccountDetailsV3SwitcherViewControllerFactoryImpl(
            accountDetailsInfoFactory: self,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory
        )
        let accountDetailsSplitterFactory = AccountDetailsSplitterScreenViewControllerFactoryImpl(
            accountDetailsInfoFactory: self,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory
        )

        let router = AccountDetailsInfoRouterImpl(
            navigationController: navigationHost,
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            accountDetailsSplitterFactory: accountDetailsSplitterFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            feedbackFlowFactory: feedbackFlowFactory,
            articleFactory: articleFactory,
            feedbackService: feedbackService
        )
        let presenter = AccountDetailsV3PresenterImpl(
            invocationSource: invocationSource,
            accountDetailsId: accountDetailsId,
            profile: profile,
            accountDetailsUseCase: useCase,
            accountOwnershipProofUseCase: accountOwnershipProofUseCase,
            payerPDFUseCase: AccountDetailsPayerPDFUseCaseFactory.make(),
            receiveMethodsAliasUseCase: ReceiveMethodsAliasUseCaseFactoryImpl().make(),
            accountDetailsSwitcherFactory: accountDetailsSwitcherFactory,
            router: router,
            analyticsTracker: accountDetailsTracker
        )

        return AccountDetailsV3ViewController(presenter: presenter)
    }

    /// This view controller will show the given account details OR if they are not passed through, it will get the first account
    /// details matching a currency which is provided
    /// TO BE REMOVED SOON
    public func makeInfoViewControllerForInfoFlow(
        navigationHost: UINavigationController,
        invocationSource: AccountDetailsInfoInvocationSource,
        profile: Profile,
        accountDetailsId: AccountDetailsId,
        completion: (() -> Void)?
    ) -> UIViewController {
        let accountDetailsUseCase = AccountDetailsUseCaseFactory.makeUseCase()
        return makeViewController(
            navigationHost: navigationHost,
            invocationSource: invocationSource,
            profile: profile,
            accountDetailsId: accountDetailsId,
            activeAccountDetails: nil,
            accountDetailsType: .standard,
            accountDetailsUseCase: accountDetailsUseCase,
            completion: completion
        )
    }
}

// MARK: - Helpers

private extension AccountDetailsInfoViewControllerFactoryImpl {
    func makeViewController(
        navigationHost: UINavigationController,
        invocationSource: AccountDetailsInfoInvocationSource,
        profile: Profile,
        accountDetailsId: AccountDetailsId,
        activeAccountDetails: ActiveAccountDetails?,
        accountDetailsType: AccountDetailsType,
        accountDetailsUseCase: AccountDetailsUseCase,
        completion: (() -> Void)? = nil
    ) -> UIViewController {
        let feedbackFlowFactory = AutoSubmittingFeedbackFlowFactoryImpl()

        let accountDetailsSplitterFactory = AccountDetailsSplitterScreenViewControllerFactoryImpl(
            accountDetailsInfoFactory: self,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory
        )

        let router = AccountDetailsInfoRouterImpl(
            navigationController: navigationHost,
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            accountDetailsSplitterFactory: accountDetailsSplitterFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            feedbackFlowFactory: feedbackFlowFactory,
            articleFactory: articleFactory,
            feedbackService: feedbackService
        )

        let presenter = AccountDetailsV2PresenterImpl(
            router: router,
            accountDetailsUseCase: accountDetailsUseCase,
            payerPDFUseCase: AccountDetailsPayerPDFUseCaseFactory.make(),
            profile: profile,
            accountDetailsId: accountDetailsId,
            accountDetailsType: accountDetailsType,
            activeAccountDetails: activeAccountDetails,
            invocationSource: invocationSource,
            analyticsProvider: AccountDetailsAnalyticsProviderImpl(),
            completion: completion
        )
        return AccountDetailsV2ViewController(
            presenter: presenter
        )
    }
}
