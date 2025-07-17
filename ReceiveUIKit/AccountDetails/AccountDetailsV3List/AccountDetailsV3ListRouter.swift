import LoggingKit
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol ReceiveMethodActionHandler: AnyObject {
    func handleReceiveMethodAction(action: ReceiveMethodNavigationAction)
}

final class AccountDetailsV3ListRouterImpl: ReceiveMethodActionHandler {
    private weak var navigationHost: UINavigationController?
    private let accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory
    private let accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory
    private let accountDetailsSplitterViewControllerFactory: AccountDetailsSplitterScreenViewControllerFactory
    private let profile: Profile
    private let source: AccountDetailsInfoInvocationSource

    private var accountDetailsCreationFlow: (any Flow<ReceiveAccountDetailsCreationFlowResult>)?

    init(
        navigationHost: UINavigationController?,
        source: AccountDetailsInfoInvocationSource,
        accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        accountDetailsSplitterViewControllerFactory: AccountDetailsSplitterScreenViewControllerFactory,
        profile: Profile
    ) {
        self.navigationHost = navigationHost
        self.source = source
        self.accountDetailsInfoFactory = accountDetailsInfoFactory
        self.accountDetailsCreationFlowFactory = accountDetailsCreationFlowFactory
        self.accountDetailsSplitterViewControllerFactory = accountDetailsSplitterViewControllerFactory
        self.profile = profile
    }

    func handleReceiveMethodAction(action: ReceiveMethodNavigationAction) {
        switch action {
        case let .order(currency, balanceId, methodType):
            orderReceiveMethod(currency: currency, balanceId: balanceId, methodType: methodType)
        case let .query(context, currency, _, _, _):
            queryReceiveMethod(context: context, currency: currency)
        case let .view(id, _):
            viewReceiveMethod(accountDetailsId: id)
        }
    }
}

private extension AccountDetailsV3ListRouterImpl {
    func viewReceiveMethod(accountDetailsId: AccountDetailsId) {
        guard let navigationHost else {
            return
        }

        let vc = accountDetailsInfoFactory.makeAccountDetailsV3ViewController(
            profile: profile,
            navigationHost: navigationHost,
            invocationSource: source,
            accountDetailsId: accountDetailsId
        )

        navigationHost.pushViewController(vc, animated: true)
    }

    func orderReceiveMethod(
        currency: CurrencyCode?,
        balanceId: BalanceId?,
        methodType: ReceiveMethodNavigationViewType?
    ) {
        guard let navigationHost else {
            return
        }

        guard let currency else {
            softFailure("[REC]: There should be currency when ordering a receive method")
            return
        }

        let flow = accountDetailsCreationFlowFactory.makeForReceive(
            shouldClearNavigation: true,
            source: .other,
            currencyCode: currency,
            profile: profile,
            navigationHost: navigationHost
        )
        flow.onFinish { [weak self] _, dismisser in
            guard let self else {
                return
            }
            dismisser?.dismiss()
            accountDetailsCreationFlow = nil
        }
        accountDetailsCreationFlow = flow
        flow.start()
    }

    func queryReceiveMethod(
        context: ReceiveMethodNavigationViewContext,
        currency: CurrencyCode?
    ) {
        guard let navigationHost else {
            return
        }

        guard let currency else {
            softFailure("[REC]: There should be currency when querying a receive method")
            return
        }

        let vc = accountDetailsSplitterViewControllerFactory.make(
            profile: profile,
            currency: currency,
            source: source,
            host: navigationHost
        )

        navigationHost.pushViewController(vc, animated: true)
    }
}
