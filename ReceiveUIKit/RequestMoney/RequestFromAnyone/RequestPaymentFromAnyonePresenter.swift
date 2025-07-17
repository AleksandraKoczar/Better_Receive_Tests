import AnalyticsKit
import Combine
import CombineSchedulers
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UIKit
import UserKit

public enum RequestFromAnyoneFinishResult {
    case success
    case dismissed
}

// sourcery: AutoMockable
protocol RequestFromAnyonePresenter: AnyObject {
    func start(with view: RequestPaymentFromAnyoneView)
    func shareTapped(_ urlString: String)
    func finishSharing(didShareWisetag: Bool)
    func turnOnWisetagTapped()
    func addAmmountAndNoteTapped()
}

final class RequestFromAnyonePresenterImpl {
    private weak var view: RequestPaymentFromAnyoneView?
    private weak var routingDelegate: RequestFromAnyoneRoutingDelegate?
    private var state: ShareableLinkStatus.Discoverability = .notDiscoverable
    private var image: UIImage?

    private let wisetagUseCase: WisetagUseCase
    private let profile: Profile
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let pasteboard: Pasteboard
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<RequestFromAnyoneAnalyticsView>

    private var fetchWisetagDataCancellable: AnyCancellable?
    private var turnOnWisetagCancellable: AnyCancellable?

    init(
        wisetagUseCase: WisetagUseCase,
        routingDelegate: RequestFromAnyoneRoutingDelegate,
        profile: Profile,
        pasteboard: Pasteboard,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.wisetagUseCase = wisetagUseCase
        self.routingDelegate = routingDelegate
        self.profile = profile
        self.pasteboard = pasteboard
        self.scheduler = scheduler
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: RequestFromAnyoneAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }
}

extension RequestFromAnyonePresenterImpl: RequestFromAnyonePresenter {
    func start(with view: any RequestPaymentFromAnyoneView) {
        self.view = view

        view.showHud()
        fetchWisetagDataCancellable = fetchWisetagData()
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                self.view?.hideHud()
                switch result {
                case let .success((status, image)):
                    guard case let .eligible(discoverabiliy) = status else {
                        routingDelegate?.useOldFlow()
                        return
                    }

                    switch discoverabiliy {
                    case .notDiscoverable:
                        state = .notDiscoverable
                    case let .discoverable(url, nickname):
                        state = .discoverable(urlString: url, nickname: nickname)
                    }
                    self.image = image
                    configureView(
                        state: state,
                        qrCodeImage: image
                    )
                    analyticsViewTracker.track(RequestFromAnyoneAnalyticsView.Started())
                case .failure:
                    showError()
                }
            }
    }

    func shareTapped(_ urlString: String) {
        view?.showShareSheet(text: urlString)
        analyticsViewTracker.track(RequestFromAnyoneAnalyticsView.ShareClicked())
    }

    func addAmmountAndNoteTapped() {
        routingDelegate?.addAmountAndNote()
        analyticsViewTracker.track(RequestFromAnyoneAnalyticsView.CreateStepClick())
    }

    func turnOnWisetagTapped() {
        updateShareableLinkStatus(isDiscoverable: true)
        analyticsViewTracker.track(RequestFromAnyoneAnalyticsView.Activate())
    }

    func qrCodeTapped(nickname: String) {
        analyticsViewTracker.track(RequestFromAnyoneAnalyticsView.Copied())
        pasteboard.addToClipboard(nickname)
    }

    func handleDoneAction() {
        routingDelegate?.endFlow()
        analyticsViewTracker.track(RequestFromAnyoneAnalyticsView.Finished(result: .dismissed))
    }

    func finishSharing(didShareWisetag: Bool) {
        if didShareWisetag {
            routingDelegate?.endFlow()
            analyticsViewTracker.track(RequestFromAnyoneAnalyticsView.Finished(result: .success))
        }
    }
}

extension RequestFromAnyonePresenterImpl: WisetagShareableLinkStatusUpdater {
    func updateShareableLinkStatus(isDiscoverable: Bool) {
        view?.showHud()
        turnOnWisetagCancellable = wisetagUseCase.updateShareableLinkStatus(
            profileId: profile.id,
            isDiscoverable: isDiscoverable
        )
        .flatMap { [weak self] status -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error> in
            guard let self else {
                return .just((status, nil))
            }
            return fetchQRCode(status: status)
        }
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else {
                return
            }
            view?.hideHud()
            switch result {
            case let .success((status, image)):
                guard case let .eligible(discoverabiliy) = status else {
                    return
                }

                switch discoverabiliy {
                case .notDiscoverable:
                    state = .notDiscoverable
                case let .discoverable(url, nickname):
                    state = .discoverable(urlString: url, nickname: nickname)
                }
                self.image = image
                configureView(
                    state: state,
                    qrCodeImage: image
                )
            case .failure:
                showError()
            }
        }
    }
}

