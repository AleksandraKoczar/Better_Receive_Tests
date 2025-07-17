import AnalyticsKit
import ApiKit
import BalanceKit
import Combine
import CombineSchedulers
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

protocol AccountDetailsV2Presenter: AccountDetailsV2ViewActionDelegate, AnyObject {
    func start(with view: AccountDetailsInfoV2View)
    func showExplore()
    func dismiss()
}

final class AccountDetailsV2PresenterImpl {
    private weak var view: AccountDetailsInfoV2View?

    private let router: AccountDetailsInfoRouter
    private let accountDetailsUseCase: AccountDetailsUseCase
    private let payerPDFUseCase: AccountDetailsPayerPDFUseCase
    private let pasteboard: Pasteboard
    private let profile: Profile
    private let accountDetailsId: AccountDetailsId
    private let accountDetailsType: AccountDetailsType
    private var activeAccountDetails: ActiveAccountDetails?
    private let analyticsTracker: AnalyticsTracker
    private let analyticsProvider: AccountDetailsAnalyticsProvider
    private let invocationSource: AccountDetailsInfoInvocationSource
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var refreshCount = 0
    private var completion: (() -> Void)?

    private var accountDetailsCancellable: AnyCancellable?
    private var payerPDFAvailabilityCancellable: AnyCancellable?
    private var payerPDFDownloadCancellable: AnyCancellable?
    private var screenshotListeningCancellable: AnyCancellable?

    private var isPayerPDFAvailable = false
    private var selectedSegmentIndex = 0

    init(
        router: AccountDetailsInfoRouter,
        accountDetailsUseCase: AccountDetailsUseCase,
        payerPDFUseCase: AccountDetailsPayerPDFUseCase,
        profile: Profile,
        accountDetailsId: AccountDetailsId,
        accountDetailsType: AccountDetailsType,
        pasteboard: Pasteboard = UIPasteboard.general,
        activeAccountDetails: ActiveAccountDetails?,
        invocationSource: AccountDetailsInfoInvocationSource,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        analyticsProvider: AccountDetailsAnalyticsProvider,
        notificationCenter: NotificationCenter = .default,
        scheduler: AnySchedulerOf<DispatchQueue> = .main,
        completion: (() -> Void)? = nil
    ) {
        self.router = router
        self.accountDetailsUseCase = accountDetailsUseCase
        self.payerPDFUseCase = payerPDFUseCase
        self.profile = profile
        self.accountDetailsId = accountDetailsId
        self.accountDetailsType = accountDetailsType
        self.activeAccountDetails = activeAccountDetails
        self.pasteboard = pasteboard
        self.analyticsTracker = analyticsTracker
        self.scheduler = scheduler
        self.invocationSource = invocationSource
        self.completion = completion
        self.analyticsProvider = analyticsProvider

        screenshotListeningCancellable =
            notificationCenter.publisher(for: UIApplication.userDidTakeScreenshotNotification)
                .sink { [weak self] _ in
                    self?.screenshotTaken()
                }
    }
}

// MARK: - AccountDetailsV2Presenter

extension AccountDetailsV2PresenterImpl: AccountDetailsV2Presenter {
    func start(with view: AccountDetailsInfoV2View) {
        self.view = view
        checkPayerPDFAvailability()

        if let activeAccountDetails {
            configureViewModel(with: activeAccountDetails)
        } else {
            startObserving(for: accountDetailsId)
        }

        analyticsTracker.track(
            screen: analyticsProvider.pageShown(
                accountDetailsId: accountDetailsId,
                currencyCode: activeAccountDetails?.currency,
                invocationSource: invocationSource,
                context: accountDetailsType
            )
        )
    }

    func showExplore() {
        guard let activeAccountDetails else {
            softFailure("showExplore missing required bank details")
            return
        }

        analyticsTracker.track(
            event: analyticsProvider.exploreButtonTapped(
                activeAccountDetails.currency
            )
        )
        router.showExplore(
            currencyCode: activeAccountDetails.currency,
            profile: profile
        )
    }

