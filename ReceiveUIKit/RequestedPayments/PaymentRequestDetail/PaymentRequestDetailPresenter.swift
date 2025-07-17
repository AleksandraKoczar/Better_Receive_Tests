import AnalyticsKit
import Combine
import CombineSchedulers
import ContactsKit
import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentRequestDetailPresenter {
    func start(with view: PaymentRequestDetailView)
    func dismiss()
}

final class PaymentRequestDetailPresenterImpl {
    private weak var view: PaymentRequestDetailView?
    private let router: PaymentRequestDetailRouter
    private weak var listUpdateDelegate: PaymentRequestListUpdater?
    private var paymentRequestId: PaymentRequestId
    private let profile: Profile
    private let pasteboard: Pasteboard
    private let paymentRequestUseCase: PaymentRequestUseCaseV2
    private let attachmentService: AttachmentFileService
    private let paymentRequestDetailsUseCase: PaymentRequestDetailsUseCase
    private let paymentRequestDetailViewModelFactory: PaymentRequestDetailViewModelFactory
    private let imageLoader: URIImageLoader
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<PaymentRequestDetailAnalyticsView>
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var fetchPaymentRequestDetailsCancellable: AnyCancellable?
    private var fetchPaymentRequestCancellable: AnyCancellable?
    private var downloadAttachmentCancellable: AnyCancellable?
    private var updateRequestStatusCancellable: AnyCancellable?
    private var getAvatarIfNeeded: AnyCancellable?

    init(
        paymentRequestId: PaymentRequestId,
        profile: Profile,
        router: PaymentRequestDetailRouter,
        listUpdateDelegate: PaymentRequestListUpdater? = nil, // Don't need list updater if it's deep-linking
        imageLoader: URIImageLoader = URIImageLoaderImpl(),
        paymentRequestUseCase: PaymentRequestUseCaseV2 = PaymentRequestUseCaseFactoryV2.make(),
        attachmentService: AttachmentFileService = AttachmentFileServiceFactory.make(),
        paymentRequestDetailsUseCase: PaymentRequestDetailsUseCase = PaymentRequestDetailsUseCaseFactory.make(),
        paymentRequestDetailViewModelFactory: PaymentRequestDetailViewModelFactory = PaymentRequestDetailViewModelFactoryImpl(),
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        pasteboard: Pasteboard = UIPasteboard.general,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.paymentRequestId = paymentRequestId
        self.profile = profile
        self.pasteboard = pasteboard
        self.imageLoader = imageLoader
        self.listUpdateDelegate = listUpdateDelegate
        self.paymentRequestUseCase = paymentRequestUseCase
        self.attachmentService = attachmentService
        self.paymentRequestDetailsUseCase = paymentRequestDetailsUseCase
        self.paymentRequestDetailViewModelFactory = paymentRequestDetailViewModelFactory
        self.scheduler = scheduler
        self.router = router
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: PaymentRequestDetailAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }
}

// MARK: - Helpers

private extension PaymentRequestDetailPresenterImpl {
    enum PaymentRequestDetailPresenterError: LocalizedError {
        case presenterHasBeenDeallocated

        var errorDescription: String? {
            switch self {
            case .presenterHasBeenDeallocated:
                "PaymentRequestDetailPresenter has been deallocated already."
            }
        }
    }

    func showError(
        title: String = L10n.PaymentRequest.Detail.Error.title,
        message: String = L10n.Generic.Error.message
    ) {
        view?.showDismissableAlert(
            title: title,
            message: message
        )
    }

