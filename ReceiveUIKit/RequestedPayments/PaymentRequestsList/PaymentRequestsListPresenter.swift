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
import UserKit
import WiseCore

enum SupportedPaymentRequestType {
    case singleUseAndReusable
    case singleUseOnly
    case invoiceOnly
}

// sourcery: AutoMockable
protocol PaymentRequestsListPresenter: AnyObject {
    func start(with view: PaymentRequestsListView)
    func rowTapped(id: String)
    func prefetch(id: String)
    func refresh()
    func dismiss()
}

final class PaymentRequestsListPresenterImpl {
    private enum Constants {
        static let invoicesHelpArticleId = HelpCenterArticleId(rawValue: "3PBeSfyBJ22iAsQD49HEbE")
        static let requestsHelpArticleId = HelpCenterArticleId(rawValue: "2WvlZST6DiDMUBhyl1N4zM")
    }

    private weak var view: PaymentRequestsListView?

    private let supportedPaymentRequestType: SupportedPaymentRequestType
    private let profile: Profile

    private let router: PaymentRequestsListRouter
    private let paymentRequestListUseCase: PaymentRequestListUseCase
    private let paymentRequestsListViewModelFactory: PaymentRequestsListViewModelFactory
    private let imageLoader: URIImageLoader
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<PaymentRequestsListAnalyticsView>
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let featureService: FeatureService
    private let flowDismissed: () -> Void

    private var paymentRequestSummaryList: PaymentRequestSummaryList
    private var fetchPaymentRequestSummariesCancellable: AnyCancellable?
    private var proceedCreateNewPaymentRequestCancellable: AnyCancellable?
    private var prefetchPaymentRequestSummariesCancellable: AnyCancellable?
    private var paymentRequestStatusCancellable: AnyCancellable?

    init(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        visibleState: PaymentRequestSummaryList.State,
        profile: Profile,
        featureService: FeatureService = GOS[FeatureServiceKey.self],
        router: PaymentRequestsListRouter,
        paymentRequestListUseCase: PaymentRequestListUseCase = PaymentRequestListUseCaseFactory.make(),
        paymentRequestsListViewModelFactory: PaymentRequestsListViewModelFactory = PaymentRequestsListViewModelFactoryImpl(),
        imageLoader: URIImageLoader = URIImageLoaderImpl(),
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main,
        flowDismissed: @escaping () -> Void
    ) {
        self.supportedPaymentRequestType = supportedPaymentRequestType
        paymentRequestSummaryList = PaymentRequestSummaryList.makeInitial(state: visibleState)
        self.profile = profile
        self.featureService = featureService
        self.router = router
        self.paymentRequestListUseCase = paymentRequestListUseCase
        self.paymentRequestsListViewModelFactory = paymentRequestsListViewModelFactory
        self.imageLoader = imageLoader
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: PaymentRequestsListAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
        self.scheduler = scheduler
        self.flowDismissed = flowDismissed
    }
}

// MARK: - Helpers

private extension PaymentRequestsListPresenterImpl {
    enum PaymentRequestSummariesUpdatingStrategy {
        case forceUpdating
        case forceUpdatingWithoutLoadingIndicator
        case useCacheFirst

        var isForceUpdating: Bool {
            switch self {
            case .forceUpdating,
                 .forceUpdatingWithoutLoadingIndicator:
                true
            case .useCacheFirst:
                false
            }
        }

        var shouldShowLoadingIndicator: Bool {
            switch self {
            case .forceUpdating,
                 .useCacheFirst:
                true
            case .forceUpdatingWithoutLoadingIndicator:
                false
            }
        }
    }

    func getSummariesWritableKeyPath() -> WritableKeyPath<PaymentRequestSummaryList, PaymentRequestSummaries> {
        switch paymentRequestSummaryList.visibleState {
        case .unpaid(.closestToExpiry):
            \.unpaid.closestToExpiry
        case .unpaid(.mostRecentlyRequested):
            \.unpaid.mostRecentlyRequested
        case .paid:
            \.paid
        case .active:
            \.active
        case .inactive:
            \.inactive
        case .upcoming(.closestToExpiry):
            \.upcoming.closestToExpiry
        case .upcoming(.mostRecentlyRequested):
            \.upcoming.mostRecentlyRequested
        case .past:
            \.past
        }
    }

    func getPaymentRequestSummaryListStateForSingleUseAndReusable(from indexOfChip: Int) -> PaymentRequestSummaryList.State? {
        switch indexOfChip {
        case 0:
            .active
        case 1:
            .inactive
        default:
            nil
        }
    }

