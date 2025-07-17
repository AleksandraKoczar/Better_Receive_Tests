import Combine
import CombineSchedulers
import DeepLinkKit
import LoggingKit
import Neptune
import Prism
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit

private enum QuickpayError: Error {
    case notEligible
    case deallocated
    case fetchingLinkError(error: String?)
    case updateLinkError(error: String?)
    case fetchingQRCodeError(error: String?)
}

// sourcery: AutoMockable
protocol QuickpayShareableLinkStatusUpdater: AnyObject {
    func updateShareableLinkStatus(isDiscoverable: Bool)
}

// sourcery: AutoMockable
protocol QuickpayPresenter: AnyObject {
    func start(with view: QuickpayView)
    func dismiss()
}

final class QuickpayPresenterImpl {
    private let profile: Profile
    private let wisetagInteractor: WisetagInteractor
    private let quickpayUseCase: QuickpayUseCase
    private let viewModelMapper: QuickpayViewModelMapper
    private let router: QuickpayRouter
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let pasteboard: Pasteboard
    private let featureService: FeatureService
    private let analyticsTracker: BusinessProfileLinkTracking

    private weak var view: QuickpayView?
    private var status: ShareableLinkStatus = .ineligible
    private var image: UIImage?
    private var isCardsEnabled = false
    private var forms: [PaymentMethodDynamicForm] = []
    private var fetchDataCancellable: AnyCancellable?
    private var updateShareableLinkStatusCancellable: AnyCancellable?

    init(
        profile: Profile,
        quickpayUseCase: QuickpayUseCase,
        wisetagInteractor: WisetagInteractor,
        viewModelMapper: QuickpayViewModelMapper,
        router: QuickpayRouter,
        analyticsTracker: BusinessProfileLinkTracking,
        pasteboard: Pasteboard,
        featureService: FeatureService,
        scheduler: AnySchedulerOf<DispatchQueue>
    ) {
        self.profile = profile
        self.quickpayUseCase = quickpayUseCase
        self.wisetagInteractor = wisetagInteractor
        self.viewModelMapper = viewModelMapper
        self.router = router
        self.analyticsTracker = analyticsTracker
        self.pasteboard = pasteboard
        self.featureService = featureService
        self.scheduler = scheduler
    }
}

// MARK: - QuickpayPresenter

extension QuickpayPresenterImpl: QuickpayPresenter {
    func start(with view: QuickpayView) {
        self.view = view
        fetchData()
    }

    func fetchData() {
        view?.showHud()
        fetchDataCancellable = wisetagInteractor.fetchNextStep()
            .combineLatest(wisetagInteractor.fetchCardDynamicForms())
            .mapError { error in QuickpayError.fetchingLinkError(error: error.localizedDescription) }
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                view?.hideHud()
                switch result {
                case let .success((nextStep, forms)):
                    self.forms = forms
                    showNextStep(step: nextStep)
                case let .failure(error):
                    showError(error: error)
                    trackOnLoadedFailure(error: error)
                }
            }
    }

    func dismiss() {
        router.dismiss(isShareableLinkDiscoverable: isDiscoverable())
    }
}

private extension QuickpayPresenterImpl {
    func showNextStep(step: WisetagNextStep) {
        switch step {
        case .showADFlow:
            guard let viewController = view as? UIViewController else {
                return
            }
            router.startAccountDetailsFlow(host: viewController)
            analyticsTracker.onOpeningAccountDetailsFlow()
        case let .showWisetag(image: image, status: status, isCardsEnabled: isCardsEnabled):
            self.status = status
            self.image = image
            self.isCardsEnabled = isCardsEnabled

            if featureService.isOn(ReceiveKitFeatures.quickpayToInPersonExperiment) {
                personaliseTapped()
            } else {
                configureView(
                    status: status,
                    qrCodeImage: image,
                    isCardsEnabled: isCardsEnabled,
                    nudge: makeNudge()
                )
                analyticsTracker.onLoaded(success: true, error: "NO", discoverable: isDiscoverable(), eligible: true)
            }
        case .showStory:
            if featureService.isOn(ReceiveKitFeatures.quickpayToInPersonExperiment) {
                router.showInPersonStory()
            } else {
                let deepLinkComponents = DeepLinkComponents.urn(Constants.componentsIntro)
                guard let route = DeepLinkStoryRouteImpl(components: deepLinkComponents) else { return }
                router.showIntroStory(route: route)
            }
        }
    }
}

// MARK: Quickpay Data pipeline

