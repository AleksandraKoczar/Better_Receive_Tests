import DeepLinkKit
import Neptune
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
@preconcurrency import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol HelpCenterArticleFactory {
    func makeArticleFlow(
        hostController: UIViewController,
        articleId: HelpCenterArticleId
    ) -> any Flow<Void>
    func isArticleLink(url: URL) -> HelpCenterArticleId?
}

// sourcery: AutoMockable
protocol AccountDetailsInfoRouter: AnyObject {
    func showBottomSheet(viewModel: AccountDetailsBottomSheetViewModel)
    func showShareSheet(
        with text: String,
        sender: UIView,
        completion: @escaping ((UIActivity.ActivityType?, Bool) -> Void)
    )
    func showShareActions(
        title: String,
        actions: [AccountDetailsShareAction]
    )

    func showShareActionsAccountDetailsV3(
        title: String,
        currencyCode: CurrencyCode,
        actions: [AccountDetailsShareAction]
    )

    func showDownloadPDFSheet(actions: [AccountDetailsV3ShareAction])

    func showDetails(model: DetailedSummaryViewModel)

    func showBottomsheetAccountDetailsV3(
        modal: AccountDetailsV3Modal
    )

    func showSwitcher(viewController: UIViewController)

    func orderReceiveMethod(
        currency: CurrencyCode?,
        profile: Profile
    )

    func queryReceiveMethod(
        currency: CurrencyCode?,
        profile: Profile
    )

    func cleanViewMethodNavigation()

    func showFeedback(
        model: FeedbackViewModel,
        context: FeedbackContext,
        onSuccess: @escaping (() -> Void)
    )

    func showFile(
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate
    )
    func showExplore(
        currencyCode: CurrencyCode,
        profile: Profile
    )
    func showTips(
        profileId: ProfileId,
        accountDetailsId: AccountDetailsId,
        currencyCode: CurrencyCode
    )
    func showDirectDebitsFAQ()
    func dismissBottomSheet(completion: (() -> Void)?)
    func showArticle(url: URL)
    func handleURI(_ uri: URI)
    func showReceiveMethodAliasRegistration(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId
    )
    func present(viewController: UIViewController)
}

final class AccountDetailsInfoRouterImpl {
    private enum Constants {
        static let directDebitHelpArticleId = HelpCenterArticleId(rawValue: "2977956")
        static let deepLinkContext = Context(source: "ReceiveURIHandler")
    }

    private let navigationController: UINavigationController
    private let feedbackService: FeedbackService
    private let receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type
    private let accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type
    private let feedbackFlowFactory: AutoSubmittingFeedbackFlowFactory
    private let orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory
    private let accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory
    private let receiveMethodsDFFlowFactory: ReceiveMethodsDFFlowFactory
    private let articleFactory: HelpCenterArticleFactory
    private let accountDetailsSplitterFactory: AccountDetailsSplitterScreenViewControllerFactory
    private let uriHandler: DeepLinkURIHandler

    private var accountDetailsIntroFlow: (any Flow<AccountDetailsIntroFlowResult>)?
    private var accountDetailsTipsFlow: (any Flow<Void>)?
    private var accountDetailsCreationFlow: (any Flow<ReceiveAccountDetailsCreationFlowResult>)?
    private var articleFlow: (any Flow<Void>)?
    private var activeFeedbackFlow: (any Flow<AutoSubmittingFeedbackFlowResult>)?
    private var receiveMethodsDFFlow: (any Flow<ReceiveMethodsDFFlowResult>)?