    func loadPaymentRequestDetails() {
        view?.showHud()
        fetchPaymentRequestDetailsCancellable = fetchPaymentRequestDetailsAndCreateViewModel()
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                view?.hideHud()
                switch result {
                case let .success(viewModel):
                    view?.configure(with: viewModel)
                case .failure:
                    showError()
                }
            }
    }

    func fetchPaymentRequest() -> AnyPublisher<PaymentRequestV2, PaymentRequestUseCaseError> {
        paymentRequestUseCase.paymentRequest(
            profileId: profile.id,
            paymentRequestId: paymentRequestId
        )
    }

    func fetchPaymentRequestDetailsAndCreateViewModel() -> AnyPublisher<PaymentRequestDetailViewModel, PaymentRequestUseCaseError> {
        paymentRequestDetailsUseCase.paymentRequestDetails(
            profileId: profile.id,
            paymentRequestId: paymentRequestId
        )
        .mapError { error in PaymentRequestUseCaseError.other(error: error) }
        .flatMap { [weak self] paymentRequestDetails -> AnyPublisher<PaymentRequestDetailViewModel, PaymentRequestUseCaseError> in
            guard let self else {
                return .fail(with: PaymentRequestUseCaseError.customError(message: L10n.Generic.Error.title))
            }
            return paymentRequestDetailViewModelFactory.make(
                from: paymentRequestDetails,
                delegate: self
            )
            .setFailureType(to: PaymentRequestUseCaseError.self)
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    func updatePaymentRequestStatus(to newStatus: PaymentRequestStatusV2, onSuccess: (() -> Void)? = nil) {
        view?.showHud()
        updateRequestStatusCancellable = paymentRequestUseCase.updatePaymentRequestStatus(
            profileId: profile.id,
            paymentRequestId: paymentRequestId,
            body: UpdatePaymentRequestStatusBodyV2(status: newStatus)
        )
        .flatMap { [weak self] _ -> AnyPublisher<PaymentRequestDetailViewModel, PaymentRequestUseCaseError> in
            guard let self else {
                return .fail(with: PaymentRequestUseCaseError.customError(message: L10n.Generic.Error.title))
            }
            return fetchPaymentRequestDetailsAndCreateViewModel()
        }
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else {
                return
            }
            view?.hideHud()
            switch result {
            case let .success(viewModel):
                onSuccess?()
                view?.configure(with: viewModel)
                listUpdateDelegate?.requestStatusUpdated()
            case let .failure(error):
                mapErrorToMessage(error: error)
            }
        }
    }
}

// MARK: - PaymentRequestDetailPresenter

extension PaymentRequestDetailPresenterImpl: PaymentRequestDetailPresenter {
    func start(with view: PaymentRequestDetailView) {
        self.view = view
        let action = PaymentRequestDetailAnalyticsView.ViewingDetails()
        analyticsViewTracker.track(action)
        loadPaymentRequestDetails()
    }

    func dismiss() {
        router.dismiss()
    }
}

// MARK: - PaymentRequestDetailViewModelDelegate

extension PaymentRequestDetailPresenterImpl: PaymentRequestDetailViewModelDelegate {
    func copyTapped(_ value: String) {
        let action = PaymentRequestDetailAnalyticsView.CopyRequestLink()
        analyticsViewTracker.track(action)
        pasteboard.addToClipboard(value)
        view?.showSnackBar(message: L10n.PaymentRequest.Detail.copied)
    }

    func shareOptionsTapped(viewModel: PaymentRequestDetailShareOptionsViewModel) {
        view?.showShareOptions(viewModel: viewModel)
    }

    func paymentMethodSummariesTapped(viewModel: PaymentRequestDetailPaymentMethodsViewModel) {
        view?.showPaymentMethodSummaries(viewModel: viewModel)
    }

    func viewAttachmentFileTapped(_ file: RequestorAttachmentFile) {
        view?.showHud()
        let action = PaymentRequestDetailAnalyticsView.ViewInvoice()
        analyticsViewTracker.track(action)
        downloadAttachmentCancellable = attachmentService.downloadFile(
            profileId: profile.id,
            requestId: paymentRequestId,
            file: file
        )
        .receive(on: scheduler)
        .asResult()
        .sink { [weak self] result in
            self?.view?.hideHud()
            switch result {
            case let .success(url):
                if let delegate = self?.view?.documentDelegate {
                    self?.router.showDocumentPreview(url: url, delegate: delegate)
                }
            case .failure:
                self?.showError()
            }
        }
    }

