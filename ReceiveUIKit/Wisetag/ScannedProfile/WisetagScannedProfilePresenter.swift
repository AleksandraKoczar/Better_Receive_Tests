import AnalyticsKit
import Combine
import CombineSchedulers
import ContactsKit
import LoggingKit
import TransferResources
import TWFoundation
import TWUI
import UserKit

internal struct ScannedProfileAnalyticsList {
    var isSelf = false
    var hasAvatar = false
    var isExisting = false
}

internal enum WisetagScannedProfileErrors: Error, Equatable {
    case failedToSendMoney
    case failedToRequestMoney
    case failedToAddRecipient
    case failedToFindContact
}

// sourcery: AutoMockable
protocol WisetagScannedProfilePresenter: AnyObject {
    func start(with view: WisetagScannedProfileView)
    func dismiss()
    func setBottomSheet(_ bottomSheet: BottomSheet?)
}

final class WisetagScannedProfilePresenterImpl {
    private weak var view: WisetagScannedProfileView?
    private weak var bottomSheet: BottomSheet?

    private let profile: Profile
    private let router: WisetagScannedProfileRouter
    private let viewModelMapper: WisetagScannedProfileViewModelMapper
    private var state: WisetagScannedProfileLoadingState = .findingUser
    private let scannedProfileNickname: String
    private let contactSearch: ContactSearch
    private let wisetagContactInteractor: WisetagContactInteractor
    private var fetchProfileCancellable: AnyCancellable?
    private var addContactCancellable: AnyCancellable?
    private var sendActionCancellable: AnyCancellable?
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<WisetagScannedProfileAnalyticsView>
    private var analyticsList: ScannedProfileAnalyticsList

    init(
        profile: Profile,
        scannedProfileNickname: String,
        contactSearch: ContactSearch,
        router: WisetagScannedProfileRouter,
        analyticsTracker: AnalyticsTracker,
        viewModelMapper: WisetagScannedProfileViewModelMapper,
        wisetagContactInteractor: WisetagContactInteractor,
        scheduler: AnySchedulerOf<DispatchQueue>
    ) {
        self.profile = profile
        self.viewModelMapper = viewModelMapper
        self.router = router
        self.wisetagContactInteractor = wisetagContactInteractor
        self.scannedProfileNickname = scannedProfileNickname
        self.contactSearch = contactSearch
        self.scheduler = scheduler
        analyticsList = ScannedProfileAnalyticsList()
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: WisetagScannedProfileAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }
}

extension WisetagScannedProfilePresenterImpl: WisetagScannedProfilePresenter {
    func start(with view: WisetagScannedProfileView) {
        self.view = view

        if contactSearch.contact.hasAvatar {
            analyticsList.hasAvatar = true
        }

        if contactSearch.isSelf {
            state = .isSelf(scannedProfile: contactSearch.contact)
            analyticsList.isSelf = true
            trackPageLoaded(
                isSelf: analyticsList.isSelf,
                isExisting: analyticsList.isExisting,
                hasAvatar: analyticsList.hasAvatar
            )
        } else {
            if let contactId = contactSearch.contact.id.contactId {
                analyticsList.isExisting = true
                trackPageLoaded(
                    isSelf: analyticsList.isSelf,
                    isExisting: analyticsList.isExisting,
                    hasAvatar: analyticsList.hasAvatar
                )
                state = .inContacts(scannedProfile: contactSearch.contact, contactId: contactId)
            } else {
                state = .userFound(scannedProfile: contactSearch.contact)
            }
        }
        configureView(state: state, nickname: scannedProfileNickname)
        analyticsViewTracker.track(WisetagScannedProfileAnalyticsView.Started())
    }

    func dismiss() {
        trackPageFinished(
            isSelf: analyticsList.isSelf,
            isExisting: analyticsList.isExisting,
            hasAvatar: analyticsList.hasAvatar,
            reason: WisetagScannedProfileFinishedReason.DISMISS
        )
        router.dismiss()
    }

