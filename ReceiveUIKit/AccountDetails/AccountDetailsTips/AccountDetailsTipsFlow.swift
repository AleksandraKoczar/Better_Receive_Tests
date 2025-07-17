import AnalyticsKit
import LoggingKit
import Neptune
import TWFoundation
import WiseCore

final class AccountDetailsTipsFlow {
    var flowHandler: FlowHandler<Void> = .empty

    private let profileId: ProfileId
    private let accountDetailsId: AccountDetailsId
    private let currencyCode: CurrencyCode
    private let navigationController: UINavigationController
    private let presenterFactory: ViewControllerPresenterFactory
    private let flowTracker: AnalyticsFlowTrackerImpl<AccountDetailsTipsFlowAnalytics>
    private let urlOpener: UrlOpener
    private let articleFactory: HelpCenterArticleFactory

    private lazy var pushPresenter: ViewControllerPresenter = presenterFactory.makePushPresenter(
        navigationController: navigationController
    )

    private var dismisser: ViewControllerDismisser?
    private var articleFlow: (any Flow<Void>)?

    init(
        profileId: ProfileId,
        accountDetailsId: AccountDetailsId,
        currencyCode: CurrencyCode,
        navigationController: UINavigationController,
        articleFactory: HelpCenterArticleFactory,
        presenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl(),
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        urlOpener: UrlOpener = UIApplication.shared
    ) {
        self.profileId = profileId
        self.accountDetailsId = accountDetailsId
        self.currencyCode = currencyCode
        self.navigationController = navigationController
        self.presenterFactory = presenterFactory
        flowTracker = .init(
            contextIdentity: AccountDetailsTipsFlowAnalytics.identity,
            analyticsTracker: analyticsTracker
        )
        self.urlOpener = urlOpener
        self.articleFactory = articleFactory
    }
}

// MARK: - Flow

extension AccountDetailsTipsFlow: Flow {
    func start() {
        flowTracker.register([AccountDetailsTipsFlowAnalytics.CurrencyProperty(currencyCode: currencyCode)])
        flowTracker.trackFlow(.started)
        flowHandler.flowStarted()

        let presenter = AccountDetailsTipsPresenterImpl(
            profileId: profileId,
            accountDetailsId: accountDetailsId,
            flowTracker: flowTracker,
            router: self
        )
        let viewController = AccountDetailsTipsViewController(presenter: presenter)
        dismisser = pushPresenter.present(viewController: viewController)
    }

    func terminate() {
        flowTracker.trackFlow(.finished)
        flowHandler.flowFinished(result: (), dismisser: dismisser)
    }
}

// MARK: - AccountDetailsTipsRouter

extension AccountDetailsTipsFlow: AccountDetailsTipsRouter {
    func open(url: URL) {
        guard let articleId = articleFactory.isArticleLink(url: url) else {
            if urlOpener.canOpenURL(url) {
                urlOpener.open(url)
            } else {
                softFailure("Unable to open URL for Wise protection")
            }
            return
        }

        startArticleFlow(articleId: articleId)
    }

    private func startArticleFlow(articleId: HelpCenterArticleId) {
        let flow = articleFactory.makeArticleFlow(
            hostController: navigationController,
            articleId: articleId
        )
        flow.onFinish { [weak self] _, dismisser in
            self?.articleFlow = nil
            dismisser?.dismiss()
        }
        flow.start()
        articleFlow = flow
    }

    func dismiss() {
        terminate()
    }
}
