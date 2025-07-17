import Combine
import CombineSchedulers
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentLinkAllPaymentsPresenter: AnyObject {
    func start(with view: PaymentLinkAllPaymentsView)
    func rowTapped(action: PaymentLinkAllPayments.Group.Content.OptionItemAction)
    func prefetch(id: String)
}

final class PaymentLinkAllPaymentsPresenterImpl {
    private weak var view: PaymentLinkAllPaymentsView?
    private let router: PaymentLinkAllPaymentsRouter
    private var paymentRequestId: PaymentRequestId
    private let profile: Profile
    private let paymentLinkAllPaymentsUseCase: PaymentLinkAllPaymentsListUseCase
    private var allPayments: PaymentLinkAllPayments
    private let scheduler: AnySchedulerOf<DispatchQueue>

    private var fetchAllPaymentsCancellable: AnyCancellable?
    private var prefetchAllPaymentsCancellable: AnyCancellable?

    init(
        router: PaymentLinkAllPaymentsRouter,
        paymentRequestId: PaymentRequestId,
        paymentLinkAllPaymentsUseCase: PaymentLinkAllPaymentsListUseCase = PaymentLinkAllPaymentsListUseCaseFactory.make(),
        profile: Profile,
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.router = router
        self.paymentRequestId = paymentRequestId
        self.paymentLinkAllPaymentsUseCase = paymentLinkAllPaymentsUseCase
        self.profile = profile
        self.scheduler = scheduler
        allPayments = PaymentLinkAllPayments.makeInitial()
    }
}

extension PaymentLinkAllPaymentsPresenterImpl: PaymentLinkAllPaymentsPresenter {
    func start(with view: PaymentLinkAllPaymentsView) {
        self.view = view
        fetchAllPaymentsIfNeeded(forceUpdating: true)
    }

    func rowTapped(action: PaymentLinkAllPayments.Group.Content.OptionItemAction) {
        switch action {
        case let .navigateToAcquiringPayment(acquiringPaymentId):
            router.showPaymentLinkPaymentDetails(acquiringPaymentId: acquiringPaymentId)
        case let .navigateToAcquiringTransaction(transactionId):
            router.showAcquiringTransactionPaymentDetails(transactionId: transactionId)
        case let .navigateToTransfer(transferId):
            router.showTransferPaymentDetails(transferId: transferId)
        }
    }

    func prefetch(id: String) {
        guard let seekPosition = getSeekPosition(id: id) else {
            return
        }

        view?.showHud()
        prefetchAllPaymentsCancellable = fetchAllPayments(seekPosition: seekPosition)
            .receive(on: scheduler)
            .asResult()
            .sink { [weak self] result in
                guard let self, let newPayments = result.value else {
                    return
                }
                view?.hideHud()
                let oldPayments = allPayments
                allPayments = oldPayments.appending(newPayments)
                let newSections = createNewSectionViewModel(from: newPayments.groups)
                view?.showNewSections(newSections)
            }
    }
}

private extension PaymentLinkAllPaymentsPresenterImpl {
    enum PaymentLinkAllPaymentsPresenterError: LocalizedError {
        case presenterHasBeenDeallocated

        var errorDescription: String? {
            switch self {
            case .presenterHasBeenDeallocated:
                "PaymentLinkAllPaymentsPresenter has been deallocated already."
            }
        }
    }

    func showError() {
        view?.showDismissableAlert(
            title: L10n.PaymentRequest.Detail.Error.title,
            message: L10n.Generic.Error.message
        )
    }

    func fetchAllPayments(seekPosition: String? = nil) -> AnyPublisher<PaymentLinkAllPayments, Error> {
        paymentLinkAllPaymentsUseCase.getAllPaymentsForPaymentLink(
            profileId: profile.id,
            paymentRequestId: paymentRequestId,
            cursor: seekPosition,
            pageSize: 10
        )
    }

    func fetchAllPaymentsIfNeeded(forceUpdating: Bool) {
        let shouldFetchAllPayments = forceUpdating || allPayments.groups.isEmpty

        guard shouldFetchAllPayments else {
            let viewModel = createViewModelFromAllPayments(from: allPayments)
            view?.configure(with: viewModel)
            return
        }

        view?.showHud()
        fetchAllPaymentsCancellable = fetchAllPayments()
            .receive(on: scheduler)
            .asResult()
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                view?.hideHud()
                switch result {
                case let .success(payments):
                    if forceUpdating {
                        allPayments = payments
                    } else {
                        let oldPayments = allPayments
                        allPayments = oldPayments.appending(payments)
                    }

                    let viewModel = createViewModelFromAllPayments(from: allPayments)
                    view?.configure(with: viewModel)
                case .failure:
                    showError()
                }
            }
    }

    func createViewModelFromAllPayments(from allPayments: PaymentLinkAllPayments) ->
        PaymentLinkAllPaymentsViewModel {
        let sections = allPayments.groups.map { group in
            PaymentLinkAllPaymentsViewModel.Section(
                id: group.groupId,
                title: group.groupLabel,
                viewModel: SectionHeaderViewModel(title: group.groupLabel),
                items: self.mapItems(from: group.content)
            )
        }

        return PaymentLinkAllPaymentsViewModel(
            title: LargeTitleViewModel(title: L10n.PaymentRequest.PaymentLink.AllPayments.title),
            content: .sections(sections)
        )
    }

    func createNewSectionViewModel(from groups: [PaymentLinkAllPayments.Group]) -> [PaymentLinkAllPaymentsViewModel.Section] {
        groups.map { group in
            PaymentLinkAllPaymentsViewModel.Section(
                id: group.groupId,
                title: group.groupLabel,
                viewModel: SectionHeaderViewModel(
                    title: group.groupLabel,
                    action: nil,
                    accessibilityHint: group.groupLabel
                ),
                items: mapItems(from: group.content)
            )
        }
    }

    func mapItems(from contents: [PaymentLinkAllPayments.Group.Content]) -> [PaymentLinkAllPaymentsViewModel.Section.OptionItem] {
        contents.map { content in
            PaymentLinkAllPaymentsViewModel.Section.OptionItem(
                id: content.id,
                option: OptionViewModel(
                    title: content.title,
                    subtitle: content.subtitle,
                    avatar: .icon(makeIcon(from: content.icon))
                ),
                actionType: content.action
            )
        }
    }

    func makeIcon(from urnString: String) -> UIImage {
        guard let urn = try? URN(urnString),
              let image = IconFactory.icon(urn: urn) else {
            return Icons.fastFlag.image
        }
        return image
    }

    func getSeekPosition(id: String) -> String? {
        guard allPayments.groups.last?.content.last?.id == id, case let .hasNextPage(seekPosition: seekPosition) = allPayments.nextPageState else {
            return nil
        }
        return seekPosition
    }
}