    func setBottomSheet(_ bottomSheet: BottomSheet?) {
        self.bottomSheet = bottomSheet
    }
}

extension WisetagScannedProfilePresenterImpl: WisetagScannedProfileModelDelegate {
    func sendMoneyWithContactId(_ contactId: String) {
        sendActionCancellable = wisetagContactInteractor.resolveRecipient(
            profileId: profile.id,
            contactId: contactId
        )
        .receive(on: scheduler)
        .asResult()
        .sink { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case let .success(resolvedRecipient):
                trackPageFinished(
                    isSelf: analyticsList.isSelf,
                    isExisting: analyticsList.isExisting,
                    hasAvatar: analyticsList.hasAvatar,
                    reason: WisetagScannedProfileFinishedReason.SEND
                )
                router.sendMoney(resolvedRecipient, contactId: contactId)
            case .failure:
                showError(WisetagScannedProfileErrors.failedToSendMoney, previousState: state)
            }
        }
    }

    func sendMoneyWithoutContactId(_ scannedProfile: Contact) {
        sendActionCancellable = wisetagContactInteractor.createContact(
            profileId: profile.id,
            matchId: scannedProfile.id.stringValue
        )
        .flatMap { [weak self] contact -> AnyPublisher<RecipientResolved, Error> in

            guard let self, let contactId = contact.id.contactId else {
                return .fail(with: GenericError("[REC] Attempt to resolve recipient but the presenter is empty."))
            }
            return wisetagContactInteractor.resolveRecipient(profileId: profile.id, contactId: contactId)
        }
        .receive(on: scheduler)
        .asResult()
        .sink { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case let .success(resolvedRecipient):
                trackPageFinished(
                    isSelf: analyticsList.isSelf,
                    isExisting: analyticsList.isExisting,
                    hasAvatar: analyticsList.hasAvatar,
                    reason: WisetagScannedProfileFinishedReason.SEND
                )
                router.sendMoney(resolvedRecipient, contactId: scannedProfile.id.contactId)
            case .failure:
                showError(WisetagScannedProfileErrors.failedToSendMoney, previousState: state)
            }
        }
    }

    func sendButtonTapped() {
        switch state {
        case let .userFound(scannedProfile: scannedProfile):
            sendMoneyWithoutContactId(scannedProfile)
        case let .recipientAdded(scannedProfile: _, contactId: contactId):
            sendMoneyWithContactId(contactId)
        case .findingUser,
             .isSelf:
            softFailure("[REC] Attempt to send, but state is incorrect.")
        case let .inContacts(scannedProfile: _, contactId: contactId):
            sendMoneyWithContactId(contactId)
        }
    }

    func requestButtonTapped() {
        switch state {
        case let .userFound(scannedProfile: scannedProfile):
            addContactCancellable = wisetagContactInteractor.createContact(
                profileId: profile.id,
                matchId: scannedProfile.id.stringValue
            )
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                switch result {
                case let .success(contact):
                    trackPageFinished(
                        isSelf: analyticsList.isSelf,
                        isExisting: analyticsList.isExisting,
                        hasAvatar: analyticsList.hasAvatar,
                        reason: WisetagScannedProfileFinishedReason.REQUEST
                    )
                    router.requestMoney(contact)
                case .failure:
                    showError(WisetagScannedProfileErrors.failedToRequestMoney, previousState: state)
                }
            }
        case let .recipientAdded(scannedProfile: scannedProfile, contactId: _):
            trackPageFinished(
                isSelf: analyticsList.isSelf,
                isExisting: analyticsList.isExisting,
                hasAvatar: analyticsList.hasAvatar,
                reason: WisetagScannedProfileFinishedReason.REQUEST
            )
            router.requestMoney(scannedProfile)
        case .findingUser,
             .isSelf:
            softFailure("[REC] Attempt to request, but state is incorrect.")
        case let .inContacts(scannedProfile: scannedProfile, contactId: _):
            trackPageFinished(
                isSelf: analyticsList.isSelf,
                isExisting: analyticsList.isExisting,
                hasAvatar: analyticsList.hasAvatar,
                reason: WisetagScannedProfileFinishedReason.REQUEST
            )
            router.requestMoney(scannedProfile)
        }
    }

    func addRecipientButtonTapped() {
        switch state {
        case let .userFound(scannedProfile: scannedProfile):
            addContactCancellable = wisetagContactInteractor.createContact(
                profileId: profile.id,
                matchId: scannedProfile.id.stringValue
            )
            .asResult()
            .receive(on: scheduler)
            .sink { [weak self] result in
                guard let self else {
                    return
                }
                switch result {
                case let .success(contact):
                    guard let contactId = contact.id.contactId else {
                        showError(WisetagScannedProfileErrors.failedToAddRecipient, previousState: state)
                        return
                    }
                    trackPageAdded()
                    state = .recipientAdded(scannedProfile: contact, contactId: contactId)
                    configureView(state: state, nickname: scannedProfileNickname)
                case .failure:
                    showError(WisetagScannedProfileErrors.failedToAddRecipient, previousState: state)
                }
            }
        case .findingUser,
             .recipientAdded,
             .inContacts,
             .isSelf:
            softFailure("[REC] Attempt to add recipient, but state is incorrect.")
        }
    }
}

