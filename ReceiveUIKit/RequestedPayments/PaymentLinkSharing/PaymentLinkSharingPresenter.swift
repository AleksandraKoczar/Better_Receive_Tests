import Combine
import CombineSchedulers
import LoggingKit
import MacrosKit
import Prism
import TWFoundation

// sourcery: AutoMockable
@MainActor
protocol PaymentLinkSharingPresenter: AnyObject {
    func viewLoaded(with view: PaymentLinkSharingView)
    func refresh()
}

@Init
final class PaymentLinkSharingPresenterImpl: PaymentLinkSharingPresenter {
    private let source: PaymentLinkSharingSource
    private let interactor: PaymentLinkSharingInteractor
    private let router: PaymentLinkSharingRouter
    private let tracking: PaymentRequestShareModalTracking

    @Init(default: PaymentLinkSharingViewModelMapperImpl())
    private let viewModelMapper: PaymentLinkSharingViewModelMapper

    @Init(default: AnySchedulerOf<DispatchQueue>.main)
    private let scheduler: AnySchedulerOf<DispatchQueue>

    @InitIgnore
    private weak var view: PaymentLinkSharingView?
    @InitIgnore
    private var fetchDetailsCancellable: AnyCancellable?
    @InitIgnore
    private var viewLoaded = false

    func viewLoaded(with view: PaymentLinkSharingView) {
        self.view = view

        guard !viewLoaded else {
            return
        }

        viewLoaded = true
        fetchDetails()
        tracking.onPaymentRequestModalStarted(source: source.analyticsValue)
    }

    func refresh() {
        fetchDetails()
    }
}

private extension PaymentLinkSharingPresenterImpl {
    func fetchDetails() {
        guard let view else { return }

        fetchDetailsCancellable = interactor.fetchDetails()
            .receive(on: scheduler)
            .handleLoading(view)
            .compactMap { $0.content }
            .sink { [weak self] in
                self?.handleContent($0)
            }
    }

    func handleContent(_ model: PaymentLinkSharingDetails) {
        guard let view else { return }

        let viewModel = viewModelMapper.map(model) { [weak self] in
            self?.handleAction($0)
        }
        view.configure(with: viewModel)
    }

    func handleAction(_ action: PaymentLinkSharingViewAction) {
        switch action {
        case let .shareLink(paymentRequest):
            tracking.onPaymentRequestModalShareLinkClicked()
            router.openLinkSharing(for: paymentRequest)
        case let .viewPaymentRequest(paymentRequestId):
            tracking.onPaymentRequestModalViewRequestClicked()
            router.openPaymentRequestDetails(for: paymentRequestId)
        }
    }
}
