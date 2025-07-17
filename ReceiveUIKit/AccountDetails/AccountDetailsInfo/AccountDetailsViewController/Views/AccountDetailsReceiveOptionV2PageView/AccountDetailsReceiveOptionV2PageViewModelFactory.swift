import BalanceKit
import Foundation
import Neptune
import TransferResources
import TWFoundation
import UIKit
import WiseCore

enum AccountDetailsReceiveOptionV2PageViewModelFactory {
    static func make(
        currencyCode: CurrencyCode,
        receiveOption: AccountDetailsReceiveOption,
        modalDelegate: AccountDetailsInfoModalDelegate,
        accountDetailsType: AccountDetailsType,
        nudgeSelectAction: @escaping (() -> Void),
        alertAction: @escaping ((String) -> Void)
    ) -> AccountDetailsReceiveOptionV2PageViewModel {
        let alert = makeAlert(
            with: receiveOption.alert,
            alertAction: alertAction
        )
        let summaries =
            if receiveOption.details.isEmpty {
                makeNoDetailSummary(
                    title: receiveOption.description?.body
                )
            } else {
                makeSummaries(
                    with: receiveOption.summaries,
                    modalDelegate: modalDelegate
                )
            }

        let infoViewModel = makeInfoViewModel(
            receiveOptionType: receiveOption.type,
            detailItems: receiveOption.details,
            currencyCode: currencyCode,
            shareText: receiveOption.shareText,
            description: receiveOption.description,
            modalDelegate: modalDelegate
        )

        let nudge = makeNudge(
            accountDetailsType: accountDetailsType,
            currencyCode: currencyCode,
            selectAction: nudgeSelectAction
        )

        return AccountDetailsReceiveOptionV2PageViewModel(
            title: receiveOption.title,
            type: AccountDetailsReceiveOptionReceiveType(
                type: receiveOption.type
            ),
            alert: alert,
            summaries: summaries,
            infoViewModel: infoViewModel,
            nudge: nudge
        )
    }
}

// MARK: - Helpers

private extension AccountDetailsReceiveOptionV2PageViewModelFactory {
    static func makeAlert(
        with alert: AccountDetailsAlert?,
        alertAction: @escaping Neptune.Action.ParameterHandler<String>
    ) -> AccountDetailsReceiveOptionV2PageViewModel.Alert? {
        guard let alert else {
            return nil
        }
        return .init(
            style: alert.asInlineAlertStyle(),
            viewModel: Neptune.InlineAlertViewModel(
                message: alert.content,
                action: alert.action.map { action in
                    Action(
                        title: action.text,
                        handler: {
                            alertAction(action.uri)
                        }
                    )
                }
            )
        )
    }

    static func makeSummaries(
        with summaries: [AccountDetailsSummaryItem],
        modalDelegate: AccountDetailsInfoModalDelegate
    ) -> [SummaryViewModel] {
        summaries.map { summary in
            let info: (() -> Void)? =
                if let description = summary.description {
                    { [weak modalDelegate] in
                        modalDelegate?.showInformationModal(
                            title: description.title,
                            description: description.body,
                            analyticsType: summary.type.caseNameId
                        )
                    }
                } else {
                    nil
                }

            return SummaryViewModel(
                title: summary.title,
                icon: summary.type.image,
                info: info
            )
        }
    }

    static func makeNoDetailSummary(title: String?) -> [SummaryViewModel] {
        guard let title else { return [] }
        return [SummaryViewModel(
            title: title,
            icon: Icons.globe.image,
            info: nil
        )]
    }

