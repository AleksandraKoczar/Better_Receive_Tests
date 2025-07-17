import Neptune
import ReceiveKit
import UIKit
import WiseCore

enum AccountDetailsV3ViewModelMapper {
    static func mapAccountDetailsContainer(
        details: [AccountDetailsV3Method.AccountDetailsItem],
        footer: AccountDetailsV3Method.AccountDetailsFooter?,
        delegate: AccountDetailsV3ViewActionDelegate?
    ) -> AccountDetailsV3MethodViewModel {
        let items = details.map { detail in

            let action: AccountDetailsV3MethodViewModel.ItemViewModel.DetailsActionViewModel? =
                switch detail.action {
                case let .copy(action):
                    AccountDetailsV3MethodViewModel.ItemViewModel.DetailsActionViewModel(
                        icon: makeIcon(from: action.icon) ?? Icons.documents.image,
                        accessibilityLabel: action.accessibilityLabel,
                        type: .copy,
                        copyText: action.copyText,
                        feedbackText: action.feedbackText,
                        handleAction: { [weak delegate] _ in
                            delegate?.handleCopyAction(copyText: action.copyText, feedbackText: action.feedbackText)
                            delegate?.trackEvent(event: .detailCopied(detailType: mapItemType(type: action.typeRawValue)))
                        }
                    )
                case .none:
                    nil
                }

            return AccountDetailsV3MethodViewModel.ItemViewModel(
                title: detail.title,
                body: detail.body,
                information: detail.information,
                action: action,
                handleMarkup: { [weak delegate] markup in
                    delegate?.handleExternalAction(action: markup.action)
                    let value: String? =
                        switch markup.action {
                        case .modal:
                            nil
                        case let .url(url):
                            url.absoluteString
                        case let .urn(uri):
                            uri.description
                        case .none:
                            nil
                        }
                    if let type = detail.type {
                        delegate?.trackEvent(event: .markupLinkClicked(detailType: mapItemType(type: type), value: value))
                    }
                }
            )
        }

        let footerViewModel: AccountDetailsV3MethodViewModel.FooterViewModel? =
            switch footer {
            case .none,
                 .unknown:
                nil
            case let .button(button):
                AccountDetailsV3MethodViewModel.FooterViewModel.button(
                    AccountDetailsV3MethodViewModel.FooterViewModel.FooterButtonViewModel(
                        title: button.title,
                        style: Self.mapToButtonStyle(buttonPriority: button.priority),
                        action: { [weak delegate] in
                            delegate?.handleExternalAction(action: button.action)
                        }
                    )
                )
            }

        return AccountDetailsV3MethodViewModel(
            items: items,
            footer: footerViewModel
        )
    }

    static func mapAvailability(
        model: AccountDetailsV3Availability
    ) -> AvailabilityViewModel {
        let items = model.items.map { item in
            AvailabilityContainerViewModel.AvailabilityItemViewModel(
                title: item.title,
                subtitle: item.body,
                iconStyle: mapInstructionType(type: item.type)
            )
        }
        return AvailabilityViewModel(title: model.title, containerViewModel: .init(items: items))
    }

    private static func mapInstructionType(type: AccountDetailsV3Availability.AvailabilityItem.`Type`) -> InstructionViewStyle {
        switch type {
        case .negative:
            .negative
        case .positive:
            .positive
        }
    }

    private static func mapKeyInformationType(type: AccountDetailsV3Information.InformationItem.`Type`) -> KeyInformationType? {
        switch type {
        case .fees:
            .fees
        case .limits:
            .limits
        case .speed:
            .speed
        case .other:
            nil
        }
    }

    private static func mapItemType(type: String) -> AccountDetailsV3AnalyticsEvent.DetailType {
        AccountDetailsV3AnalyticsEvent.DetailType(rawValue: type) ?? .other
    }

