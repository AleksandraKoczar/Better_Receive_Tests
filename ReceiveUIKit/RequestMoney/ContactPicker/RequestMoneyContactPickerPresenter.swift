import AnalyticsKit
import Combine
import CombineSchedulers
import ContactsKit
import Foundation
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol RequestMoneyContactPickerPresenter: AnyObject {
    func start(with: RequestMoneyContactPickerView)
    func startSearch()
    func select(contact: Contact?)
    func inviteFriendsTapped()
    func findFriendsTapped()
    func nudgeDismissed(nudgeType: ContactPickerNudgeType)
    func loadMore()
    func dismiss()
}

final class RequestMoneyContactPickerPresenterImpl {
    private enum Constants {
        static let defaultPageSize = 20
    }

    private let router: RequestMoneyContactPickerRouter
    private let contactListPagePublisherFactory: ContactListPagePublisherFactory
    private let nudgeProvider: ContactPickerNudgeProvider
    private let notificationCenter: NotificationCenter
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<RequestMoneyContactPickerAnalyticsView>
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let input = PassthroughSubject<ContactListInput, Never>()
    private let mapper: RequestMoneyContactPickerMapper

    private let profile: Profile

    private weak var view: RequestMoneyContactPickerView?
    private var contactsListNextPageCancellable: AnyCancellable?
    private var recentContactsCancellable: AnyCancellable?
    private var nudgesCancellable: AnyCancellable?
    private var hasOngoingRequest = false

    private var contactLists: [ContactList] = []
    private var recentContacts: [Contact] = []
    private var nudge: NudgeViewModel?

    private var contacts: [Contact] {
        contactLists.flatMap {
            $0.contacts
        }
    }

    private lazy var recentContactsInput = CurrentValueSubject<ContactListPageInput, Never>(
        self.recentContactsContext()
    )

    init(
        profile: Profile,
        contactListPagePublisherFactory: ContactListPagePublisherFactory,
        nudgeProvider: ContactPickerNudgeProvider,
        mapper: RequestMoneyContactPickerMapper,
        router: RequestMoneyContactPickerRouter,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main,
        notificationCenter: NotificationCenter = .default
    ) {
        self.profile = profile
        self.contactListPagePublisherFactory = contactListPagePublisherFactory
        self.nudgeProvider = nudgeProvider
        self.mapper = mapper
        self.router = router
        self.scheduler = scheduler
        self.notificationCenter = notificationCenter
        analyticsViewTracker = AnalyticsViewTrackerImpl<RequestMoneyContactPickerAnalyticsView>(
            contextIdentity: RequestMoneyContactPickerAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }
}

// MARK: - RequestMoneyContactPickerPresenter

extension RequestMoneyContactPickerPresenterImpl: RequestMoneyContactPickerPresenter {
    func start(with view: RequestMoneyContactPickerView) {
        self.view = view
        analyticsViewTracker.trackView(.started)
        createSubscription()
        fetchContacts()
        fetchNudges()
        createRecentContactsSubscription()
        updateView()

        let notifications = [
            Notification.Name.contactAdded,
            .contactDeleted,
            .contactUpdated,
        ]
        notifications.forEach {
            notificationCenter.addObserver(
                self,
                selector: #selector(contactsChanged),
                name: $0,
                object: nil
            )
        }
    }

    func startSearch() {
        router.startSearch()
    }

    func loadMore() {
        fetchContacts()
    }

    func select(contact: Contact?) {
        if contact != nil {
            analyticsViewTracker.track(
                RequestMoneyContactPickerAnalyticsView.ContactSelected()
            )
        } else {
            analyticsViewTracker.track(
                RequestMoneyContactPickerAnalyticsView.CreateLinkSelected(
                    hasContacts: contacts.isNonEmpty
                )
            )
        }
        createPaymentLink(contact: contact)
    }

    func dismiss() {
        router.dismiss()
    }

    func inviteFriendsTapped() {
        router.inviteFriendsNudgeTapped()
    }

    func findFriendsTapped() {
        router.findFriendsNudgeTapped()
    }

    func nudgeDismissed(nudgeType: ContactPickerNudgeType) {
        nudgeProvider.nudgeDismissed(nudgeType)
        fetchNudges()
    }
}

// MARK: - Data Helpers

private extension RequestMoneyContactPickerPresenterImpl {
    func createSubscription() {
        contactsListNextPageCancellable = contactListPagePublisherFactory.makeNextPage(
            profileId: profile.id,
            input: input.eraseToAnyPublisher()
        )
        .receive(on: scheduler)
        .asResult()
        .sink { [weak self] result in
            guard let self else { return }
            hasOngoingRequest = false
            view?.hideLoading()
            switch result {
            case let .success(contactList):
                if contacts.isEmpty {
                    analyticsViewTracker.track(
                        RequestMoneyContactPickerAnalyticsView.LoadedAction(
                            hasContacts: contactList.contacts.isNonEmpty
                        )
                    )
                }
                if contactList.contacts.isNonEmpty {
                    contactLists.append(contactList)
                    updateView()
                }

            case let .failure(error):
                analyticsViewTracker.track(
                    RequestMoneyContactPickerAnalyticsView.LoadingFailed(
                        hasContacts: contacts.isNonEmpty,
                        message: error.localizedDescription
                    )
                )
                view?.showErrorAlert(
                    title: L10n.Generic.Error.title,
                    message: L10n.Generic.Error.message
                )
            }
        }
    }

