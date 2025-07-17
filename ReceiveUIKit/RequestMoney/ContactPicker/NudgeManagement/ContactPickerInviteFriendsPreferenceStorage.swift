import ReceiveKit
import TWFoundation
import WiseCore

// sourcery: AutoMockable
protocol ContactPickerInviteFriendsPreferenceStorage: AnyObject {
    func inviteFriendsPreference(for userId: UserId) -> Bool
    func setInviteFriendsPreference(_ preference: Bool, for userId: UserId)
}

final class ContactPickerInviteFriendsPreferenceStorageImpl: ContactPickerInviteFriendsPreferenceStorage {
    private enum Constants {
        static let inviteFriendsPreferencesKey = "ContactPickerInviteFriendsPreference-InvitedFriendsPreferences"
    }

    private struct PersistedPreference: Codable {
        let userId: Int64
        let preference: Bool
    }

    private let codableStore: CodableKeyValueStore

    init(
        codableStore: CodableKeyValueStore = UserDefaults.standard
    ) {
        self.codableStore = codableStore
    }

    func inviteFriendsPreference(for userId: UserId) -> Bool {
        guard let persistedPreferences: [PersistedPreference] = codableStore.codableObjectSafe(forKey: Constants.inviteFriendsPreferencesKey),
              let persistedPreference = persistedPreferences.first(where: { $0.userId == userId.value }) else {
            return true
        }
        return persistedPreference.preference
    }

    func setInviteFriendsPreference(
        _ preference: Bool,
        for userId: UserId
    ) {
        let newPersistedPreference = PersistedPreference(
            userId: userId.value,
            preference: preference
        )
        var preferencesToStore = [newPersistedPreference]
        if var persistedPreferences: [PersistedPreference] = codableStore.codableObjectSafe(forKey: Constants.inviteFriendsPreferencesKey) {
            persistedPreferences.removeAll(where: { $0.userId == userId.value })
            preferencesToStore.append(contentsOf: persistedPreferences)
        }
        codableStore.setCodableObjectSafe(preferencesToStore, forKey: Constants.inviteFriendsPreferencesKey)
    }
}