    static func makeInfoViewModel(
        receiveOptionType: AccountDetailsReceiveOption.ReceiveType,
        detailItems: [AccountDetailsDetailItem],
        currencyCode: CurrencyCode,
        shareText: String?,
        description: AccountDetailsDescription?,
        modalDelegate: AccountDetailsInfoModalDelegate
    ) -> AccountDetailsReceiveOptionInfoV2ViewModel? {
        guard detailItems.isNonEmpty else {
            return nil
        }

        let rows: [AccountDetailsInfoRowV2ViewModel] = detailItems.map { detailItem in
            if detailItem.description != nil {
                let actionButton: Action
                let tooltip: IconButtonView.ViewModel?

                if detailItem.shouldObfuscate {
                    actionButton = Action(
                        title: L10n.AccountDetails.Info.Details.Obfuscated.reveal,
                        discoverabilityTitle: L10n.AccountDetails.Info.Details.Obfuscated.Reveal.accessibilityHint,
                        handler: { [weak modalDelegate] in
                            modalDelegate?.showCopyableModal(
                                accountDetailItem: detailItem
                            )
                        }
                    )
                    tooltip = nil
                } else {
                    actionButton = copyAction(
                        detailItem: detailItem,
                        modalDelegate: modalDelegate
                    )
                    tooltip = IconButtonView.ViewModel(
                        icon: Icons.questionMarkCircle.image,
                        discoverabilityTitle: L10n.AccountDetails.Info.Details.MoreInformation.accessibilityHint,
                        handler: { [weak modalDelegate] in
                            modalDelegate?.showCopyableModal(
                                accountDetailItem: detailItem
                            )
                        }
                    )
                }

                return AccountDetailsInfoRowV2ViewModel(
                    title: detailItem.title,
                    information: detailItem.body,
                    isObfuscated: detailItem.shouldObfuscate,
                    action: actionButton,
                    tooltip: tooltip
                )
            } else {
                return AccountDetailsInfoRowV2ViewModel(
                    title: detailItem.title,
                    information: detailItem.body,
                    isObfuscated: detailItem.shouldObfuscate,
                    action: copyAction(
                        detailItem: detailItem,
                        modalDelegate: modalDelegate
                    ),
                    tooltip: nil
                )
            }
        }

        let shareButton: AccountDetailsInfoHeaderV2ViewModel.ShareButton? = {
            guard let shareText else {
                return nil
            }
            return .init(
                title: L10n.AccountDetails.Info.Header.share,
                action: { [weak modalDelegate] view in
                    modalDelegate?.shareAccountDetails(
                        shareText: shareText,
                        sender: view
                    )
                }
            )
        }()

        let avatarImageCreator: (SemanticContext) -> UIImage = { semanticContext in
            switch receiveOptionType {
            case .local:
                currencyCode.icon
            case .international:
                Icons.globe.image.withTintColor(
                    semanticContext.theme.color.content.primary.normal,
                    renderingMode: .alwaysOriginal
                )
            }
        }

        return AccountDetailsReceiveOptionInfoV2ViewModel(
            header: AccountDetailsInfoHeaderV2ViewModel(
                avatarAccessibilityValue: currencyCode.localizedCurrencyName,
                title: description?.body
                    ?? L10n.AccountDetails.Info.Details.Header.currency(currencyCode.value),
                shareButton: shareButton,
                avatarImageCreator: avatarImageCreator
            ),
            rows: rows
        )
    }

    static func copyAction(
        detailItem: AccountDetailsDetailItem,
        modalDelegate: AccountDetailsInfoModalDelegate
    ) -> Action {
        Action(
            image: Icons.documents.image,
            discoverabilityTitle: L10n.AccountDetails.Info.Details.MoreInformation.accessibilityHint,
            handler: { [weak modalDelegate] in
                modalDelegate?.copyAccountDetails(
                    detailItem.body,
                    for: detailItem.title,
                    analyticsType: detailItem.analyticsType
                )
            }
        )
    }

    static func makeNudge(
        accountDetailsType: AccountDetailsType,
        currencyCode: CurrencyCode,
        selectAction: @escaping (() -> Void)
    ) -> NudgeViewModel {
        let nudgeViewModel: NudgeViewModel
        switch accountDetailsType {
        case .standard:
            let copies: (title: String, actionTitle: String) =
                if currencyCode == CurrencyCode.EUR {
                    (
                        title: L10n.AccountDetails.Info.AccountDetails.Nudge.Nbb.title,
                        actionTitle: L10n.AccountDetails.Info.Nudge.Action.Nbb.title
                    )
                } else {
                    (
                        title: L10n.AccountDetails.Info.AccountDetails.Nudge.title(currencyCode.value),
                        actionTitle: L10n.AccountDetails.Info.Nudge.Action.title
                    )
                }

            nudgeViewModel = NudgeViewModel(
                title: copies.title,
                asset: NudgeViewModel.Asset.globe,
                ctaTitle: copies.actionTitle,
                onSelect: selectAction
            )
        case .directDebit:
            nudgeViewModel = NudgeViewModel(
                title: L10n.AccountDetails.Info.DirectDebits.Nudge.title,
                asset: NudgeViewModel.Asset.calendar,
                ctaTitle: L10n.AccountDetails.Info.Nudge.Action.title,
                onSelect: selectAction
            )
        }
        return nudgeViewModel
    }
}
