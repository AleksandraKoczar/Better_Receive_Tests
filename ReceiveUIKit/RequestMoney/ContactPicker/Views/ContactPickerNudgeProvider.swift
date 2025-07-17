import Combine
import ContactsKit
import Dependencies
import Foundation
import Neptune
import TransferResources
import TWFoundation
import UserKit
import WiseCore

// sourcery: Buildable
enum ContactPickerNudgeType: Hashable {
    case findFriends
    case inviteFriends
}

// sourcery: AutoMockable
protocol ContactPickerNudgeProvider: AnyObject {
    func nudgeDismissed(_ nudge: ContactPickerNudgeType)
    func getContentForNudge(_ nudge: ContactPickerNudgeType) -> AnyPublisher<ContactPickerNudgeModel, Error>
    var nudge: AnyPublisher<ContactPickerNudgeType?, Never> { get }
}

final class ContactPickerNudgeProviderImpl: ContactPickerNudgeProvider {
    private let userProvider: UserProvider
    private let discoveryService: ContactSyncDiscoveryService
    private let inviteStorage: ContactPickerInviteFriendsPreferenceStorage
    @Dependency(\.receiveInviteService)
    private var receiveInviteService

    private var userId: UserId { userProvider.user.userId }
    private var shouldShowInviteFriendsNudge = CurrentValueSubject<Bool, Never>(false)

    init(
        userProvider: UserProvider,
        discoveryService: ContactSyncDiscoveryService = GOS[ContactSyncDiscoveryServiceKey.self],
        inviteStorage: ContactPickerInviteFriendsPreferenceStorage
    ) {
        self.userProvider = userProvider
        self.discoveryService = discoveryService
        self.inviteStorage = inviteStorage
        let shouldShowInviteFriends = inviteStorage.inviteFriendsPreference(for: userId)
        shouldShowInviteFriendsNudge.send(shouldShowInviteFriends)
    }

    var nudge: AnyPublisher<ContactPickerNudgeType?, Never> {
        discoveryService.discoveryNudgeVisible
            .combineLatest(shouldShowInviteFriendsNudge)
            .flatMap { [weak self] shouldShowFindFriendsNudge, shouldShowInviteFriendsNudge in
                guard let self else {
                    return AnyPublisher<ContactPickerNudgeType?, Never>.just(nil)
                }
                if shouldShowFindFriendsNudge {
                    return .just(.findFriends)
                } else if shouldShowInviteFriendsNudge {
                    return inviteAvailablity()
                        .map { $0 ? ContactPickerNudgeType.inviteFriends : nil }
                        .eraseToAnyPublisher()
                } else {
                    return .just(nil)
                }
            }.eraseToAnyPublisher()
    }

    func nudgeDismissed(_ nudge: ContactPickerNudgeType) {
        switch nudge {
        case .findFriends:
            Task {
                try? await discoveryService.updateDiscoveryNudgeStatus(enabled: false)
            }
        case .inviteFriends:
            inviteStorage.setInviteFriendsPreference(false, for: userId)
            shouldShowInviteFriendsNudge.send(false)
        }
    }

    func getContentForNudge(_ nudge: ContactPickerNudgeType) -> AnyPublisher<ContactPickerNudgeModel, Error> {
        switch nudge {
        case .findFriends:
            let viewModel = ContactPickerNudgeModel(
                type: .findFriends,
                title: L10n.PaymentRequest.ContactPicker.FindFriendsNudge.title,
                icon: .wallet,
                ctaTitle: L10n.PaymentRequest.ContactPicker.FindFriendsNudge.cta
            )
            return .just(viewModel)
        case .inviteFriends:
            let viewModel = ContactPickerNudgeModel(
                type: .inviteFriends,
                title: L10n.PaymentRequest.ContactPicker.InviteFriendsNudge.title,
                icon: .plane,
                ctaTitle: L10n.PaymentRequest.ContactPicker.InviteFriendsNudge.cta
            )
            return .just(viewModel)
        }
    }

    func inviteAvailablity() -> AnyPublisher<Bool, Never> {
        Deferred { [weak self] in
            Future(asyncWork: {
                await self?.receiveInviteService.fetchInviteAvailability(profileId: self?.userProvider.activeProfile?.id) ?? false
            })
        }
        .eraseToAnyPublisher()
    }
}
