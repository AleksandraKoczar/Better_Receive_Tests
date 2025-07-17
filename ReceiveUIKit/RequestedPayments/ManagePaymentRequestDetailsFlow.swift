import AnalyticsKit
import ReceiveKit
import TWFoundation
import TWUI
import UserKit
import WiseCore

final class ManagePaymentRequestDetailsFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty
    private let profile: Profile
    private let paymentRequestId: PaymentRequestId
    private let navigationController: UINavigationController
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let presenterFactory: ViewControllerPresenterFactory
    private var pushPresenter: NavigationViewControllerPresenter
    private var dismisser: ViewControllerDismisser?

    init(
        profile: Profile,
        paymentRequestId: PaymentRequestId,
        navigationController: UINavigationController,
        webViewControllerFactory: WebViewControllerFactory.Type,
        presenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl()
    ) {
        self.profile = profile
        self.paymentRequestId = paymentRequestId
        self.navigationController = navigationController
        self.presenterFactory = presenterFactory
        self.webViewControllerFactory = webViewControllerFactory
        pushPresenter = presenterFactory.makePushPresenter(
            navigationController: navigationController
        )
    }

    func start() {
        showPaymentRequestDetails()
        flowHandler.flowStarted()
    }

    func terminate() {
        flowFinished()
    }

    // MARK: - Helpers

    private func flowFinished() {
        flowHandler.flowFinished(result: (), dismisser: dismisser)
    }

    private func showPaymentRequestDetails() {
        let router = PaymentRequestDetailRouterImpl(
            navigationController: navigationController,
            profile: profile,
            paymentRequestId: paymentRequestId,
            webViewControllerFactory: webViewControllerFactory,
            flowDelegate: self
        )
        let presenter = PaymentRequestDetailPresenterImpl(
            paymentRequestId: paymentRequestId,
            profile: profile,
            router: router
        )
        let viewController = PaymentRequestDetailViewController(presenter: presenter)
        router.paymentDetailsRefundFlowDelegate = presenter
        router.paymentRequestDetailViewController = viewController
        dismisser = pushPresenter.present(viewController: viewController)
    }
}

// MARK: - PaymentRequestDetailFlowDelegate

extension ManagePaymentRequestDetailsFlow: PaymentRequestDetailFlowDelegate {
    func dismiss() {
        flowFinished()
    }
}