    func getPaymentRequestSummaryListStateForSingleUseOnly(from indexOfChip: Int) -> PaymentRequestSummaryList.State? {
        switch indexOfChip {
        case 0:
            .unpaid(paymentRequestSummaryList.unpaid.visibleState)
        case 1:
            .paid
        default:
            nil
        }
    }

    func getPaymentRequestSummaryListStateForInvoice(from indexOfChip: Int) -> PaymentRequestSummaryList.State? {
        switch indexOfChip {
        case 0:
            .upcoming(paymentRequestSummaryList.upcoming.visibleState)
        case 1:
            .past
        default:
            nil
        }
    }

    func getPaymentRequestSummaryListState(from indexOfChip: Int) -> PaymentRequestSummaryList.State? {
        switch supportedPaymentRequestType {
        case .singleUseAndReusable:
            getPaymentRequestSummaryListStateForSingleUseAndReusable(from: indexOfChip)
        case .singleUseOnly:
            getPaymentRequestSummaryListStateForSingleUseOnly(from: indexOfChip)
        case .invoiceOnly:
            getPaymentRequestSummaryListStateForInvoice(from: indexOfChip)
        }
    }

    func trackChipChange() {
        let chipName =
            switch paymentRequestSummaryList.visibleState {
            case .unpaid:
                "Unpaid"
            case .paid:
                "Paid"
            case .active:
                "Active"
            case .inactive:
                "Inactive"
            case .upcoming:
                "Upcoming"
            case .past:
                "Past"
            }
        let action = PaymentRequestsListAnalyticsView.TabChange(tab: chipName)
        analyticsViewTracker.track(action)
    }

    func getPaymentRequestStatuses() -> [PaymentRequestApiStatus] {
        switch paymentRequestSummaryList.visibleState {
        case .inactive,
             .past:
            [.completed, .invalidated, .expired]
        case .unpaid,
             .active,
             .upcoming:
            [.published]
        case .paid:
            [.completed]
        }
    }

    func getPaymentRequestTypes() -> [PaymentRequestSummariesApiRequestType] {
        switch supportedPaymentRequestType {
        case .singleUseAndReusable:
            [
                .singleUse,
                .reusable,
            ]
        case .singleUseOnly:
            [.singleUse]
        case .invoiceOnly:
            [.invoice]
        }
    }

    func getSortDescriptor() -> PaymentRequestSummariesApiSortDescriptor {
        switch paymentRequestSummaryList.visibleState {
        case .unpaid(.closestToExpiry),
             .upcoming(.closestToExpiry):
            PaymentRequestSummariesApiSortDescriptor(
                sortBy: .expirationAt,
                sortOrder: .ascend
            )
        case .unpaid(.mostRecentlyRequested),
             .upcoming(.mostRecentlyRequested),
             .active:
            PaymentRequestSummariesApiSortDescriptor(
                sortBy: .publishedAt,
                sortOrder: .descend
            )
        case .paid,
             .inactive,
             .past:
            PaymentRequestSummariesApiSortDescriptor(
                sortBy: .updatedAt,
                sortOrder: .descend
            )
        }
    }

    func fetchPaymentRequestSummaries(seekPosition: String? = nil) -> AnyPublisher<PaymentRequestSummaries, Error> {
        paymentRequestListUseCase.paymentRequestSummaries(
            profileId: profile.id,
            statuses: getPaymentRequestStatuses(),
            requestTypes: getPaymentRequestTypes(),
            sortDescriptor: getSortDescriptor(),
            pageSize: 30,
            seekPosition: seekPosition
        )
    }