    init(
        navigationController: UINavigationController,
        receiveSpaceFactoryType: ReceiveSpaceFactoryProtocol.Type,
        accountDetailsTipsFlowFactoryType: ReceiveAccountDetailsTipsFlowFactory.Type,
        accountDetailsSplitterFactory: AccountDetailsSplitterScreenViewControllerFactory,
        orderAccountDetailsFlowFactory: OrderAccountDetailsFlowFactory,
        accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactory,
        receiveMethodsDFFlowFactory: ReceiveMethodsDFFlowFactory = ReceiveMethodsDFFlowFactoryImpl(),
        feedbackFlowFactory: AutoSubmittingFeedbackFlowFactory,
        articleFactory: HelpCenterArticleFactory,
        feedbackService: FeedbackService,
        uriHandler: DeepLinkURIHandler = GOS[DeepLinkURIHandlerKey.self],
    ) {
        self.navigationController = navigationController
        self.receiveSpaceFactoryType = receiveSpaceFactoryType
        self.accountDetailsTipsFlowFactoryType = accountDetailsTipsFlowFactoryType
        self.accountDetailsSplitterFactory = accountDetailsSplitterFactory
        self.orderAccountDetailsFlowFactory = orderAccountDetailsFlowFactory
        self.accountDetailsCreationFlowFactory = accountDetailsCreationFlowFactory
        self.receiveMethodsDFFlowFactory = receiveMethodsDFFlowFactory
        self.feedbackFlowFactory = feedbackFlowFactory
        self.articleFactory = articleFactory
        self.feedbackService = feedbackService
        self.uriHandler = uriHandler
    }

    private func startArticleFlow(navigationController: UINavigationController, articleId: HelpCenterArticleId) {
        let flow = articleFactory.makeArticleFlow(
            hostController: navigationController,
            articleId: articleId
        )
        flow.onFinish { [weak self] _, dismisser in
            self?.articleFlow = nil
            dismisser?.dismiss()
        }
        articleFlow = flow
        flow.start()
    }
}

extension AccountDetailsInfoRouterImpl: AccountDetailsInfoRouter {
    func cleanViewMethodNavigation() {
        navigationController.presentedViewController?.dismiss(animated: UIView.shouldAnimate, completion: { [weak self] in
            guard let self else { return }

            let copy = navigationController.viewControllers
            guard copy.isNonEmpty, let last = copy.last else { return }

            // Remove all VCs between AccountDetailsV3ListViewController and AccountDetailsV3ViewController
            if let targetIndex = copy.lastIndex(where: { $0 is AccountDetailsV3ListViewController }) {
                let filteredVCs = Array(copy.prefix(targetIndex + 1)) + [last]
                navigationController.setViewControllers(filteredVCs, animated: false)
            }
        })
    }

    func queryReceiveMethod(
        currency: CurrencyCode?,
        profile: Profile
    ) {
        navigationController.presentedViewController?.dismiss(animated: UIView.shouldAnimate, completion: { [weak self] in
            guard let self,
                  let currency else {
                return
            }

            let splitter: UIViewController = accountDetailsSplitterFactory.make(
                profile: profile,
                currency: currency,
                source: .accountDetailsList,
                host: navigationController
            )

            let copy = navigationController.viewControllers
            guard copy.isNonEmpty, copy.last is AccountDetailsV3ViewController else { return }

            // Remove all VCs on top of List and append splitter
            if let targetIndex = copy.lastIndex(where: { $0 is AccountDetailsV3ListViewController }) {
                var filteredVCs = Array(copy.prefix(targetIndex + 1))
                filteredVCs.append(splitter)
                navigationController.setViewControllers(filteredVCs, animated: false)
            }
        })
    }

    func orderReceiveMethod(
        currency: CurrencyCode?,
        profile: Profile
    ) {
        navigationController.presentedViewController?.dismiss(animated: UIView.shouldAnimate, completion: { [weak self] in
            guard let self,
                  let currency else { return }

            let flow = accountDetailsCreationFlowFactory.makeForReceive(
                shouldClearNavigation: true,
                source: .other,
                currencyCode: currency,
                profile: profile,
                navigationHost: navigationController
            )
            flow.onFinish { [weak self] _, dismisser in
                self?.accountDetailsCreationFlow = nil
                dismisser?.dismiss()
            }
            accountDetailsCreationFlow = flow
            flow.start()
        })
    }

