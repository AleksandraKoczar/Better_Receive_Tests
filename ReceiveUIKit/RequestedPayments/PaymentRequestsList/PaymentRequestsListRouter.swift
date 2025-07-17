import DeepLinkKit
import Foundation
import LoggingKit
import ReceiveKit
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentRequestsListRouter: AnyObject {
    func showRequestDetail(
        paymentRequestId: PaymentRequestId,
        profile: Profile,
        listUpdateDelegate: PaymentRequestListUpdater
    )
    func showNewRequestFlow(
        profile: Profile,
        listUpdateDelegate: PaymentRequestListUpdater
    )
    func showCreateInvoiceOnWeb(
        profileId: ProfileId,
        listUpdateDelegate: PaymentRequestListUpdater
    )
    func showMethodManagementOnWeb(
        profileId: ProfileId
    )
    func showHelpArticle(articleId: HelpCenterArticleId)
}

final class PaymentRequestsListRouterImpl {
    private weak var listUpdateDelegate: PaymentRequestListUpdater?

    private let navigationController: UINavigationController
    private let currencySelectorFactory: ReceiveCurrencySelectorFactory
    private let userProvider: UserProvider
    private let helpCenterArticleFactory: HelpCenterArticleFactory
    private let allDeepLinksUIFactory: AllDeepLinksUIFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private var helpFlow: (any Flow<Void>)?
    private var requestMoneyFlow: (any Flow<Void>)?

    init(
        navigationController: UINavigationController,
        currencySelectorFactory: ReceiveCurrencySelectorFactory,
        webViewControllerFactory: WebViewControllerFactory.Type,
        helpCenterArticleFactory: HelpCenterArticleFactory,
        userProvider: UserProvider = GOS[UserProviderKey.self],
        allDeepLinksUIFactory: AllDeepLinksUIFactory = GOS[AllDeepLinksUIFactoryKey.self]
    ) {
        self.navigationController = navigationController
        self.currencySelectorFactory = currencySelectorFactory
        self.userProvider = userProvider
        self.webViewControllerFactory = webViewControllerFactory
        self.helpCenterArticleFactory = helpCenterArticleFactory
        self.allDeepLinksUIFactory = allDeepLinksUIFactory
    }
}

// MARK: - PaymentRequestsListRouter

extension PaymentRequestsListRouterImpl: PaymentRequestsListRouter {
    private enum Constants {
        static let accountInvoicesPath = "/account/invoices"
        static let methodManagementPath = "/payments/method-management"
    }

    func showRequestDetail(
        paymentRequestId: PaymentRequestId,
        profile: Profile,
        listUpdateDelegate: PaymentRequestListUpdater
    ) {
        let router = PaymentRequestDetailRouterImpl(
            navigationController: navigationController,
            profile: profile,
            paymentRequestId: paymentRequestId,
            webViewControllerFactory: webViewControllerFactory
        )
        let presenter = PaymentRequestDetailPresenterImpl(
            paymentRequestId: paymentRequestId,
            profile: profile,
            router: router,
            listUpdateDelegate: listUpdateDelegate
        )
        let viewController = PaymentRequestDetailViewController(presenter: presenter)
        router.paymentDetailsRefundFlowDelegate = presenter
        router.paymentRequestDetailViewController = viewController
        navigationController.pushViewController(viewController, animated: UIView.shouldAnimate)
    }

    func showNewRequestFlow(
        profile: Profile,
        listUpdateDelegate: PaymentRequestListUpdater
    ) {
        // Pass `false` to `isUrn` here,
        // because we only support urn for Launchpad entry point now
        let route = DeepLinkRequestMoneyRouteImpl(balanceId: nil, isUrn: false, profileId: profile.id, requestType: .link)
        let context = Context(source: DeepLinkRequestMoneyRouteImpl.TargetRoute.paymentRequestList.rawValue)
        guard let flow = allDeepLinksUIFactory.build(
            for: route,
            hostController: navigationController,
            with: context
        ) else {
            softFailure("[REC] Unable to build request money flow. Please check route and ui factory registration.")
            return
        }
        flow.onFinish { [weak self, weak listUpdateDelegate] _, dismisser in
            guard let self else {
                return
            }
            requestMoneyFlow = nil
            dismisser?.dismiss()
            listUpdateDelegate?.requestStatusUpdated()
        }
        requestMoneyFlow = flow
        flow.start()
    }

    func showCreateInvoiceOnWeb(
        profileId: ProfileId,
        listUpdateDelegate: PaymentRequestListUpdater
    ) {
        self.listUpdateDelegate = listUpdateDelegate
        let url = Branding.current.url.appendingPathComponent(ReceiveWebViewUrlConstants.createInvoiceUrlPath)
        let viewController = webViewControllerFactory.make(
            with: url,
            userInfoForAuthentication: (userProvider.user.userId, profileId)
        )
        viewController.isDownloadSupported = true
        viewController.navigationDelegate = self
        navigationController.present(
            viewController.navigationWrapped(),
            animated: UIView.shouldAnimate
        )
    }

    func showMethodManagementOnWeb(
        profileId: ProfileId
    ) {
        let url = Branding.current.url.appendingPathComponent(Constants.methodManagementPath)
        let viewController = webViewControllerFactory.make(
            with: url,
            userInfoForAuthentication: (userProvider.user.userId, profileId)
        )
        viewController.navigationDelegate = self
        navigationController.present(
            viewController.navigationWrapped(),
            animated: UIView.shouldAnimate
        )
    }

    func showHelpArticle(articleId: HelpCenterArticleId) {
        let flow = helpCenterArticleFactory.makeArticleFlow(
            hostController: navigationController,
            articleId: articleId
        )

        flow.onFinish { [weak self] _, dismisser in
            dismisser.dismiss {
                self?.helpFlow = nil
            }
        }

        helpFlow = flow

        flow.start()
    }
}

// MARK: - WebContentViewControllerNavigationDelegate

extension PaymentRequestsListRouterImpl: WebContentViewControllerNavigationDelegate {
    func navigateToURL(
        viewController: WebContentViewController,
        url: URL?
    ) {
        // Dismiss the web invoice request creation flow and reload the payment request list,
        // when the web flow tries to re-direct users to `https://wise.com/account/invoices/{paymentRequestId}`
        guard let path = url?.path,
              path.contains(Constants.accountInvoicesPath) else {
            return
        }
        viewController.dismiss(animated: UIView.shouldAnimate) { [weak delegate = listUpdateDelegate] in
            delegate?.invoiceRequestCreated()
        }
    }
}