extension WisetagScannedProfilePresenterImpl {
    func configureView(state: WisetagScannedProfileLoadingState, nickname: String) {
        let viewModel = viewModelMapper.make(state: state, nickname: nickname, delegate: self)
        view?.configure(with: viewModel)
    }
}

extension WisetagScannedProfilePresenterImpl {
    private func showError(_ errorType: WisetagScannedProfileErrors, previousState: WisetagScannedProfileLoadingState) {
        var errorViewModel = ErrorViewModel(
            illustrationConfiguration: .warning,
            title: L10n.Generic.Error.title,
            message: .text(L10n.Generic.Error.message),
            primaryViewModel: .init(
                title: L10n.Card.Show.Pin.Error.button,
                handler: { [weak self] in
                    guard let self else { return }
                    configureView(state: previousState, nickname: scannedProfileNickname)
                }
            )
        )

        switch errorType {
        case .failedToFindContact:
            errorViewModel = ErrorViewModel(
                illustrationConfiguration: .warning,
                title: L10n.Wisetag.ScannedProfile.Error.FailedToFindContact.title,
                message: .text(L10n.Wisetag.ScannedProfile.Error.FailedToFindContact.subtitle),
                primaryViewModel: .init(
                    title: L10n.Card.Show.Pin.Error.button,
                    handler: { [weak self] in
                        guard let self else {
                            return
                        }
                        dismiss()
                    }
                )
            )
        case .failedToAddRecipient,
             .failedToRequestMoney,
             .failedToSendMoney:
            break
        }

        view?.configureError(with: errorViewModel)
    }

    func trackPageStarted() {
        analyticsViewTracker.track(WisetagScannedProfileAnalyticsView.Started())
    }

    func trackPageLoaded(isSelf: Bool, isExisting: Bool, hasAvatar: Bool) {
        analyticsViewTracker.track(WisetagScannedProfileAnalyticsView.Loaded(
            matchIsSelf: isSelf,
            matchIsExisting: isExisting,
            matchHasAvatar: hasAvatar
        ))
    }

    func trackPageFailed(reason: Error) {
        analyticsViewTracker.track(
            WisetagScannedProfileAnalyticsView.Failed(message: reason.nonLocalizedDescription)
        )
    }

    func trackPageAdded() {
        analyticsViewTracker.track(WisetagScannedProfileAnalyticsView.Added())
    }

    func trackPageFinished(isSelf: Bool, isExisting: Bool, hasAvatar: Bool, reason: WisetagScannedProfileFinishedReason) {
        analyticsViewTracker.track(WisetagScannedProfileAnalyticsView.Finished(
            finishedAction: reason,
            matchIsSelf: isSelf,
            matchIsExisting: isExisting,
            matchHasAvatar: hasAvatar
        ))
    }
}
