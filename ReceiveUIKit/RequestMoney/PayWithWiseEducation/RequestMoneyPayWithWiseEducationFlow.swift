import TWFoundation
import TWUI

final class RequestMoneyPayWithWiseEducationFlow: Flow {
    var flowHandler: FlowHandler<RequestMoneyPayWithWiseEducationFlowResult> = .empty

    private let educationviewControllerFactory: RequestMoneyPayWithWiseEducationViewControllerFactory
    private let viewControllerPresenter: ViewControllerPresenter

    private var dismisser: ViewControllerDismisser?

    init(
        educationviewControllerFactory: RequestMoneyPayWithWiseEducationViewControllerFactory,
        viewControllerPresenter: ViewControllerPresenter
    ) {
        self.educationviewControllerFactory = educationviewControllerFactory
        self.viewControllerPresenter = viewControllerPresenter
    }

    func start() {
        flowHandler.flowStarted()
        let viewController = educationviewControllerFactory.make(routingDelegate: self)
        dismisser = viewControllerPresenter.present(viewController: viewController)
    }

    func terminate() {
        flowHandler.flowFinished(result: .cancelled, dismisser: dismisser)
    }
}

// MARK: - RequestMoneyPayWithWiseEducationRoutingDelegate

extension RequestMoneyPayWithWiseEducationFlow: RequestMoneyPayWithWiseEducationRoutingDelegate {
    func showInviteFriends() {
        flowHandler.flowFinished(result: .inviteFriendsSelected, dismisser: dismisser)
    }

    func dismiss() {
        terminate()
    }
}