    func fetchContacts() {
        let contactCursor = contactLists.last?.nextPage
        if hasOngoingRequest
            || (contactLists.isNonEmpty && contactCursor == nil) {
            return
        }

        hasOngoingRequest = true
        view?.showLoading()
        input.send(
            Self.makeContactListInput(
                pageCursor: contactCursor,
                size: Constants.defaultPageSize
            )
        )
    }

    func fetchNudges() {
        nudgesCancellable = nudgeProvider.nudge
            .flatMap { [weak self] nudge -> AnyPublisher<ContactPickerNudgeModel, Error> in
                guard let self, let nudge else { return .fail(with: GenericError("no nudge to fetch")) }
                return nudgeProvider.getContentForNudge(nudge)
            }
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(model):
                    nudge = mapNudge(model: model)
                case .failure:
                    nudge = nil
                }
                updateView()
            }
    }

    func mapNudge(model: ContactPickerNudgeModel) -> NudgeViewModel {
        switch model.type {
        case .findFriends:
            NudgeViewModel(
                title: model.title,
                asset: model.icon,
                ctaTitle: model.ctaTitle,
                onSelect: { [weak self] in
                    guard let self else { return }
                    findFriendsTapped()
                },
                onDismiss: { [weak self] in
                    guard let self else { return }
                    nudgeDismissed(nudgeType: .findFriends)
                }
            )
        case .inviteFriends:
            NudgeViewModel(
                title: model.title,
                asset: model.icon,
                ctaTitle: model.ctaTitle,
                onSelect: { [weak self] in
                    guard let self else { return }
                    inviteFriendsTapped()
                },
                onDismiss: { [weak self] in
                    guard let self else { return }
                    nudgeDismissed(nudgeType: .inviteFriends)
                }
            )
        }
    }

    func createRecentContactsSubscription() {
        recentContactsCancellable = contactListPagePublisherFactory.make(
            profileId: profile.id,
            input: recentContactsInput.eraseToAnyPublisher()
        )
        .map { contactListPage -> [Contact] in
            contactListPage.recent?.contacts ?? []
        }
        .asResult()
        .receive(on: scheduler)
        .sink { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(contacts):
                if contacts.isNonEmpty {
                    recentContacts = contacts
                    updateView()
                }
            case .failure:
                view?.showErrorAlert(
                    title: L10n.Generic.Error.title,
                    message: L10n.Generic.Error.message
                )
            }
        }
    }
}

// MARK: - View Update

private extension RequestMoneyContactPickerPresenterImpl {
    func updateView() {
        let viewModel = mapper.makeModel(
            recentContacts: recentContacts,
            contacts: contacts,
            contactList: contactLists,
            nudge: nudge
        )
        view?.configure(viewModel: viewModel)
    }
}

// MARK: - Routing Helpers

private extension RequestMoneyContactPickerPresenterImpl {
    func createPaymentLink(contact: Contact?) {
        router.createPaymentRequest(
            contact: contact
        )
    }
}

// MARK: - Request Helpers

private extension RequestMoneyContactPickerPresenterImpl {
    static func makeContactListInput(
        pageCursor: ContactListPageCursor?,
        size: Int
    ) -> ContactListInput {
        ContactListInput(
            // TODO: Change to `frequent` when BE ready
            filter: .notOwnedByCustomer,
            page: ContactListInput.Page(
                page: pageCursor,
                pageSize: size
            ),
            context: context()
        )
    }

    static func context() -> ContactContext {
        ContactContext.parameters(
            ContactContext.Parameters(
                action: ContactAction.request,
                sourceCurrency: nil,
                targetCurrency: nil,
                sourceAmount: nil,
                targetAmount: nil,
                includeExternalIdentifiers: false,
                includeExistingContacts: true,
                legalEntityType: nil
            )
        )
    }

    // TODO: check with BE if .request should be used as action
    func recentContactsContext() -> ContactListPageInput {
        ContactListPageInput(
            recentContactsPageSize: 5,
            contactsPageSize: 20,
            context: ContactContext.parameters(
                ContactContext.Parameters(
                    action: .request,
                    sourceCurrency: nil,
                    targetCurrency: nil,
                    sourceAmount: nil,
                    targetAmount: nil,
                    includeExternalIdentifiers: false,
                    includeExistingContacts: true,
                    legalEntityType: nil
                )
            )
        )
    }
}

// MARK: - Observers

private extension RequestMoneyContactPickerPresenterImpl {
    @objc
    func contactsChanged() {
        contactLists = []
        view?.reset()
        fetchContacts()
    }
}