    static func mapKeyInformation(
        model: AccountDetailsV3Information,
        delegate: AccountDetailsV3ViewActionDelegate?
    ) -> KeyInformationViewModel {
        let chips: [KeyInformationViewModel.ChipViewModel] = model.items.compactMap { item in
            guard let type = mapKeyInformationType(type: item.type) else {
                return nil
            }
            return KeyInformationViewModel.ChipViewModel(title: item.title, type: type)
        }

        let detailedSummaries: [KeyInformationType: AccountDetailsV3Information.InformationItem.DetailedSummary] =
            model.items.reduce(into: [:]) { dict, item in
                if let type = mapKeyInformationType(type: item.type) {
                    dict[type] = item.detailedSummaries
                }
            }

        let informationItems: [KeyInformationItem] = model.items.compactMap { item in

            let summaries = item.summaries.compactMap { summary in
                KeyInformationListItemViewModel(
                    title: summary.title,
                    subtitle: summary.body,
                    description: summary.information
                )
            }

            guard let type = mapKeyInformationType(type: item.type) else {
                return nil
            }
            return KeyInformationItem(
                type: type,
                subtitle: item.description,
                isDetailSupported: detailedSummaries[type].isNonNil,
                items: summaries
            )
        }

        // guard chips.isNonEmpty, informationItems.isNonEmpty else { return }

        return KeyInformationViewModel(
            title: model.title,
            chips: chips,
            items: informationItems,
            selectedChip: chips.first!,
            selectedItem: informationItems.first!,
            onContainerTap: { [weak delegate] chipType in
                guard let details = detailedSummaries[chipType] else {
                    return
                }
                delegate?.containerTapped(content: details)
                delegate?.trackEvent(event: .containerSelected(chipType))
            },
            trackChipSelected: { [weak delegate] chipType in
                delegate?.trackEvent(event: .chipSelected(chipType))
            }
        )
    }

    static func makeIcon(from urnString: String) -> UIImage? {
        guard let urn = try? URN(urnString) else {
            return nil
        }
        return IconFactory.icon(urn: urn) ?? FlagFactory.flag(urn: urn)
    }

    static func mapKeyInformationDetails(
        content: AccountDetailsV3Information.InformationItem.DetailedSummary,
        router: AccountDetailsInfoRouter
    ) -> DetailedSummaryViewModel {
        let actions: [DetailedSummaryViewModel.DetailedSummaryActionViewModel] = content.actions.compactMap { action in
            guard let uri = URI(string: action.value) else { return nil }
            return DetailedSummaryViewModel.DetailedSummaryActionViewModel(
                title: action.title,
                uri: uri,
                handleAction: {
                    router.handleURI($0)
                }
            )
        }

        let groups = content.groups.map { group in
            let items = group.items.map { item in
                DetailedSummaryViewModel.DetailedSummaryGroupViewModel.DetailedSummaryGroupItemViewModel(
                    title: item.title,
                    body: item.body,
                    handleURLMarkup: { url in
                        router.showArticle(url: url)
                    }
                )
            }

            return DetailedSummaryViewModel.DetailedSummaryGroupViewModel(
                title: group.title,
                icon: makeIcon(from: group.icon),
                items: items
            )
        }

        return DetailedSummaryViewModel(
            title: content.title,
            subtitle: content.subtitle,
            groups: groups,
            actions: actions
        )
    }

    static func mapHeader(
        model: AccountDetailsV3Method.DetailsHeader,
        delegate: AccountDetailsV3ViewActionDelegate?
    ) -> DetailsHeaderViewModel {
        let actions = model.actions.map { action in
            switch action {
            case let .share(model as AccountDetailsHeaderBaseAction),
                 let .urn(model as AccountDetailsHeaderBaseAction):
                DetailsHeaderViewModel.DetailsHeaderActionViewModel(
                    title: model.title,
                    handleAction: { [weak delegate] in
                        delegate?.handleHeaderAction(action)
                    }
                )
            }
        }

        return DetailsHeaderViewModel(
            title: model.title,
            subtitle: model.body,
            handleSubtitleMarkup: { [weak delegate] markup in
                delegate?.handleExternalAction(action: markup.action)
                let value: String? =
                    switch markup.action {
                    case .modal:
                        nil
                    case let .url(url):
                        url.absoluteString
                    case let .urn(uri):
                        uri.description
                    case .none:
                        nil
                    }

                delegate?.trackEvent(event: .currencyHeaderMarkupClicked(value: value))
            },
            actions: actions
        )
    }

    static func mapToButtonStyle(
        buttonPriority: ButtonPriority
    ) -> any LargeButtonAppearance {
        switch buttonPriority {
        case .primary:
            LargePrimaryButtonAppearance.largePrimary
        case .secondary:
            LargeSecondaryButtonAppearance.largeSecondary
        case .secondaryNeutral:
            LargeSecondaryNeutralButtonAppearance.largeSecondaryNeutral
        case .tertiary:
            LargeTertiaryButtonAppearance.largeTertiary
        }
    }
}
