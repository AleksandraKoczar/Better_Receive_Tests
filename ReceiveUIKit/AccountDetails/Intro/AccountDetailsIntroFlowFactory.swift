import AnalyticsKit
import ApiKit
import Neptune
import ObjectModelKit
import PersistenceKit
import TWUI
import UIKit
import UserKit
import WiseCore

public enum AccountDetailsIntroFlowResult {
    case none
}

public enum AccountDetailsIntroFlowStartOrigin {
    case notification
    case accountDetails
    case debug
}

public enum AccountDetailsIntroFlowFactory {
    public static func make(
        origin: AccountDetailsIntroFlowStartOrigin,
        shouldShowDetailsSummary: Bool,
        navigationHost: UIViewController,
        currencyCode: CurrencyCode,
        profile: Profile,
        receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type,
        accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        feedbackService: FeedbackService,
        articleFactory: HelpCenterArticleFactory
    ) -> any Flow<AccountDetailsIntroFlowResult> {
        AccountDetailsIntroFlow(
            origin: origin,
            shouldShowDetailsSummary: shouldShowDetailsSummary,
            navigationHost: navigationHost,
            currencyCode: currencyCode,
            profile: profile,
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            articleFactory: articleFactory,
            feedbackService: feedbackService
        )
    }
}