    func fetchPaymentRequestSummariesIfNeeded(
        updatingStrategy: PaymentRequestSummariesUpdatingStrategy
    ) {
        let summariesKeyPath = getSummariesWritableKeyPath()
        let summaries = paymentRequestSummaryList[keyPath: summariesKeyPath]
        let shouldFetchPaymentRequestSummaries = updatingStrategy.isForceUpdating || summaries.groups.isEmpty
        guard shouldFetchPaymentRequestSummaries else {
            let viewModel = paymentRequestsListViewModelFactory.make(
                supportedPaymentRequestType: supportedPaymentRequestType,
                profile: profile,
                paymentRequestSummaryList: paymentRequestSummaryList,
                delegate: self
            )
            view?.configure(with: viewModel)
            return
        }
        if updatingStrategy.shouldShowLoadingIndicator {
            view?.showLoading()
        }
        fetchPaymentRequestSummariesCancellable = fetchPaymentRequestSummaries()
            .receive(on: scheduler)
            .asResult()
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                if updatingStrategy.shouldShowLoadingIndicator {
                    view?.hideLoading()
                }
                switch result {
                case let .success(paymentRequestSummaries):
                    if updatingStrategy.isForceUpdating {
                        paymentRequestSummaryList[keyPath: summariesKeyPath] = paymentRequestSummaries
                    } else {
                        let oldSummaries = paymentRequestSummaryList[keyPath: summariesKeyPath]
                        paymentRequestSummaryList[keyPath: summariesKeyPath] = oldSummaries.appending(paymentRequestSummaries)
                    }
                    let viewModel = paymentRequestsListViewModelFactory.make(
                        supportedPaymentRequestType: supportedPaymentRequestType,
                        profile: profile,
                        paymentRequestSummaryList: paymentRequestSummaryList,
                        delegate: self
                    )
                    view?.configure(with: viewModel)
                case .failure:
                    view?.showDismissableAlert(
                        title: L10n.Generic.Error.title,
                        message: L10n.Generic.Error.message
                    )
                }
            }
    }

    func getSeekPosition(
        id: String,
        summariesKeyPath: KeyPath<PaymentRequestSummaryList, PaymentRequestSummaries>
    ) -> String? {
        let summaries = paymentRequestSummaryList[keyPath: summariesKeyPath]
        guard summaries.groups.last?.summaries.last?.id == id,
              case let .hasNextPage(seekPosition) = summaries.nextPageState else {
            return nil
        }
        return seekPosition
    }

    func resetPaymentRequestSummaryListButKeepVisibleStates() {
        let summariesKeyPath = getSummariesWritableKeyPath()
        let visibleSummaries = paymentRequestSummaryList[keyPath: summariesKeyPath]
        let visibleState = paymentRequestSummaryList.visibleState
        let visibleUnpaidState = paymentRequestSummaryList.unpaid.visibleState
        paymentRequestSummaryList = PaymentRequestSummaryList.makeInitial(state: visibleState)
        paymentRequestSummaryList.unpaid.visibleState = visibleUnpaidState
        paymentRequestSummaryList[keyPath: summariesKeyPath] = visibleSummaries
    }

    func reloadPaymentRequestSummaryListButKeepVisibleStates(
        updatingStrategy: PaymentRequestSummariesUpdatingStrategy
    ) {
        resetPaymentRequestSummaryListButKeepVisibleStates()
        fetchPaymentRequestSummariesIfNeeded(
            updatingStrategy: updatingStrategy
        )
    }

    func configureWithGlobalEmptyState() {
        let viewModel = paymentRequestsListViewModelFactory.makeGlobalEmptyState(
            supportedPaymentRequestType: supportedPaymentRequestType,
            delegate: self
        )

        view?.configure(with: viewModel)
    }
}

// MARK: - PaymentRequestsListPresenter

extension PaymentRequestsListPresenterImpl: PaymentRequestsListPresenter {
    func createNewRequest() {
        let (isInvoice, target): (Bool, PaymentRequestsListAnalyticsView.CreateTapped.Target) =
            switch supportedPaymentRequestType {
            case .invoiceOnly:
                (true, .invoice)
            case .singleUseOnly,
                 .singleUseAndReusable:
                (false, .paymentRequest)
            }
        let action = PaymentRequestsListAnalyticsView.CreateTapped(target: target)
        analyticsViewTracker.track(action)
        if isInvoice {
            router.showCreateInvoiceOnWeb(
                profileId: profile.id,
                listUpdateDelegate: self
            )
        } else {
            router.showNewRequestFlow(
                profile: profile,
                listUpdateDelegate: self
            )
        }
    }

    func dismiss() {
        flowDismissed()
    }

    func start(with view: PaymentRequestsListView) {
        self.view = view

        paymentRequestStatusCancellable = paymentRequestListUseCase
            .paymentRequestStatus(profileId: profile.id, requestTypes: getPaymentRequestTypes())
            .asResult()
            .sink { [weak self] result in
                guard let self else { return }

                switch result {
                case let .success(status):
                    switch status {
                    case .hasPaymentRequests:
                        fetchPaymentRequestSummariesIfNeeded(
                            updatingStrategy: .forceUpdating
                        )
                    case .noPaymentRequests:
                        configureWithGlobalEmptyState()
                    }
                case .failure:
                    view.showDismissableAlert(
                        title: L10n.Generic.Error.title,
                        message: L10n.Generic.Error.message
                    )
                }
            }
    }