    func dismiss() {
        completion?()
    }
}

// MARK: - AccountDetailsInfoModalDelegate

extension AccountDetailsV2PresenterImpl: AccountDetailsInfoModalDelegate {
    func copyAccountDetails(
        _ copyText: String,
        for fieldName: String,
        analyticsType: String?
    ) {
        let event: AnalyticsEventItem? = {
            guard let activeAccountDetails else { return nil }
            return analyticsProvider.copyButtonTapped(
                activeAccountDetails.currency,
                analyticsType: analyticsType
            )
        }()

        copy(
            content: copyText,
            fieldName: fieldName,
            analyticsEvent: event
        )
    }

    func showInformationModal(title: String?, description: String?, analyticsType: String?) {
        let model = AccountDetailsBottomSheetViewModel(
            title: title,
            description: description
        ) { [weak self] url in
            self?.router.showArticle(url: url)
        }
        router.showBottomSheet(viewModel: model)

        analyticsTracker.track(
            event: analyticsProvider.summaryDescriptionShown(
                analyticsType
            )
        )
    }

    func showCopyableModal(accountDetailItem: AccountDetailsDetailItem) {
        guard let description = accountDetailItem.description else {
            softFailure("We should only have a description to call this method")
            return
        }

        var footerConfig: AccountDetailsBottomSheetViewModel.CopyConfig?
        if let cta = accountDetailItem.description?.cta {
            let copyConfigTitle: String
            let copyConfigType: AccountDetailsBottomSheetViewModel.CopyConfig.FooterType
            if accountDetailItem.shouldObfuscate {
                copyConfigTitle = accountDetailItem.title
                copyConfigType = .revealed
            } else {
                copyConfigTitle = L10n.AccountDetails.Info.Details.Copy.Button.title(cta.label)
                copyConfigType = .plainText
            }

            footerConfig = AccountDetailsBottomSheetViewModel.CopyConfig(
                type: copyConfigType,
                title: copyConfigTitle,
                value: cta.content,
                copyAction: { [weak self] in
                    guard let self else { return }
                    router.dismissBottomSheet(completion: nil)
                    copy(
                        content: cta.content,
                        fieldName: cta.label,
                        analyticsEvent: analyticsProvider.modalCopied(
                            accountDetailItem.analyticsType
                        )
                    )
                }
            )
        }

        let model = AccountDetailsBottomSheetViewModel(
            title: description.title,
            description: description.body,
            footerConfig: footerConfig
        )

        router.showBottomSheet(viewModel: model)

        analyticsTracker.track(
            event: analyticsProvider.modalShown(
                accountDetailItem.analyticsType
            )
        )
    }

    func shareAccountDetails(shareText: String, sender: UIView?) {
        let shareActions: [AccountDetailsShareAction] = createShareActions(
            shareText: shareText,
            sender: sender
        )

        router.showShareActions(
            title: L10n.AccountDetails.Share.Sheet.title,
            actions: shareActions
        )

        if let activeAccountDetails {
            analyticsTracker.track(
                event: analyticsProvider.shareActionSheetShown(
                    activeAccountDetails.currency
                )
            )
        }
    }
}

// MARK: - AccountDetailsV2ViewActionDelegate

extension AccountDetailsV2PresenterImpl: AccountDetailsV2ViewActionDelegate {
    func view(
        _ view: AccountDetailsV2View,
        didChangeSegmentIndexTo index: Int,
        type: AccountDetailsReceiveOptionReceiveType?
    ) {
        selectedSegmentIndex = index
        analyticsTracker.track(
            event: analyticsProvider.tabChanged(
                type?.caseNameId
            )
        )
    }
}

// MARK: - Data Helpers

