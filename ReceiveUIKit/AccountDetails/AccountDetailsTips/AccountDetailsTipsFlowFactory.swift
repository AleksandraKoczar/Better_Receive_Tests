import TWFoundation
import TWUI
import WiseCore

public enum AccountDetailsTipsFlowFactory {
    public static func make(
        navigationController: UINavigationController,
        profileId: ProfileId,
        accountDetailsId: AccountDetailsId,
        currencyCode: CurrencyCode,
        articleFactory: HelpCenterArticleFactory
    ) -> any Flow<Void> {
        AccountDetailsTipsFlow(
            profileId: profileId,
            accountDetailsId: accountDetailsId,
            currencyCode: currencyCode,
            navigationController: navigationController,
            articleFactory: articleFactory
        )
    }
}
