import AnalyticsKit
import Neptune
import TWFoundation
import TWUI
import UIKit
import UserKit

final class GetPaidOptionsFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty
    private let profile: Profile
    private let userProvider: UserProvider
    private let navigationController: UINavigationController
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory
    private let requestMoneyFlowFactory: RequestMoneyFlowFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<GetPaidOptionsAnalyticsView>

    private var bottomSheetDismisser: BottomSheetDismisser?
    private var requestMoneyFlow: (any Flow<Void>)?

    init(
        profile: Profile,
        navigationController: UINavigationController,
        requestMoneyFlowFactory: RequestMoneyFlowFactory,
        webViewControllerFactory: WebViewControllerFactory.Type,
        viewControllerPresenterFactory: ViewControllerPresenterFactory,
        userProvider: UserProvider = GOS[UserProviderKey.self],
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self]
    ) {
        self.profile = profile
        self.navigationController = navigationController
        self.requestMoneyFlowFactory = requestMoneyFlowFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
        self.userProvider = userProvider
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: GetPaidOptionsAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }

    func start() {
        let viewController = GetPaidOptionsBottomSheetViewController(
            delegate: self
        )

        let bottomSheetPresenter = viewControllerPresenterFactory.makeBottomSheetPresenter(parent: navigationController)
        bottomSheetDismisser = bottomSheetPresenter.present(
            viewController: viewController,
            completion: nil
        )
    }

    func terminate() {
        flowHandler.flowFinished(result: (), dismisser: bottomSheetDismisser)
    }
}

extension GetPaidOptionsFlow: GetPaidOptionsRoutingDelegate {
    func didSelectGetPaidOption(_ option: GetPaidOption) {
        switch option {
        case .requestMoney:
            analyticsViewTracker.track(GetPaidOptionsAnalyticsView.CreatePaymentLinkCTA())
            startRequestMoneyFlow()
        case .createInvoice:
            analyticsViewTracker.track(GetPaidOptionsAnalyticsView.CreateInvoiceCTA())
            startCreateInvoiceFlow()
        }
    }
}

private extension GetPaidOptionsFlow {
    func startRequestMoneyFlow() {
        bottomSheetDismisser?.dismiss { [weak self] in
            guard let self else { return }
            let flow = requestMoneyFlowFactory.makeModalForLaunchpadFactory(
                profile: profile,
                balanceId: nil,
                contact: nil,
                rootViewController: navigationController
            )

            flow.onFinish { [weak self] _, dismisser in
                self?.requestMoneyFlow = nil
                self?.flowHandler.flowFinished(result: (), dismisser: dismisser)
            }
            requestMoneyFlow = flow
            flow.start()
        }
    }

    func startCreateInvoiceFlow() {
        bottomSheetDismisser?.dismiss { [weak self] in
            guard let self else { return }
            let url = Branding.current.url.appendingPathComponent(ReceiveWebViewUrlConstants.createInvoiceUrlPath)
            let viewController = webViewControllerFactory.make(
                with: url,
                userInfoForAuthentication: (userProvider.user.userId, profile.id)
            )
            viewController.isDownloadSupported = true
            navigationController.present(
                viewController.navigationWrapped(),
                animated: UIView.shouldAnimate
            )
        }
    }
}