private extension AccountDetailsV2PresenterImpl {
    func startObserving(for accountDetailsId: AccountDetailsId) {
        accountDetailsCancellable = accountDetailsUseCase.accountDetails
            .handleEvents(receiveOutput: { [weak self] state in
                if state == nil {
                    self?.accountDetailsUseCase.refreshAccountDetails()
                }
            })
            .compactMap { $0 }
            .receive(on: scheduler)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .loading:
                    showLoading(loading: true)

                case let .loaded(accountDetails):
                    showLoading(loading: false)

                    guard let activeAccountDetails = accountDetails
                        .activeDetails()
                        .first(where: {
                            $0.id == accountDetailsId
                        }) else {
                        showError()
                        softFailure("[REC]: Mismatch on account details")
                        return
                    }

                    updateViewIfRequired(activeAccountDetails: activeAccountDetails)

                case .recoverableError:
                    showLoading(loading: false)
                    showError()
                }
            }
    }

    func checkPayerPDFAvailability() {
        guard let id = activeAccountDetails?.id else { return }
        payerPDFAvailabilityCancellable = payerPDFUseCase.checkAvailability(
            accountDetailsId: id,
            profileId: profile.id
        )
        .receive(on: scheduler)
        .sink { result in
            switch result {
            case .initial,
                 .loading:
                return
            case let .content(isPayerPDFAvailable, _):
                self.isPayerPDFAvailable = isPayerPDFAvailable
            case .error:
                self.isPayerPDFAvailable = false
            }
        }
    }

    func downloadPayerPDF() {
        guard let id = activeAccountDetails?.id else { return }

        showLoading(loading: true)

        payerPDFDownloadCancellable = payerPDFUseCase.pdf(
            accountDetailsId: id,
            profileId: profile.id
        )
        .receive(on: scheduler)
        .asResult()
        .sink { [weak self] result in
            guard let self,
                  let view else {
                return
            }
            showLoading(loading: false)
            switch result {
            case let .success(url):
                router.showFile(
                    url: url,
                    delegate: view.documentInteractionControllerDelegate
                )
                if let activeAccountDetails {
                    analyticsTracker.track(
                        event: analyticsProvider.pdfShared(
                            activeAccountDetails.currency
                        )
                    )
                }
            case let .failure(error):
                view.showErrorAlert(
                    title: L10n.Balance.Details.AccountDetails.Error.title,
                    message: error.localizedDescription
                )
            }
        }
    }
}

// MARK: - Helpers

private extension AccountDetailsV2PresenterImpl {
    func createShareActions(shareText: String, sender: UIView?) -> [AccountDetailsShareAction] {
        guard let currencyCode = activeAccountDetails?.currency else {
            return []
        }
        var actions: [AccountDetailsShareAction] = [
            AccountDetailsShareAction(
                title: L10n.AccountDetails.Share.Sheet.Items.copyDetails,
                image: Icons.documents.image,
                handler: { [weak self] in
                    guard let self else { return }
                    pasteboard.addToClipboard(shareText)
                    view?.generateHapticFeedback()
                    view?.showConfirmation(
                        message: L10n.AccountDetails.Info.Details.Copy.Snack.AccountDetails.Copied.message
                    )
                    analyticsTracker.track(
                        event: analyticsProvider.copiedFromActionSheet(
                            currencyCode
                        )
                    )
                }
            ),
            AccountDetailsShareAction(
                title: L10n.AccountDetails.Share.Sheet.Items.shareToContact,
                image: Icons.shareIos.image,
                handler: { [weak self] in
                    guard let self,
                          let sender else {
                        return
                    }
                    router.showShareSheet(
                        with: shareText,
                        sender: sender,
                        completion: { [weak self] activityType, isCompleted in
                            guard let self else { return }
                            analyticsTracker.track(
                                event: analyticsProvider.sharedViaShareSheet(
                                    currencyCode: currencyCode,
                                    activityType: activityType?.rawValue ?? "",
                                    isCompleted: isCompleted
                                )
                            )
                        }
                    )
                    analyticsTracker.track(
                        event: analyticsProvider.shareSheetShown(
                            currencyCode
                        )
                    )
                }
            ),
        ]
        guard isPayerPDFAvailable else {
            return actions
        }
        actions.append(
            AccountDetailsShareAction(
                title: L10n.AccountDetails.Share.Sheet.Items.shareViaPDF,
                image: Icons.paperclip.image,
                handler: { [weak self] in
                    self?.downloadPayerPDF()
                }
            )
        )
        return actions
    }

