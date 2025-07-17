import Combine
import CombineSchedulers
import Foundation
import ReceiveKit
import TransferResources
import WiseCore

// sourcery: AutoMockable
protocol PaymentLinkPaymentDetailsPresenter: AnyObject {
    func start(with view: PaymentLinkPaymentDetailsView)
}

final class PaymentLinkPaymentDetailsPresenterImpl {
    private let paymentRequestId: PaymentRequestId
    private let acquiringPaymentId: AcquiringPaymentId
    private let profileId: ProfileId
    private let paymentLinkPaymentDetailsUseCase: PaymentLinkPaymentDetailsUseCase
    private let router: PaymentLinkPaymentDetailsRouter
    private let viewModelFactory: PaymentLinkPaymentDetailsViewModelFactory
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private weak var view: PaymentLinkPaymentDetailsView?
    private var fetchPaymentDetailsCancellable: AnyCancellable?

    init(
        paymentRequestId: PaymentRequestId,
        acquiringPaymentId: AcquiringPaymentId,
        profileId: ProfileId,
        router: PaymentLinkPaymentDetailsRouter,
        paymentLinkPaymentDetailsUseCase: PaymentLinkPaymentDetailsUseCase = PaymentLinkPaymentDetailsUseCaseFactory.make(),
        viewModelFactory: PaymentLinkPaymentDetailsViewModelFactory = PaymentLinkPaymentDetailsViewModelFactoryImpl(),
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.paymentRequestId = paymentRequestId
        self.acquiringPaymentId = acquiringPaymentId
        self.profileId = profileId
        self.paymentLinkPaymentDetailsUseCase = paymentLinkPaymentDetailsUseCase
        self.router = router
        self.viewModelFactory = viewModelFactory
        self.scheduler = scheduler
    }
}

// MARK: - PaymentLinkPaymentDetailsPresenter

extension PaymentLinkPaymentDetailsPresenterImpl: PaymentLinkPaymentDetailsPresenter {
    func start(with view: PaymentLinkPaymentDetailsView) {
        self.view = view
        view.showHud()
        fetchPaymentDetailsCancellable = paymentLinkPaymentDetailsUseCase.paymentDetails(
            profileId: profileId,
            paymentRequestId: paymentRequestId,
            acquiringPaymentId: acquiringPaymentId
        )
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else {
                return
            }
            self.view?.hideHud()
            switch result {
            case let .success(paymentLinkPaymentDetails):
                let viewModel = viewModelFactory.make(
                    from: paymentLinkPaymentDetails,
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

// MARK: - PaymentLinkPaymentDetailsViewModelDelegate

extension PaymentLinkPaymentDetailsPresenterImpl: PaymentLinkPaymentDetailsViewModelDelegate {
    func optionItemTapped(
        action: PaymentLinkPaymentDetails.Section.Item.OptionItemAction
    ) {
        switch action {
        case let .navigateToAcquiringTransaction(transactionId):
            router.showAcquiringTransactionPaymentDetails(transactionId: transactionId)
        case let .navigateToTransfer(transferId):
            router.showTransferPaymentDetails(transferId: transferId)
        }
    }
}
