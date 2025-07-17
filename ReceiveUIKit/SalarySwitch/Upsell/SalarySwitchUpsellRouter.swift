import BalanceKit
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol SalarySwitchUpsellRouter: AnyObject {
    func showHud()
    func hideHud()
    func showErrorAlert(title: String, message: String)
    func showUpsell(viewModel: UpsellViewModel)
    func showFAQ(path: String)
    func showOrderAccountDetailsFlow(
        profile: Profile,
        currency: CurrencyCode
    )
    func showOptionSelection(
        balanceId: BalanceId,
        currency: CurrencyCode,
        profileId: ProfileId
    )
}

final class SalarySwitchUpsellRouterImpl {
    private let host: UIViewController
    private let presenterFactory: ViewControllerPresenterFactory
    private let orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    private let factory: SalarySwitchFactory
    private let presenter: ViewControllerPresenter
    private let dismisserCapturer: (ViewControllerDismisser) -> Void
    private let articleFactory: HelpCenterArticleFactory

    private var navigationController: UINavigationController?
    private var articleFlow: (any Flow<Void>)?
    private var dismisser: ViewControllerDismisser? {
        didSet {
            guard let value = dismisser else { return }
            dismisserCapturer(value)
        }
    }

    private var orderAccountDetailsFlow: (any Flow<OrderAccountDetailsFlowResult>)?

    init(
        host: UIViewController,
        presenterFactory: ViewControllerPresenterFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        factory: SalarySwitchFactory,
        articleFactory: HelpCenterArticleFactory,
        dismisserCapturer: @escaping (ViewControllerDismisser) -> Void
    ) {
        self.host = host
        self.presenterFactory = presenterFactory
        self.orderAccountDetailsFlowFactory = orderAccountDetailsFlowFactory
        self.factory = factory
        self.articleFactory = articleFactory
        self.dismisserCapturer = dismisserCapturer

        presenter = presenterFactory.makeModalPresenter(parent: host)
    }
}

// MARK: - SalarySwitchUpsellRouter

extension SalarySwitchUpsellRouterImpl: SalarySwitchUpsellRouter {
    func showHud() {
        host.showHud()
    }

    func hideHud() {
        host.hideHud()
    }

    func showErrorAlert(title: String, message: String) {
        host.showErrorAlert(title: title, message: message)
    }

    func showUpsell(viewModel: UpsellViewModel) {
        let viewController = factory.makeUpsellViewController(viewModel: viewModel)
        let navController = viewController.navigationWrapped()
        dismisser = presenter.present(viewController: navController)
        navigationController = navController
    }

    func showOptionSelection(
        balanceId: BalanceId,
        currency: CurrencyCode,
        profileId: ProfileId
    ) {
        guard let navigationController else { return }
        let viewController = factory.makeOptionsSelectionViewController(
            balanceId: balanceId,
            currencyCode: currency,
            profileId: profileId,
            navigationHost: navigationController
        )
        var presenter = presenterFactory.makePushPresenter(
            navigationController: navigationController
        )
        presenter.keepOnlyLastViewControllerOnStack = true
        presenter.present(
            viewController: viewController,
            animated: UIView.shouldAnimate
        )
    }

    func showFAQ(path: String) {
        let url = Branding.current.url.appendingPathComponent(path)
        guard let articleId = articleFactory.isArticleLink(url: url) else {
            return
        }

        startArticleFlow(hostViewController: host, articleId: articleId)
    }

    func startArticleFlow(hostViewController: UIViewController, articleId: HelpCenterArticleId) {
        let flow = articleFactory.makeArticleFlow(
            hostController: hostViewController,
            articleId: articleId
        )
        flow.onFinish { [weak self] _, dismisser in
            self?.articleFlow = nil
            dismisser?.dismiss()
        }
        flow.start()
        articleFlow = flow
    }

    func showOrderAccountDetailsFlow(
        profile: Profile,
        currency: CurrencyCode
    ) {
        guard let navigationController else { return }
        orderAccountDetailsFlow = orderAccountDetailsFlowFactory.makeFlow(
            source: .salarySwitch,
            orderSource: .other,
            navigationController: navigationController,
            profile: profile,
            currency: currency
        )
        orderAccountDetailsFlow?.onFinish { [weak self] result, dismisser in
            guard let self else { return }
            switch result {
            case .ordered:
                NotificationCenter.default.post(
                    name: .balancesNeedUpdate,
                    object: nil
                )
            case .accountDetailsOpen,
                 .dismissed,
                 .abortedWithError:
                break
            }
            self.navigationController?.topViewController?.dismiss(animated: UIView.shouldAnimate)
            dismisser?.dismiss()
            orderAccountDetailsFlow = nil
        }

        orderAccountDetailsFlow?.start()
    }
}