    func rowTapped(id: String) {
        router.showRequestDetail(
            paymentRequestId: PaymentRequestId(id),
            profile: profile,
            listUpdateDelegate: self
        )
    }

    func prefetch(id: String) {
        let summariesKeyPath = getSummariesWritableKeyPath()
        guard let seekPosition = getSeekPosition(id: id, summariesKeyPath: summariesKeyPath) else {
            return
        }
        prefetchPaymentRequestSummariesCancellable = fetchPaymentRequestSummaries(seekPosition: seekPosition)
            .receive(on: scheduler)
            .asResult()
            .sink { [weak self] result in
                guard let self,
                      let newSummaries = result.value else {
                    return
                }
                let oldSummaries = paymentRequestSummaryList[keyPath: summariesKeyPath]
                paymentRequestSummaryList[keyPath: summariesKeyPath] = oldSummaries.appending(newSummaries)
                let newSections = paymentRequestsListViewModelFactory.makeSectionViewModels(
                    paymentRequestSummaryList: paymentRequestSummaryList,
                    groups: newSummaries.groups,
                    delegate: self
                )
                view?.showNewSections(newSections)
            }
    }

    func refresh() {
        reloadPaymentRequestSummaryListButKeepVisibleStates(
            updatingStrategy: .forceUpdating
        )
    }
}

// MARK: - PaymentRequestsListViewModelDelegate

extension PaymentRequestsListPresenterImpl: PaymentRequestsListViewModelDelegate {
    func openSettingsTapped() {
        router.showMethodManagementOnWeb(profileId: profile.id)
    }

    func segmentedControlSelected(at index: Int) {
        guard let newState = getPaymentRequestSummaryListState(from: index),
              newState != paymentRequestSummaryList.visibleState else {
            return
        }
        paymentRequestSummaryList.visibleState = newState
        trackChipChange()
        fetchPaymentRequestSummariesIfNeeded(
            updatingStrategy: .useCacheFirst
        )
    }

    func sortTapped() {
        let sortingState = supportedPaymentRequestType == .invoiceOnly
            ? paymentRequestSummaryList.upcoming.visibleState
            : paymentRequestSummaryList.unpaid.visibleState
        let viewModel = paymentRequestsListViewModelFactory.makeRadioOptionsViewModel(
            sortingState: sortingState,
            delegate: self
        )
        view?.showRadioOptions(viewModel: viewModel)
    }

    func fetchAvatarModel(
        urlString: String,
        badge: UIImage?,
        fallbackModel: ContactsKit.AvatarModel
    ) -> AnyPublisher<ContactsKit.AvatarModel, Never> {
        guard let url = URL(string: urlString) else {
            return .just(fallbackModel)
        }
        return imageLoader.load(.url(url))
            .map { image in
                AvatarModel.image(image, badge: badge)
            }
            .replaceError(with: fallbackModel)
            .eraseToAnyPublisher()
    }

    func sortingOptionTapped(at index: Int) {
        guard let newState = PaymentRequestSummaryList.SortingState.allCases[safe: index] else {
            return
        }
        if supportedPaymentRequestType == .invoiceOnly {
            paymentRequestSummaryList.visibleState = .upcoming(newState)
            paymentRequestSummaryList.upcoming.visibleState = newState
        } else {
            paymentRequestSummaryList.visibleState = .unpaid(newState)
            paymentRequestSummaryList.unpaid.visibleState = newState
        }
        let viewModel = paymentRequestsListViewModelFactory.makeRadioOptionsViewModel(
            sortingState: newState,
            delegate: self
        )
        view?.updateRadioOptions(viewModel: viewModel)
    }

    func applySortingAction() {
        view?.dismissRadioOptions()
        fetchPaymentRequestSummariesIfNeeded(
            updatingStrategy: .useCacheFirst
        )
    }

    func createRequestPaymentTapped() {
        createNewRequest()
    }

    func learnMoreTapped() {
        let articleId = supportedPaymentRequestType == .invoiceOnly
            ? Constants.invoicesHelpArticleId
            : Constants.requestsHelpArticleId

        router.showHelpArticle(articleId: articleId)
    }
}

// MARK: - PaymentRequestListUpdater

extension PaymentRequestsListPresenterImpl: PaymentRequestListUpdater {
    func requestStatusUpdated() {
        reloadPaymentRequestSummaryListButKeepVisibleStates(
            updatingStrategy: .forceUpdatingWithoutLoadingIndicator
        )
    }

    func invoiceRequestCreated() {
        reloadPaymentRequestSummaryListButKeepVisibleStates(
            updatingStrategy: .forceUpdating
        )
    }
}
