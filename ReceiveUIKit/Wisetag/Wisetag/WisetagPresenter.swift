import AnalyticsKit
import BalanceKit
import Combine
import CombineSchedulers
import DeepLinkKit
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol WisetagShareableLinkStatusUpdater: AnyObject {
    func updateShareableLinkStatus(isDiscoverable: Bool)
}

// sourcery: AutoMockable
protocol WisetagPresenter: AnyObject {
    func start(with view: WisetagView)
    func dismiss()
    func showDiscoverabilityBottomSheet()
    func copyLinkTapped()
}

private enum WisetagPresenterError: Error {
    case deallocatedSelf
}

final class WisetagPresenterImpl {
    private let shouldBecomeDiscoverable: Bool
    private let profile: Profile
    private let interactor: WisetagInteractor
    private let viewModelMapper: WisetagViewModelMapper
    private let router: WisetagRouter
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<WisetagAnalyticsView>
    private let pasteboard: Pasteboard
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var status: ShareableLinkStatus = .ineligible
    private var image: UIImage?
    private weak var view: WisetagView?

    private var fetchShareableLinkStatusCancellable: AnyCancellable?
    private var updateShareableLinkStatusCancellable: AnyCancellable?
    private var fetchWisetagDataCancellable: AnyCancellable?

    init(
        shouldBecomeDiscoverable: Bool,
        profile: Profile,
        interactor: WisetagInteractor,
        viewModelMapper: WisetagViewModelMapper,
        router: WisetagRouter,
        analyticsTracker: AnalyticsTracker,
        pasteboard: Pasteboard,
        scheduler: AnySchedulerOf<DispatchQueue>
    ) {
        self.shouldBecomeDiscoverable = shouldBecomeDiscoverable
        self.profile = profile
        self.interactor = interactor
        self.viewModelMapper = viewModelMapper
        self.router = router
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: WisetagAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
        self.pasteboard = pasteboard
        self.scheduler = scheduler
    }
}

// MARK: - WisetagPresenter

extension WisetagPresenterImpl: WisetagPresenter {
    func start(with view: WisetagView) {
        self.view = view
        fetchData()
    }

    func fetchData() {
        view?.showHud()
        fetchWisetagDataCancellable = interactor.fetchNextStep()
            .mapError { error in WisetagError.loadingError(error: error) }
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                view?.hideHud()
                switch result {
                case let .success(nextStep):
                    showNextStep(step: nextStep)
                case let .failure(error):
                    showError(error: error)
                    trackError(.loadingError(error: error))
                }
            }
    }

    func dismiss() {
        let isDiscoverable = isShareableLinkDiscoverable()
        router.dismiss(isShareableLinkDiscoverable: isDiscoverable)
    }
}

// MARK: WisetagViewModelDelegate

extension WisetagPresenterImpl: WisetagViewModelDelegate {
    func linkTapped() {
        copyLinkTapped()
        let text = L10n.Wisetag.SnackBar.Message.copyLink
        view?.showSnackbar(message: text)
    }

    func downloadTapped() {
        guard let image else {
            softFailure("[REC] Attempt to download non-existing image.")
            trackError(.downloadWisetagImageError)
            return
        }
        router.showDownload(image: image)
    }

    func showWisetagLearnMore() {
        analyticsViewTracker.track(WisetagAnalyticsView.NicknameOpened())
        let deepLinkComponents = DeepLinkComponents.urn(Constants.componentsLearnMore)
        guard let route = DeepLinkStoryRouteImpl(components: deepLinkComponents) else { return }
        router.showWisetagLearnMore(route: route)
    }

    func copyLinkTapped() {
        analyticsViewTracker.track(WisetagAnalyticsView.Copied())
        guard let urlString = getUrlString() else {
            softFailure("[REC] Attempt to copy non-existing urlString.")
            return
        }
        pasteboard.addToClipboard(urlString)
    }

    func qrCodeTapped() {
        guard let nickname = getNickname() else {
            softFailure("[REC] Attempt to copy non-existing nickname.")
            return
        }
        pasteboard.addToClipboard(nickname)
    }

    func shareLinkTapped(_ urlString: String) {
        analyticsViewTracker.track(WisetagAnalyticsView.ShareStarted())
        view?.showShareSheet(text: urlString)
    }

    func footerButtonTapped() {
        analyticsViewTracker.track(WisetagAnalyticsView.ActivateStarted())
        updateShareableLinkStatus(isDiscoverable: true)
    }

    func showDiscoverabilityBottomSheet() {
        analyticsViewTracker.track(WisetagAnalyticsView.SettingsOpened())
        router.showContactOnWise(nickname: getNickname())
    }