    func showSwitcher(viewController: UIViewController) {
        navigationController.present(viewController.navigationWrapped(), animated: UIView.shouldAnimate)
    }

    func showDetails(model: DetailedSummaryViewModel) {
        let vc = SwiftUIHostingController {
            KeyInformationDetailsView(model: model)
        }
        navigationController.present(vc.navigationWrapped(), animated: UIView.shouldAnimate)
    }

    func showBottomSheet(viewModel: AccountDetailsBottomSheetViewModel) {
        let vc = AccountDetailsEducationViewControllerFactory.make(model: viewModel)
        navigationController.present(vc.navigationWrapped(), animated: UIView.shouldAnimate)
    }

    func showArticle(url: URL) {
        guard let articleId = articleFactory.isArticleLink(url: url) else {
            return
        }

        dismissBottomSheet { [weak self] in
            guard let self else { return }
            startArticleFlow(
                navigationController: navigationController,
                articleId: articleId
            )
        }
    }

    func dismissBottomSheet(completion: (() -> Void)?) {
        navigationController.presentedViewController?.dismiss(animated: UIView.shouldAnimate, completion: completion)
    }

    func showShareSheet(
        with text: String,
        sender: UIView,
        completion: @escaping ((UIActivity.ActivityType?, Bool) -> Void)
    ) {
        let sharingController = UIActivityViewController.universalSharingController(
            forItems: [text],
            sourceView: sender
        ) { activityType, completed, _, _ in
            completion(activityType, completed)
        }
        navigationController.present(sharingController, animated: UIView.shouldAnimate)
    }

    func showShareActions(title: String, actions: [AccountDetailsShareAction]) {
        let items = actions.map {
            OptionViewModel(
                title: $0.title,
                avatar: AvatarViewModel.icon(
                    $0.image
                )
            )
        }

        navigationController.presentNavigationOptionsSheet(
            items: items,
            handler: { index, _ in
                actions[index].handler()
            }
        )
    }

    func showShareActionsAccountDetailsV3(
        title: String,
        currencyCode: CurrencyCode,
        actions: [AccountDetailsShareAction]
    ) {
        let items = actions.map {
            OptionViewModel(
                title: $0.title,
                avatar: AvatarViewModel.icon(
                    $0.image
                )
            )
        }

        navigationController.presentNavigationOptionsSheet(
            title: L10n.AccountDetailsV3.Share.Sheet.title(currencyCode.value),
            subtitle: L10n.AccountDetailsV3.Share.Sheet.subtitle,
            items: items,
            handler: { index, _ in
                actions[index].handler()
            }
        )
    }

    func showDownloadPDFSheet(actions: [AccountDetailsV3ShareAction]) {
        let items = actions.map {
            OptionViewModel(
                title: $0.title,
                subtitle: $0.subtitle
            )
        }

        navigationController.presentNavigationOptionsSheet(
            title: L10n.AccountDetailsV3.Share.Pdf.Download.title,
            subtitle: L10n.AccountDetailsV3.Share.Pdf.Download.subtitle,
            items: items,
            handler: { index, _ in
                actions[index].handler()
            }
        )
    }

    func showBottomsheetAccountDetailsV3(
        modal: AccountDetailsV3Modal
    ) {
        let action: Action? = {
            guard let button = modal.button, let url = URL(string: button.value) else { return nil }
            return Action(
                title: button.title,
                handler: { [weak self] in
                    guard let self else { return }
                    showArticle(url: url)
                }
            )
        }()

        let markdownBody: MarkdownLabel = {
            let markdown = MarkdownLabel()
            markdown.numberOfLines = 0
            markdown.setMarkdownText(modal.body.text)
            markdown.linkActionHandler = { [weak self] urlString in
                guard let url = URL(string: urlString) else { return }
                self?.showArticle(url: url)
            }
            return markdown
        }()

        let viewModel = AccountDetailsV3EducationViewModel(
            title: modal.title,
            body: markdownBody,
            action: action
        )

        let vc = AccountDetailsV3EducationViewController(model: viewModel)
        navigationController.present(vc.navigationWrapped(), animated: UIView.shouldAnimate)
    }

