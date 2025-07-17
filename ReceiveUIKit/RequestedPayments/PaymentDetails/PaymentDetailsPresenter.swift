import Combine
import CombineSchedulers
import ReceiveKit
import TransferResources
import TWFoundation
import WiseCore

// sourcery: AutoMockable
protocol PaymentDetailsPresenter: AnyObject {
    func start(with view: PaymentDetailsView)
}

final class PaymentDetailsPresenterImpl {
    private weak var view: PaymentDetailsView?
    private let router: PaymentDetailsRouter
    private let interactor: PaymentDetailsInteractor
    private let featureService: FeatureService
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private let profileId: ProfileId
    private var configureViewCancellable: AnyCancellable?

    init(
        profileId: ProfileId,
        router: PaymentDetailsRouter,
        interactor: PaymentDetailsInteractor,
        featureService: FeatureService = GOS[FeatureServiceKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profileId = profileId
        self.router = router
        self.interactor = interactor
        self.featureService = featureService
        self.scheduler = scheduler
    }
}

// MARK: - PaymentDetailsPresenter

extension PaymentDetailsPresenterImpl: PaymentDetailsPresenter {
    func start(with view: PaymentDetailsView) {
        self.view = view
        view.showHud()
        configureViewCancellable = interactor.paymentDetails(profileId: profileId)
            .receive(on: scheduler)
            .asResult()
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                self.view?.hideHud()
                switch result {
                case let .success(paymentDetails):
                    let viewModel = PaymentDetailsViewModelMapper.make(
                        from: paymentDetails,
                        delegate: self
                    )
                    self.view?.configure(with: viewModel)
                case .failure:
                    self.view?.showDismissableAlert(
                        title: L10n.Generic.Error.title,
                        message: L10n.Generic.Error.message
                    )
                }
            }
    }
}

// MARK: - PaymentDetailsViewModelMapperDelegate

extension PaymentDetailsPresenterImpl: PaymentDetailsViewModelMapperDelegate {
    func isRefundEnabled() -> Bool {
        featureService.getValue(for: ReceiveKitFeatures.acquiringTransactionRefundEnabledV2)
    }

    func proceedRefund(paymentId: String) {
        router.showRefundFlow(paymentId: paymentId, profileId: profileId)
    }

    func showRefundDisabled(
        title: String,
        message: String,
        illustrationUrn: String?
    ) {
        router.showRefundDisabledBottomSheet(
            title: title,
            illustrationUrn: illustrationUrn,
            message: message
        )
    }
}
