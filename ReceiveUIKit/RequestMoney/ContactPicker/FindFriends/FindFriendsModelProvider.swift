import Foundation
import Neptune
import TransferResources
import TWUI

struct FindFriendsModelProvider {
    var models: [FindFriendsViewModel] {
        [
            FindFriendsViewModel(
                title: L10n.Crossbalance.Onboarding.First.title,
                subtitle: L10n.Crossbalance.Onboarding.First.description,
                asset: .image(Illustrations.magnifyingGlass.image)
            ),
            FindFriendsViewModel(
                title: L10n.Crossbalance.Onboarding.Second.title,
                subtitle: L10n.Crossbalance.Onboarding.Second.description,
                asset: .image(Illustrations.globe.image)
            ),
            FindFriendsViewModel(
                title: L10n.Crossbalance.Onboarding.Third.title,
                subtitle: L10n.Crossbalance.Onboarding.Third.description,
                asset: .image(Illustrations.gear.image)
            ),
        ]
    }
}