    func showFeedback(
        model: FeedbackViewModel,
        context: FeedbackContext,
        onSuccess: @escaping (() -> Void)
    ) {
        let flow = feedbackFlowFactory.make(
            viewModel: model,
            context: context,
            service: feedbackService,
            hostController: navigationController,
            additionalProperties: nil
        )
        flow.onFinish { [weak self] result, dismisser in
            dismisser?.dismiss()
            if result == .success {
                onSuccess()
            }
            self?.activeFeedbackFlow = nil
        }
        activeFeedbackFlow = flow
        flow.start()
    }

    func showFile(
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate
    ) {
        let interactionController = UIDocumentInteractionController(url: url)
        interactionController.name = ""
        interactionController.delegate = delegate
        interactionController.presentPreview(animated: UIView.shouldAnimate)
    }

    func showExplore(
        currencyCode: CurrencyCode,
        profile: Profile
    ) {
        accountDetailsIntroFlow = AccountDetailsIntroFlowFactory.make(
            origin: .accountDetails,
            shouldShowDetailsSummary: false,
            navigationHost: navigationController,
            currencyCode: currencyCode,
            profile: profile,
            receiveSpaceFactoryType: receiveSpaceFactoryType,
            accountDetailsTipsFlowFactoryType: accountDetailsTipsFlowFactoryType,
            orderAccountDetailsFlowFactory: orderAccountDetailsFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            feedbackService: feedbackService,
            articleFactory: articleFactory
        )
        accountDetailsIntroFlow?.onFinish { [weak self] _, dismisser in
            dismisser?.dismiss()
            self?.accountDetailsIntroFlow = nil
        }
        accountDetailsIntroFlow?.start()
    }

    func showTips(
        profileId: ProfileId,
        accountDetailsId: AccountDetailsId,
        currencyCode: CurrencyCode
    ) {
        let accountDetailsTipsFlowController = TWNavigationController()
        accountDetailsTipsFlowController.modalPresentationStyle = .fullScreen
        let flow = accountDetailsTipsFlowFactoryType.make(
            navigationController: accountDetailsTipsFlowController,
            profileId: profileId,
            accountDetailsId: accountDetailsId,
            currencyCode: currencyCode,
            articleFactory: articleFactory
        )
        accountDetailsTipsFlow = ModalPresentationFlow(
            flow: flow,
            rootViewController: navigationController,
            flowController: accountDetailsTipsFlowController
        )
        accountDetailsTipsFlow?.onFinish { [weak self] _, dismisser in
            dismisser?.dismiss()
            self?.accountDetailsTipsFlow = nil
        }
        accountDetailsTipsFlow?.start()
    }

    func showDirectDebitsFAQ() {
        startArticleFlow(navigationController: navigationController, articleId: Constants.directDebitHelpArticleId)
    }

    func handleURI(_ uri: URI) {
        uriHandler.handleURI(
            uri,
            deepLinkContext: .receiveURIHandler,
            hostController: navigationController
        )
    }

    func showReceiveMethodAliasRegistration(
        accountDetailsId: AccountDetailsId,
        profileId: ProfileId
    ) {
        let flow = receiveMethodsDFFlowFactory.make(
            mode: .register,
            accountDetailsId: accountDetailsId,
            profileId: profileId,
            hostViewController: navigationController
        )
        flow.onFinish { [weak self] _, dismisser in
            dismisser?.dismiss()
            self?.receiveMethodsDFFlow = nil
        }
        receiveMethodsDFFlow = flow
        flow.start()
    }

    func present(viewController: UIViewController) {
        navigationController.present(viewController, animated: UIView.shouldAnimate)
    }
}