private extension QuickpayPresenterImpl {
    func configureView(
        status: ShareableLinkStatus,
        qrCodeImage: UIImage?,
        isCardsEnabled: Bool,
        nudge: NudgeViewModel?
    ) {
        guard case let .eligible(discoverability) = status else {
            return
        }

        let viewModel = viewModelMapper.make(
            status: discoverability,
            profile: profile,
            qrCodeImage: qrCodeImage,
            isCardsEnabled: isCardsEnabled,
            nudge: nudge,
            delegate: self
        )
        view?.configure(with: viewModel)
    }

    func getNickname() -> String? {
        guard case let .eligible(discoverability) = status,
              case let .discoverable(_, nickname) = discoverability else {
            return nil
        }
        /* nickname is returned with @ character. We should remove it to create a valid link */
        return String(nickname.dropFirst())
    }

    func isDiscoverable() -> Bool {
        guard case let .eligible(discoverability) = status,
              case .discoverable = discoverability else {
            return false
        }
        return true
    }

    func trackOnLoadedFailure(error: QuickpayError) {
        var isEligible = true
        var errorString: String?
        switch error {
        case .notEligible:
            isEligible = false
            errorString = "User is not eligible for quickpay"
        case .deallocated:
            break
        case .fetchingLinkError:
            errorString = "Fetching link error"
        case .fetchingQRCodeError:
            errorString = "Fetching qr code error"
        case .updateLinkError:
            errorString = "Update link error"
        }
        analyticsTracker.onLoaded(success: false, error: errorString, discoverable: isDiscoverable(), eligible: isEligible)
    }

    func showError(error: QuickpayError) {
        switch error {
        case .notEligible:
            let errorViewModel = ErrorViewModel(
                illustrationConfiguration: .warning,
                title: L10n.Quickpay.Error.NotEligible.title,
                message: .text(L10n.Quickpay.Error.NotEligible.subtitle),
                primaryViewModel: .done { [weak self] in
                    self?.dismiss()
                }
            )
            view?.configureWithError(with: errorViewModel)
        case .deallocated:
            break
        case .fetchingLinkError,
             .fetchingQRCodeError:
            let errorViewModel = ErrorViewModel(
                illustrationConfiguration: .warning,
                title: NeptuneLocalization.ErrorView.NetworkError.title,
                message: .text(NeptuneLocalization.ErrorView.NetworkError.message),
                primaryViewModel: .tryAgain { [weak self] in
                    self?.fetchData()
                }
            )
            view?.configureWithError(with: errorViewModel)
        case .updateLinkError:
            let errorViewModel = ErrorViewModel(
                illustrationConfiguration: .warning,
                title: NeptuneLocalization.ErrorView.NetworkError.title,
                message: .text(NeptuneLocalization.ErrorView.NetworkError.message),
                primaryViewModel: .tryAgain { [weak self] in
                    guard let self else { return }
                    updateShareableLinkStatus(isDiscoverable: isDiscoverable())
                }
            )

            view?.configureWithError(with: errorViewModel)
        }
    }

    enum Constants {
        static let componentsIntro = DeepLinkURNComponents(
            path: ["stories", "notifications", "wisetagbiz"]
        )
    }
}

// MARK: QuickpayViewModelDelegate

extension QuickpayPresenterImpl: QuickpayViewModelDelegate {
    func giveFeedbackTapped() {
        let model = FeedbackViewModel(
            title: L10n.Quickpay.Feedback.title,
            description: L10n.Quickpay.Feedback.description,
            ratingMode: .sevenScale(legend: .range(
                min: L10n.Quickpay.Feedback.Form.minValue,
                max: L10n.Quickpay.Feedback.Form.maxValue
            )),
            placeholder: L10n.Balance.Shared.Feedback.placeholder,
            submitButtonTitle: L10n.Quickpay.Feedback.Form.submit
        )
        let context = FeedbackContext(
            feature: "QUICKPAY_QUALITY_SURVEY",
            pageName: nil,
            profileId: profile.id
        )

        router.showFeedback(
            model: model,
            context: context,
            onSuccess: { [weak self] in
                guard let self else {
                    return
                }
                view?.showSnackbar(message: L10n.Quickpay.Feedback.successMessage)
            }
        )
    }

    func shareTapped() {
        guard let urlString = getUrlString() else {
            softFailure("[REC] Attempt to share non-existing urlString.")
            return
        }
        router.shareLinkTapped(link: urlString)
    }

    func personaliseTapped() {
        guard case let .eligible(discoverability) = status else {
            return
        }
        router.personaliseTapped(status: discoverability)
        analyticsTracker.onCustomLinkToggled()
    }

