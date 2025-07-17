import ContactsKitTestingSupport
import Dependencies
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport

final class ContactPickerNudgeProviderTests: TWTestCase {
    private var provider: ContactPickerNudgeProviderImpl!
    private var inviteFriendsPreferenceStorage: ContactPickerInviteFriendsPreferenceStorageMock!
    private var discoveryService: ContactSyncDiscoveryServiceMock!
    private var userProvider: StubUserProvider!

    override func setUp() async throws {
        try await super.setUp()

        inviteFriendsPreferenceStorage = ContactPickerInviteFriendsPreferenceStorageMock()
        inviteFriendsPreferenceStorage.inviteFriendsPreferenceReturnValue = true
        userProvider = .init()
        userProvider.addPersonalProfile(asActive: true)

        discoveryService = .init()
        discoveryService.discoveryNudgeVisible = .just(true)

        provider = ContactPickerNudgeProviderImpl(
            userProvider: userProvider,
            discoveryService: discoveryService,
            inviteStorage: inviteFriendsPreferenceStorage
        )
    }

    override func tearDown() async throws {
        provider = nil
        inviteFriendsPreferenceStorage = nil
        userProvider = nil
        discoveryService = nil
        try await super.tearDown()
    }

    func test_givenInviteFriendsNudgeType_thenReturnCorrectItem() throws {
        let result = try awaitPublisher(
            provider.getContentForNudge(.inviteFriends)
        )

        let actual = try XCTUnwrap(result.value)
        let expected = ContactPickerNudgeModel(
            type: .inviteFriends,
            title: "Invite your friends to Wise to request from them",
            icon: .plane,
            ctaTitle: "Invite friends"
        )
        expectNoDifference(actual, expected)
    }

    func test_findFriendsNudgeType_thenReturnCorrectItem()
        throws {
        inviteFriendsPreferenceStorage.inviteFriendsPreferenceReturnValue = true

        let result = try awaitPublisher(
            provider.getContentForNudge(.findFriends)
        )

        let actual = try XCTUnwrap(result.value)
        let expected = ContactPickerNudgeModel(
            type: .findFriends,
            title: "Turn on contacts and request from friends",
            icon: .wallet,
            ctaTitle: "Find friends"
        )
        expectNoDifference(actual, expected)
    }

    func test_invitePreferenceEnabled_AndContactsDisabled_thenShowFindFriendsFirst() throws {
        discoveryService.discoveryNudgeVisible = .just(true)
        inviteFriendsPreferenceStorage.inviteFriendsPreferenceReturnValue = true

        let provider = withDependencies({
            $0.receiveInviteService.fetchInviteAvailability = { _ in true }
        }) {
            ContactPickerNudgeProviderImpl(
                userProvider: userProvider,
                discoveryService: discoveryService,
                inviteStorage: inviteFriendsPreferenceStorage
            )
        }

        try awaitPublisherMatching(provider.nudge) { $0 == .findFriends }
    }

    func test_invitePreferenceEnabled_AndContactsEnabled_thenShowInviteFriendsFirst() throws {
        discoveryService.discoveryNudgeVisible = .just(false)
        inviteFriendsPreferenceStorage.inviteFriendsPreferenceReturnValue = true

        let provider = withDependencies({
            $0.receiveInviteService.fetchInviteAvailability = { _ in true }
        }) {
            ContactPickerNudgeProviderImpl(
                userProvider: userProvider,
                discoveryService: discoveryService,
                inviteStorage: inviteFriendsPreferenceStorage
            )
        }

        try awaitPublisherMatching(provider.nudge) { $0 == .inviteFriends }
    }

    func test_givenInviteFriendsPreferenceIsFalse_AndContactsEnabled_ReturnNudgeIsNil() throws {
        discoveryService.discoveryNudgeVisible = .just(false)
        inviteFriendsPreferenceStorage.inviteFriendsPreferenceReturnValue = false

        let provider = ContactPickerNudgeProviderImpl(
            userProvider: userProvider,
            discoveryService: discoveryService,
            inviteStorage: inviteFriendsPreferenceStorage
        )

        try awaitPublisherMatching(provider.nudge) { $0 == nil }
    }

    func test_givenInviteNudgeDismissed_AndContactsEnabled_thenSaveToStorage_AndNudgeIsNil() throws {
        discoveryService.discoveryNudgeVisible = .just(false)
        provider.nudgeDismissed(.inviteFriends)

        XCTAssertEqual(inviteFriendsPreferenceStorage.inviteFriendsPreferenceCallsCount, 1)
        try awaitPublisherMatching(provider.nudge) { $0 == nil }
    }

    func test_givenInviteUnavailable_AndContactsDisabled_ThenNudgeIsNil() throws {
        discoveryService.discoveryNudgeVisible = .just(false)

        let provider = withDependencies({
            $0.receiveInviteService.fetchInviteAvailability = { _ in false }
        }) {
            ContactPickerNudgeProviderImpl(
                userProvider: userProvider,
                discoveryService: discoveryService,
                inviteStorage: inviteFriendsPreferenceStorage
            )
        }

        try awaitPublisherMatching(provider.nudge) { $0 == nil }
    }
}