    func showTips() {
        guard let activeAccountDetails else {
            softFailure("[REC]: showTips missing required bank details")
            return
        }

        router.showTips(
            profileId: profile.id,
            accountDetailsId: activeAccountDetails.id,
            currencyCode: activeAccountDetails.currency
        )
    }

    func updateViewIfRequired(activeAccountDetails: ActiveAccountDetails) {
        if self.activeAccountDetails != activeAccountDetails {
            self.activeAccountDetails = activeAccountDetails
            configureViewModel(with: activeAccountDetails)
        }
    }

    func showLoading(loading: Bool) {
        if loading {
            view?.showHud()
        } else {
            view?.hideHud()
        }
    }

    func showError() {
        view?.showError(
            title: L10n.Balance.Details.AccountDetails.Error.title,
            message: L10n.Balance.Details.AccountDetails.Error.message,
            leftAction: AlertAction(message: L10n.Balance.Details.AccountDetails.Error.retry, action: { [weak self] in
                self?.accountDetailsUseCase.refreshAccountDetails()
            }),
            rightActionTitle: L10n.Balance.Details.AccountDetails.Error.back
        )
    }

    func configureViewModel(with activeAccountDetails: ActiveAccountDetails) {
        let isExploreEnabled = profile.type == .personal && {
            switch accountDetailsType {
            case .standard:
                true
            case .directDebit:
                false
            }
        }()

        let viewModel = AccountDetailsV2ViewModel(
            title: activeAccountDetails.title,
            currency: activeAccountDetails.currency,
            activeAccountDetails: activeAccountDetails,
            modalDelegate: self,
            accountDetailsType: accountDetailsType,
            isExploreEnabled: isExploreEnabled,
            nudgeSelectAction: { [weak self] in
                guard let self else { return }
                switch accountDetailsType {
                case .directDebit:
                    router.showDirectDebitsFAQ()
                case .standard:
                    showTips()
                }
            },
            alertAction: { [weak self] uriString in
                self?.handleURI(string: uriString)
            }
        )

        view?.configure(with: viewModel)
    }

    func copy(
        content: String,
        fieldName: String,
        analyticsEvent: AnalyticsEventItem?
    ) {
        pasteboard.addToClipboard(content)
        view?.generateHapticFeedback()
        view?.showConfirmation(
            message: L10n.AccountDetails.Info.Details.Copy.snack(
                fieldName
            )
        )

        if let analyticsEvent {
            analyticsTracker.track(
                event: analyticsEvent
            )
        }
    }

    func handleURI(string: String) {
        guard let uri = URI(string: string) else {
            softFailure("[REC] Failed to handle URN")
            return
        }

        router.handleURI(uri)
    }

    func screenshotTaken() {
        guard let shareText = activeAccountDetails?
            .receiveOptions[safe: selectedSegmentIndex]?
            .shareText,
            let activeView = view?.activeView else {
            return
        }
        let alert = UIAlertController(
            title: L10n.AccountDetails.Info.Details.Share.Alert.message,
            message: "",
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.AccountDetails.Info.Details.Share.Alert.Message.yes,
                style: .default,
                handler: { [weak self] _ in
                    guard let self else {
                        return
                    }
                    shareAccountDetails(shareText: shareText, sender: activeView)
                }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.AccountDetails.Info.Details.Share.Alert.Message.no,
                style: .cancel
            )
        )

        router.present(viewController: alert)
    }
}
