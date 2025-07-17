import BalanceKit
import Neptune
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol SalarySwitchFlowFactory: AnyObject {
    func make(
        origin: SalarySwitchFlowStartOrigin,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        profile: Profile,
        currencyCode: CurrencyCode,
        host: UIViewController,
        articleFactory: HelpCenterArticleFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    ) -> any Flow<Void>
}

public final class SalarySwitchFlowFactoryImpl {
    private let presenterFactory: ViewControllerPresenterFactory

    public init(
        presenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl()
    ) {
        self.presenterFactory = presenterFactory
    }
}

extension SalarySwitchFlowFactoryImpl: SalarySwitchFlowFactory {
    func make(
        origin: SalarySwitchFlowStartOrigin,
        accountDetailsRequirementStatus: SalarySwitchFlowAccountDetailsRequirementStatus,
        profile: Profile,
        currencyCode: CurrencyCode,
        host: UIViewController,
        articleFactory: HelpCenterArticleFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    ) -> any Flow<Void> {
        SalarySwitchFlow(
            origin: origin,
            accountDetailsRequirementStatus: accountDetailsRequirementStatus,
            profile: profile,
            currencyCode: currencyCode,
            presenterFactory: presenterFactory,
            host: host,
            articleFactory: articleFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory
        )
    }
}

// MARK: - Add money

extension SalarySwitchFlowFactoryImpl {
    public func makeForAddMoney(
        hasActiveAccountDetails: Bool,
        balanceId: BalanceId,
        currencyCode: CurrencyCode,
        profile: Profile,
        host: UIViewController,
        articleFactory: HelpCenterArticleFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    ) -> any Flow<Void> {
        let status: SalarySwitchFlowAccountDetailsRequirementStatus = hasActiveAccountDetails
            ? .hasActiveAccountDetails(balanceId: balanceId)
            : .needsAccountDetailsActivation
        return make(
            origin: .addMoney,
            accountDetailsRequirementStatus: status,
            profile: profile,
            currencyCode: currencyCode,
            host: host,
            articleFactory: articleFactory,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory
        )
    }
}