    func cancelPaymentRequestTapped(requestType: PaymentRequestDetails.RequestType) {
        let action = PaymentRequestDetailAnalyticsView.StartCancellingRequest()
        analyticsViewTracker.track(action)
        let viewModel = paymentRequestDetailViewModelFactory.makeCancelConfirmation(
            requestType: requestType,
            delegate: self
        )
        router.showActionConfirmation(viewModel: viewModel)
    }

    func paymentDetailsTapped(action: PaymentRequestDetailsSection.Item.OptionItemAction) {
        switch action {
        case let .navigateToAcquiringPayment(acquiringPaymentId):
            router.showPaymentLinkPaymentDetails(acquiringPaymentId: acquiringPaymentId)
        case let .navigateToAcquiringTransaction(transactionId):
            router.showAcquiringTransactionPaymentDetails(transactionId: transactionId)
        case let .navigateToTransfer(transferId):
            router.showTransferPaymentDetails(transferId: transferId)
        }
    }

    func cancelPaymentRequestConfirmed() {
        updatePaymentRequestStatus(to: .invalidated) { [weak self] in
            let action = PaymentRequestDetailAnalyticsView.CancelRequest()
            self?.analyticsViewTracker.track(action)
        }
    }

    func markAsPaidTapped(requestType: PaymentRequestDetails.RequestType) {
        let viewModel = paymentRequestDetailViewModelFactory.makeMarkAsPaidConfirmation(
            requestType: requestType,
            delegate: self
        )
        router.showActionConfirmation(viewModel: viewModel)
    }

    func markAsPaidConfirmed() {
        updatePaymentRequestStatus(to: .completed)
    }

    func shareWithQRCodeTapped() {
        view?.showHud()
        fetchPaymentRequestCancellable = fetchPaymentRequest()
            .receive(on: scheduler)
            .asResult()
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                view?.hideHud()
                switch result {
                case let .success(paymentRequest):
                    router.showQRCode(paymentRequest: paymentRequest)
                case .failure:
                    showError()
                }
            }
    }

    func shareSheetTapped() {
        view?.showHud()
        fetchPaymentRequestCancellable = fetchPaymentRequest()
            .receive(on: scheduler)
            .asResult()
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                view?.hideHud()
                switch result {
                case let .success(paymentRequest):
                    router.showShareSheet(paymentRequest: paymentRequest)
                case .failure:
                    showError()
                }
            }
    }

    func fetchAvatarViewModel(
        urlString: String,
        fallbackImage: UIImage,
        badge: UIImage?
    ) -> AnyPublisher<AvatarViewModel, Never> {
        let fallbackViewModel = AvatarViewModel.icon(fallbackImage, badge: badge)
        guard let url = URL(string: urlString) else {
            softFailure("[REC] Attemp to download avatar with invalid url: \(urlString)")
            return .just(fallbackViewModel)
        }
        return imageLoader.load(.url(url))
            .map { image in AvatarViewModel.image(image, badge: badge) }
            .replaceError(with: fallbackViewModel)
            .eraseToAnyPublisher()
    }

    func sectionHeaderActionTapped(urnString: String) {
        let action = PaymentRequestDetailAnalyticsView.ViewAllPressed(urn: urnString)
        analyticsViewTracker.track(action)
        router.goToViewAllPayments()
    }

    func mapErrorToMessage(error: PaymentRequestUseCaseError) {
        switch error {
        case let .customError(message: message):
            showError(title: "", message: message ?? L10n.Generic.Error.message)
        case .other:
            showError()
        }
    }
}

// MARK: - PaymentDetailsRefundFlowDelegate

extension PaymentRequestDetailPresenterImpl: PaymentDetailsRefundFlowDelegate {
    func didRefundFlowCompleted() {
        router.goBackToPaymentRequestDetail()
        loadPaymentRequestDetails()
    }

    func goBackToAllPayments() {
        router.goBackToAllPayments()
    }
}