    func scanQRcodeTapped() {
        analyticsViewTracker.track(WisetagAnalyticsView.ScanOpened())
        router.showScanQRcode()
    }
}

// MARK: - WisetagShareableLinkStatusUpdater

extension WisetagPresenterImpl: WisetagShareableLinkStatusUpdater {
    func updateShareableLinkStatus(isDiscoverable: Bool) {
        view?.showHud()
        updateShareableLinkStatusCancellable = interactor.updateShareableLinkStatus(
            profileId: profile.id,
            isDiscoverable: isDiscoverable
        )
        .mapError { error in WisetagError.updateSharableLinkError(error: error) }
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
                    qrCodeImage: image
                )
            case let .failure(error):
                trackError(.updateSharableLinkError(error: error))
                showError(error: error)
            }
        }
    }
}

// MARK: - Steps

private extension WisetagPresenterImpl {
    func showNextStep(step: WisetagNextStep) {
        switch step {
        case .showADFlow:
            guard let viewController = view as? UIViewController else {
                return
            }
            router.startAccountDetailsFlow(host: viewController)
        case let .showWisetag(image: image, status: status, _):
            analyticsViewTracker.track(WisetagAnalyticsView.Loaded.success)
            self.status = status
            self.image = image
            configureView(
                status: status,
                qrCodeImage: image
            )
        case .showStory:
            let deepLinkComponents = DeepLinkComponents.urn(Constants.componentsIntro)
            guard let route = DeepLinkStoryRouteImpl(components: deepLinkComponents) else { return }
            router.showStory(route: route)
        }
    }
}

// MARK: - Error handling

private extension WisetagPresenterImpl {
    func trackError(_ error: WisetagError) {
        if let event = WisetagAnalyticsView.WisetagFailed(error: error) {
            analyticsViewTracker.track(event)
        }

        switch error {
        case let .loadingError(error: error):
            analyticsViewTracker.track(
                WisetagAnalyticsView.Loaded.error(message: error.localizedDescription)
            )
        default:
            break
        }
    }
}

// MARK: - Helpers

private extension WisetagPresenterImpl {
    func configureView(
        status: ShareableLinkStatus,
        qrCodeImage: UIImage?
    ) {
        let viewModel = viewModelMapper.make(
            profile: profile,
            status: status,
            qrCodeImage: qrCodeImage,
            delegate: self
        )
        view?.configure(with: viewModel)
    }

    func showError(error: WisetagError) {
        switch error {
        case .loadingError,
             .downloadWisetagImageError:
            let errorViewModel = ErrorViewModel(
                illustrationConfiguration: .warning,
                title: NeptuneLocalization.ErrorView.NetworkError.title,
                message: .text(NeptuneLocalization.ErrorView.NetworkError.message),
                primaryViewModel: .tryAgain { [weak self] in
                    self?.fetchData()
                }
            )
            view?.configureWithError(with: errorViewModel)
        case .ineligible:
            let errorViewModel = ErrorViewModel(
                illustrationConfiguration: .warning,
                title: L10n.Wisetag.ScannedProfile.Error.NotEligible.title,
                message: .text(L10n.Wisetag.ScannedProfile.Error.NotEligible.subtitle),
                primaryViewModel: .done { [weak self] in
                    self?.dismiss()
                }
            )
            view?.configureWithError(with: errorViewModel)
        case .updateSharableLinkError:
            let errorViewModel = ErrorViewModel(
                illustrationConfiguration: .warning,
                title: NeptuneLocalization.ErrorView.NetworkError.title,
                message: .text(NeptuneLocalization.ErrorView.NetworkError.message),
                primaryViewModel: .tryAgain { [weak self] in
                    self?.updateShareableLinkStatus(isDiscoverable: (self?.isShareableLinkDiscoverable()) != nil)
                }
            )
            view?.configureWithError(with: errorViewModel)
        }
    }

    func isShareableLinkDiscoverable() -> Bool {
        guard case let .eligible(discoverability) = status,
              case .discoverable = discoverability else {
            return false
        }
        return true
    }

    func getNickname() -> String? {
        guard case let .eligible(discoverability) = status,
              case let .discoverable(_, nickname) = discoverability else {
            return nil
        }
        return nickname
    }

    func getUrlString() -> String? {
        guard case let .eligible(discoverability) = status,
              case let .discoverable(url, _) = discoverability else {
            return nil
        }
        return url
    }

    enum Constants {
        static let componentsLearnMore = DeepLinkURNComponents(
            path: ["stories", "notifications", "wisetag-consumer-intro"]
        )
        static let componentsIntro = DeepLinkURNComponents(
            path: ["stories", "notifications", "wisetag-consumer-intro-get-started-cta"]
        )
    }
}