extension RequestFromAnyonePresenterImpl {
    func fetchWisetagData() -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error> {
        wisetagUseCase.shareableLinkStatus(for: profile.id)
            .flatMap { [weak self] status -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error> in
                guard let self else { return .just((status, nil)) }
                return fetchQRCode(status: status)
            }.eraseToAnyPublisher()
    }

    func fetchQRCode(status: ShareableLinkStatus) -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error> {
        guard case let .eligible(discoverability) = status else {
            return .just((status, nil))
        }
        let content: String = { branding in
            switch discoverability {
            case .notDiscoverable:
                branding.urlString
            case let .discoverable(urlString, _):
                urlString
            }
        }(Branding.current)
        return wisetagUseCase.qrCode(content: content)
            .map { image in
                (status, image)
            }
            .catch { _ -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error> in
                .just((status, nil))
            }
            .eraseToAnyPublisher()
    }

    func configureView(
        state: ShareableLinkStatus.Discoverability,
        qrCodeImage: UIImage?
    ) {
        view?.configure(with: makeViewModel(state: state, qrCodeImage: qrCodeImage))
    }

    func makeViewModel(
        state: ShareableLinkStatus.Discoverability,
        qrCodeImage: UIImage?
    ) -> RequestPaymentFromAnyoneViewModel {
        let titleViewModel = LargeTitleViewModel(
            title: L10n.PaymentRequest.Create.RequestFromAnyone.title,
            description: L10n.PaymentRequest.Create.RequestFromAnyone.description
        )

        var primaryAction: Action
        let secondaryAction = Action(
            title: L10n.PaymentRequest.Create.RequestFromAnyone.addAmountAction,
            handler: { [weak self] in
                self?.addAmmountAndNoteTapped()
            }
        )

        switch state {
        case let .discoverable(urlString, _):
            primaryAction = Action(
                title: L10n.PaymentRequest.Create.RequestFromAnyone.shareAction,
                handler: { [weak self] in
                    self?.shareTapped(urlString)
                }
            )
        case .notDiscoverable:
            primaryAction = Action(
                title: L10n.PaymentRequest.Create.RequestFromAnyone.turnOnAction,
                handler: { [weak self] in
                    self?.turnOnWisetagTapped()
                }
            )
        }

        let actionButton = SmallButtonView(
            title: L10n.PaymentRequest.Create.RequestFromAnyone.doneAction,
            style: .smallSecondaryNeutral,
            handler: { [weak self] in
                self?.handleDoneAction()
            }
        )

        return RequestPaymentFromAnyoneViewModel(
            titleViewModel: titleViewModel,
            qrCodeViewModel: makeQRCodeViewModel(state: state, qrCodeImage: qrCodeImage),
            doneAction: actionButton,
            primaryActionFooter: primaryAction,
            secondaryActionFooter: secondaryAction
        )
    }

    func makeQRCodeViewModel(
        state: ShareableLinkStatus.Discoverability,
        qrCodeImage: UIImage?
    ) -> WisetagQRCodeViewModel {
        guard case let .discoverable(urlString, nickname) = state else {
            let urlString = Constants.placeholderURL.absoluteString
            let placeholderQRCode = qrCodeImage ?? UIImage.qrCode(from: urlString)

            return WisetagQRCodeViewModel(state: .qrCodeDisabled(
                placeholderQRCode: placeholderQRCode,
                disabledText: L10n.Wisetag.inactiveWisetag,
                onTap: {}
            ))
        }
        let qrCode = qrCodeImage ?? UIImage.qrCode(from: urlString)
        return WisetagQRCodeViewModel(state: .qrCodeEnabled(
            qrCode: qrCode,
            enabledText: nickname,
            enabledTextOnTap: L10n.Wisetag.QrCode.Copied.title,
            onTap: { [weak self] in
                self?.qrCodeTapped(nickname: nickname)
            }
        ))
    }

    func showError() {
        view?.showDismissableAlert(
            title: L10n.Generic.Error.title,
            message: L10n.Generic.Error.message
        )
    }

    private enum Constants {
        static let placeholderURL = Branding.current.url.appendingPathComponent("wisetag")
    }
}
