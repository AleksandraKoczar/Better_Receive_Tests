import TWFoundation
import TWUI
import WiseCore

// sourcery: AutoMockable
public protocol ReceiveAccountDetailsTipsFlowFactory {
    static func make(
        navigationController: UINavigationController,
        profileId: ProfileId,
        accountDetailsId: AccountDetailsId,
        currencyCode: CurrencyCode,
        articleFactory: HelpCenterArticleFactory
    ) -> any Flow<Void>
}
