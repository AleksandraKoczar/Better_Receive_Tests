import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

protocol AccountDetailsV3SwitcherViewControllerFactory: AnyObject {
    func make(
        profile: Profile,
        actionHandler: ReceiveMethodActionHandler
    ) -> UIViewController
}

public class AccountDetailsV3SwitcherViewControllerFactoryImpl: AccountDetailsV3SwitcherViewControllerFactory {
    private let accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory
    private let accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory

    public init(
        accountDetailsInfoFactory: AccountDetailsInfoViewControllerFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory
    ) {
        self.accountDetailsInfoFactory = accountDetailsInfoFactory
        self.accountDetailsCreationFlowFactory = accountDetailsCreationFlowFactory
    }

    func make(
        profile: Profile,
        actionHandler: ReceiveMethodActionHandler
    ) -> UIViewController {
        let presenter = AccountDetailsV3SwitcherPresenterImpl(
            profile: profile,
            actionHandler: actionHandler,
            receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCaseFactory.make()
        )

        return AccountDetailsV3ListViewController(presenter: presenter)
    }
}
