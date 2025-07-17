import Combine
import CombineSchedulers
import ContactsKit
import LoggingKit
import Neptune
import RecipientsKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit

final class WisetagScannedProfileFlow: Flow {
    var flowHandler: FlowHandler<Void> = .empty

    private let profile: Profile
    private let nickname: String
    private weak var navigationController: UINavigationController?
    private weak var lookupContactFailureBottomSheet: UIViewController?
    private let requestMoneyFlowFactory: RequestMoneyFlowFactory
    private let transferFlowFactory: WisetagScannedProfileTransferFlowFactory
    private let viewControllerFactory: WisetagScannedProfileViewControllerFactory
    private let bottomSheetPresenter: BottomSheetPresenter
    private let wisetagContactInteractor: WisetagContactInteractor
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let userProvider: UserProvider
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var fetchProfileCancellable: AnyCancellable?
    private var bottomSheetDismisser: BottomSheetDismisser?
    private var requestFlow: (any Flow<Void>)?

    init(
        profile: Profile,
        nickname: String,
        navigationController: UINavigationController,
        requestMoneyFlowFactory: RequestMoneyFlowFactory,
        transferFlowFactory: WisetagScannedProfileTransferFlowFactory,
        viewControllerFactory: WisetagScannedProfileViewControllerFactory,
        viewControllerPresenterFactory: ViewControllerPresenterFactory,
        wisetagContactInteractor: WisetagContactInteractor,
        webViewControllerFactory: WebViewControllerFactory.Type,
        userProvider: UserProvider = GOS[UserProviderKey.self],
        scheduler: AnySchedulerOf<DispatchQueue>
    ) {
        self.profile = profile
        self.nickname = nickname
        self.navigationController = navigationController
        self.requestMoneyFlowFactory = requestMoneyFlowFactory
        self.transferFlowFactory = transferFlowFactory
        self.viewControllerFactory = viewControllerFactory
        self.wisetagContactInteractor = wisetagContactInteractor
        self.webViewControllerFactory = webViewControllerFactory
        self.userProvider = userProvider
        self.scheduler = scheduler

        bottomSheetPresenter = viewControllerPresenterFactory.makeBottomSheetPresenter(parent: navigationController)
    }

    func start() {
        fetchProfileCancellable = wisetagContactInteractor.lookupContact(profileId: profile.id, nickname: nickname)
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                switch result {
                case let .success(contactSearch):
                    if contactSearch.pageType == .business {
                        startBusinessFlow()
                    } else {
                        startPersonalFlow(contactSearch)
                    }
                case .failure:
                    let controller = BottomSheetViewController.makeErrorSheet(viewModel: ErrorViewModel(
                        illustrationConfiguration: .warning,
                        title: L10n.Generic.Error.title,
                        message: .text(L10n.Generic.Error.message),
                        primaryViewModel: .dismiss { [weak self] in
                            self?.lookupContactFailureBottomSheet?.dismiss(animated: UIView.shouldAnimate)
                        }
                    ))

                    navigationController?.presentBottomSheet(controller)
                    lookupContactFailureBottomSheet = controller
                }
            }
    }

    func startPersonalFlow(_ contactSearch: ContactSearch) {
        let (viewController, presenter) = viewControllerFactory.makeScannedProfile(
            profile: profile,
            nickname: nickname,
            contactSearch: contactSearch,
            router: self
        )
        bottomSheetDismisser = bottomSheetPresenter.present(
            viewController: viewController,
            completion: nil
        )
        presenter.setBottomSheet(bottomSheetDismisser?.bottomSheet)
        flowHandler.flowStarted()
    }

    func startBusinessFlow() {
        guard let profileId = userProvider.activeProfile?.id else {
            softFailure("[REC] Attemp to open web flow without any active profile.")
            return
        }

        let url = makeURLForBusiness(nickname: nickname)
        let webViewController = webViewControllerFactory.make(
            with: url,
            userInfoForAuthentication: (
                userId: userProvider.user.userId,
                profileId: profileId
            )
        )
        webViewController.navigationDelegate = self
        webViewController.modalPresentationStyle = .fullScreen
        navigationController?.present(
            webViewController.navigationWrapped(),
            animated: UIView.shouldAnimate
        )
    }

    func terminate() {
        flowHandler.flowFinished(result: (), dismisser: bottomSheetDismisser)
    }

    private func makeURLForBusiness(nickname: String) -> URL {
        let wisetagURL = Branding.current.url.appendingPathComponent(Constants.bussinessWisetagPath(nickname: nickname))
        let components = URLComponents(url: wisetagURL, resolvingAgainstBaseURL: false)

        guard let url = components?.url else {
            return wisetagURL
        }
        return url
    }

    private enum Constants {
        static func bussinessWisetagPath(nickname: String) -> String {
            "/pay/me/\(nickname)"
        }
    }
}

// MARK: - WisetagScannedProfileRouter

extension WisetagScannedProfileFlow: WisetagScannedProfileRouter {
    func sendMoney(_ resolvedRecipient: RecipientResolved, contactId: String?) {
        bottomSheetDismisser?.dismiss { [weak self] in
            guard let self,
                  let navigationController else {
                softFailure("[REC] Attempt to show send money flow when the primary navigation controller is empty.")
                return
            }
            var resultContactId = contactId
            if case let .balanceRecipient(balanceRecipient) = resolvedRecipient,
               resultContactId.isNil {
                resultContactId = balanceRecipient.profileContactId
            }

            transferFlowFactory.start(
                with: resolvedRecipient,
                contactId: resultContactId,
                onHost: navigationController
            )
        }
    }

    func requestMoney(_ contact: Contact) {
        guard let navigationController,
              let id = contact.id.contactId else {
            softFailure("[REC] Attempt to show request money flow when the primary navigation controller is empty.")
            return
        }

        bottomSheetDismisser?.dismiss { [weak self] in
            guard let self else {
                return
            }
            let requestMoneyContact = RequestMoneyContact(
                id: id,
                title: contact.title,
                subtitle: contact.subtitle,
                hasRequestCapability: true,
                avatarPublisher: contact.avatarPublisher
            )
            let requestMoneyFlow = requestMoneyFlowFactory.makeModalFlowForRecentContact(
                profile: profile,
                contact: requestMoneyContact,
                rootViewController: navigationController
            )
            requestMoneyFlow.onFinish { [weak self] _, dismisser in
                self?.requestFlow = nil
                self?.flowHandler.flowFinished(result: (), dismisser: dismisser)
            }
            requestFlow = requestMoneyFlow
            requestMoneyFlow.start()
        }
    }

    func dismiss() {
        terminate()
    }
}

// MARK: - WebContentViewControllerNavigationDelegate

extension WisetagScannedProfileFlow: WebContentViewControllerNavigationDelegate {
    func navigateToURL(
        viewController: WebContentViewController,
        url: URL?
    ) {}
}
