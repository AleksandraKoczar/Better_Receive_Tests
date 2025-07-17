import AnalyticsKit
import BalanceKit
import Neptune
import TWFoundation
import TWUI
import UserKit
import WiseCore

public enum AccountDetailsBalanceHeaderFlowFactory {
    public static func make(
        canShowUpsell: Bool,
        canOrderMultipleAccountDetails: Bool,
        currencyCode: CurrencyCode,
        profile: Profile,
        host: UIViewController,
        accountDetailsWishListInteractor: AccountDetailsWishListInteractor,
        faqHelper: FaqHelper,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        multipleAccountDetailsOrderFlowFactory: MultipleAccountDetailsOrderFlowWithUpsellConfigurationFactory,
        feedbackService: FeedbackService,
        receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type,
        accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type,
        articleFactory: HelpCenterArticleFactory
    ) -> any Flow<AccountDetailsBalanceHeaderFlowResult> {
        let accountDetailsUseCase = AccountDetailsUseCaseFactory.makeUseCase()
        let accountDetailsOrderUseCase = AccountDetailsOrderUseCaseFactory.make()

        let accountDetailsListFactory = AccountDetailsListFactoryImpl(
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            accountDetailsWishListInteractor: accountDetailsWishListInteractor,
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            articleFactory: articleFactory,
            feedbackService: feedbackService
        )

        let accountDetailsInfoFactory = AccountDetailsInfoViewControllerFactoryImpl(
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            articleFactory: articleFactory,
            feedbackService: feedbackService
        )
        let requirementsUseCase = AccountDetailsRequirementsUseCaseFactory.make()
        let accountDetailsSplitterScreenFactory = AccountDetailsSplitterScreenViewControllerFactoryImpl(
            accountDetailsInfoFactory: accountDetailsInfoFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory
        )
        let upsellFactory = AccountDetailsFlowUpsellFactoryImpl()
        return AccountDetailsBalanceHeaderFlow(
            canShowUpsell: canShowUpsell,
            canOrderMultipleAccountDetails: canOrderMultipleAccountDetails,
            currencyCode: currencyCode,
            profile: profile,
            host: host,
            accountDetailsUseCase: accountDetailsUseCase,
            accountDetailsOrderUseCase: accountDetailsOrderUseCase,
            accountDetailsRequirementsUseCase: requirementsUseCase,
            upsellFactory: upsellFactory,
            accountDetailsInfoFactory: accountDetailsInfoFactory,
            accountDetailsListFactory: accountDetailsListFactory,
            accountDetailsSplitterScreenFactory: accountDetailsSplitterScreenFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            multipleAccountDetailsOrderFlowFactory: multipleAccountDetailsOrderFlowFactory
        )
    }
}