    func cardTapped(articleId: String) {
        guard let url = mapArticleIdToUrl(articleId: articleId) else {
            return
        }
        router.showHelpArticle(url: url)
        analyticsTracker.onCarouselArticleOpened(articleId: articleId)
    }

    func mapArticleIdToUrl(articleId: String) -> String? {
        "\(Branding.current.urlString)/help/articles/\(articleId)"
    }

    func showManageQuickpay() {
        router.showManageQuickpay(nickname: getNickname())
        analyticsTracker.onSettingsButton()
    }

    func qrCodeTapped() {
        guard isDiscoverable() else {
            router.showDiscoverability(nickname: getNickname())
            return
        }
        guard let image else { return }
        router.startDownload(image: image)
        analyticsTracker.onQrCodeDownloadButton()
    }

    func linkTapped() {
        guard let urlString = getUrlString() else {
            softFailure("[REC] Attempt to copy non-existing urlString.")
            return
        }
        pasteboard.addToClipboard(urlString)
        let text = L10n.Wisetag.SnackBar.Message.copyLink
        view?.showSnackbar(message: text)
    }

    func getUrlString() -> String? {
        guard case let .eligible(discoverability) = status,
              case let .discoverable(url, _) = discoverability else {
            return nil
        }
        return url
    }

    func footerButtonTapped() {
        updateShareableLinkStatus(isDiscoverable: true)
        analyticsTracker.onActivate()
    }
}

// MARK: - Get Paid with Card Nudge

private extension QuickpayPresenterImpl {
    func onNudgeDismissed(type: CardNudgeType) {
        wisetagInteractor.setShouldShowNudge(false, profileId: profile.id, nudgeType: type)
        view?.updateNudge(nil)
        analyticsTracker.onCardSetupNudgeDismiss()
    }

    func onNudgeSelected(type: CardNudgeType) {
        router.showDynamicFormsMethodManagement(forms, delegate: self)
        analyticsTracker.onCardSetupNudgeOpened()
    }

    func makeNudge() -> NudgeViewModel? {
        guard let flowId = PaymentMethodsDynamicFormId(rawValue: forms.first?.flowId) else {
            return nil
        }

        switch flowId {
        case .acquiringEvidenceCollectionFormId,
             .acquiringOnboardingConsentFormId:
            if wisetagInteractor.shouldShowNudge(profileId: profile.id, nudgeType: .onboarding) {
                analyticsTracker.onCardSetupNudgeViewed()
                return NudgeViewModel(
                    title: L10n.Quickpay.CardOnboardingNudge.title,
                    asset: .globe,
                    ctaTitle: L10n.Quickpay.CardOnboardingNudge.ctaTitle,
                    onSelect: { self.onNudgeSelected(type: .onboarding) },
                    onDismiss: { self.onNudgeDismissed(type: .onboarding) }
                )
            }
        case .waitlistFormId:
            if wisetagInteractor.shouldShowNudge(profileId: profile.id, nudgeType: .waitlist) {
                return NudgeViewModel(
                    title: L10n.Quickpay.CardWaitlistNudge.title,
                    asset: .globe,
                    ctaTitle: L10n.Quickpay.CardWaitlistNudge.ctaTitle,
                    onSelect: { self.onNudgeSelected(type: .waitlist) },
                    onDismiss: { self.onNudgeDismissed(type: .waitlist) }
                )
            }
        }
        return nil
    }
}

// MARK: - PaymentMethodsDelegate

extension QuickpayPresenterImpl: PaymentMethodsDelegate {
    func refreshPaymentMethods() {
        fetchData()
    }

    func trackDynamicFlowFailed() {
        // TODO: trackDFFailed once prism is ready
    }
}

// MARK: - QuickpayShareableLinkStatusUpdater

extension QuickpayPresenterImpl: QuickpayShareableLinkStatusUpdater {
    func updateShareableLinkStatus(isDiscoverable: Bool) {
        view?.showHud()
        updateShareableLinkStatusCancellable = wisetagInteractor.updateShareableLinkStatus(
            profileId: profile.id,
            isDiscoverable: isDiscoverable
        )
        .mapError { error in QuickpayError.updateLinkError(error: error.localizedDescription) }
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else {
                return
            }
            view?.hideHud()
            switch result {
            case let .success((status, image)):
                self.status = status
                configureView(
                    status: status,
                    qrCodeImage: image,
                    isCardsEnabled: isCardsEnabled,
                    nudge: makeNudge()
                )
            case let .failure(error):
                showError(error: error)
            }
        }
    }
}
