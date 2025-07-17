import Neptune
import ReceiveKit
import TransferResources
import UIKit
import WiseAtomsIcons
import WiseCore

enum AccountDetailsV3ListModelMapper {
    static func mapAccountDetailsList(
        receiveMethodNavigation: ReceiveMethodNavigation,
        delegate: ReceiveMethodNavigationDelegate?,
        trackOnSearchTapped: @escaping () -> Void
    ) -> AccountDetailsV3ListViewModel {
        let sections = mapSections(
            sections: receiveMethodNavigation.sections,
            delegate: delegate
        )
        return AccountDetailsV3ListViewModel(
            title: L10n.AccountDetailsV3.List.title,
            subtitle: L10n.AccountDetailsV3.List.subtitle,
            originalSections: sections,
            onSearchTapped: trackOnSearchTapped
        )
    }

    static func makeIcon(from urnString: String?) -> UIImage {
        guard let urnString,
              let urn = try? URN(urnString),
              let flagIcon = FlagFactory.flag(urn: urn) else {
            return Icons.fastFlag.image
        }
        return flagIcon
    }

    static func makeBadge(from urnString: String?) -> UIImage? {
        guard let urnString,
              let urn = try? URN(urnString),
              let badgeIcon = IconFactory.icon(urn: urn) else {
            return nil
        }
        return badgeIcon
    }

    static func makeAvatar(from value: String?, badge: ReceiveMethodNavigation.Badge?) -> AvatarViewModel {
        let image = makeIcon(from: value)
        let badge = makeBadge(from: badge?.value)
        return ._image(image, badge: badge)
    }

    static func mapSections(
        sections: [ReceiveMethodNavigation.Section],
        delegate: ReceiveMethodNavigationDelegate?
    ) -> [AccountDetailsV3ListViewModel.Section] {
        sections.map { section in
            AccountDetailsV3ListViewModel.Section(
                title: section.title,
                items: section.items.map { item in
                    AccountDetailsV3ListViewModel.Section.Item(
                        avatar: makeAvatar(from: item.avatars.first?.value, badge: item.badge),
                        title: item.title,
                        subtitle: item.subtitle,
                        keywords: item.keywords,
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
                        }
                    )
                }
            )
        }
    }
}
