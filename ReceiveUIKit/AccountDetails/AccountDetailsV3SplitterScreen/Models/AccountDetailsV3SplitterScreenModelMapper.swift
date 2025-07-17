import Neptune
import ReceiveKit
import UIKit
import WiseAtomsIcons
import WiseCore

enum AccountDetailsV3SplitterScreenModelMapper {
    static func mapSplitterScreen(
        currency: CurrencyCode,
        receiveMethodNavigation: ReceiveMethodNavigation,
        delegate: ReceiveMethodNavigationDelegate?
    ) -> AccountDetailsV3SplitterScreenViewModel {
        let items = receiveMethodNavigation.sections.first?.items.map { item in
            AccountDetailsV3SplitterScreenViewModel.ItemViewModel(
                title: item.title,
                subtitle: item.subtitle,
                body: item.body,
                avatar: makeAvatar(from: item.avatars.first?.value, badge: item.badge),
                onTapAction: { [weak delegate] in
                    switch item.action.payload {
                    case .unknown: break
                    case let .order(orderAction):
                        delegate?.handleAction(action: .order(
                            currency: orderAction.currency,
                            balanceId: orderAction.balanceId,
                            methodType: orderAction.methodType
                        ))
                    case let .query(queryAction):
                        delegate?.handleAction(action: .query(
                            context: queryAction.context,
                            currency: queryAction.currency,
                            groupId: queryAction.groupId,
                            balanceId: queryAction.balanceId,
                            methodTypes: queryAction.methodTypes
                        ))
                    case let .view(viewAction):
                        delegate?.handleAction(action: .view(id: viewAction.id, methodType: viewAction.methodType))
                    }
                },
                state: mapState(state: item.state)
            )
        }

        return AccountDetailsV3SplitterScreenViewModel(currency: currency, items: items ?? [])
    }

    static func makeAvatar(from value: String?, badge: ReceiveMethodNavigation.Badge?) -> AvatarViewModel {
        let image = makeIcon(from: value)
        let badge = makeBadge(from: badge?.value)
        return .icon(image, badge: badge)
    }

    static func makeIcon(from urnString: String?) -> UIImage {
        guard let urnString,
              let urn = try? URN(urnString),
              let icon = IconFactory.icon(urn: urn) else {
            return Icons.bank.image
        }
        return icon
    }

    static func makeBadge(from urnString: String?) -> UIImage? {
        guard let urnString,
              let urn = try? URN(urnString),
              let badgeIcon = IconFactory.icon(urn: urn) else {
            return nil
        }
        return badgeIcon
    }

    private static func mapState(state: ReceiveMethodNavigation.ReceiveMethodState) -> AccountDetailsV3SplitterScreenViewModel.AccountDetailsV3State {
        switch state {
        case .active:
            .active
        case .disabled:
            .active
        case .available:
            .available
        }
    }
}
