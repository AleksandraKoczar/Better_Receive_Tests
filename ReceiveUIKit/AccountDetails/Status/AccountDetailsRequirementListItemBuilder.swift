import ApiKit
import BalanceKit
import Foundation
import Neptune
import TransferResources
import TWFoundation
import TWUI
import UserKit
import WiseCore

public struct AccountDetailsRequirementListItemBuilder {
    private let minAmount: Money?
    private let profileType: ProfileType
    private let actionListRouter: ActionListRouter

    public init(
        minAmount: Money?,
        profileType: ProfileType,
        actionListRouter: ActionListRouter
    ) {
        self.minAmount = minAmount
        self.profileType = profileType
        self.actionListRouter = actionListRouter
    }

    public func item(
        for requirement: AccountDetailsRequirement
    ) -> SummaryViewModel? {
        let status: SummaryViewModel.Status?
        guard requirement.type != .profileCompletion else { return nil }

        switch requirement.status {
        case .done:
            status = .done
        case .pendingTW:
            status = .pending
        case .failed,
             .pendingUser,
             .other:
            status = nil
        }

        return SummaryViewModel(
            title: title(for: requirement),
            description: description(for: requirement),
            icon: icon(for: requirement),
            status: status,
            action: nil,
            info: action(for: requirement)
        )
    }

    private func icon(for requirement: AccountDetailsRequirement) -> UIImage {
        switch requirement.type {
        case .topUp,
             .fee:
            Icons.money.image
        case .verification:
            Icons.id.image
        case .profileCompletion,
             .other:
            Icons.bank.image
        }
    }

    private func title(for requirement: AccountDetailsRequirement) -> String {
        switch requirement.type {
        case let .fee(amount, _):
            feeTitle(requirement.status, amount: amount)

        case .topUp:
            topUpTitle(requirement.status)

        case .verification:
            verifyTitle(requirement.status)

        default:
            L10n.Order.Account.Details.Action.List.Option.Unhandled.todo
        }
    }

    private func feeTitle(_ status: AccountDetailsRequirementStatus, amount: Money) -> String {
        switch status {
        case .pendingUser,
             .failed:
            if profileType == .personal {
                let formattedAmount = MoneyFormatter.format(amount)
                return L10n.Order.Account.Details.Action.List.Option.Charge.Fee.Amount.todo(formattedAmount)
            } else {
                return L10n.Order.Account.Details.Action.List.Option.Fee.todo
            }
        case .pendingTW:
            return L10n.Order.Account.Details.Action.List.Option.Fee.done
        case .done:
            return L10n.Order.Account.Details.Action.List.Option.Fee.done
        case .other:
            return L10n.Order.Account.Details.Action.List.Option.Unhandled.todo
        }
    }

    private func topUpTitle(_ status: AccountDetailsRequirementStatus) -> String {
        switch status {
        case .pendingUser,
             .failed:
            if let minAmount {
                let formattedAmount = MoneyFormatter.format(minAmount)
                return L10n.Order.Account.Details.Action.List.Option.Topup.Min.Amount.todo(formattedAmount)
            } else {
                return L10n.Order.Account.Details.Action.List.Option.Topup.todo
            }
        case .pendingTW:
            return L10n.Order.Account.Details.Action.List.Option.Topup.pending
        case .done:
            return L10n.Order.Account.Details.Action.List.Option.Topup.done
        case .other:
            return L10n.Order.Account.Details.Action.List.Option.Unhandled.todo
        }
    }

    private func verifyTitle(_ status: AccountDetailsRequirementStatus) -> String {
        switch status {
        case .pendingUser,
             .failed:
            L10n.Order.Account.Details.Action.List.Option.Verify.todo
        case .pendingTW:
            L10n.Order.Account.Details.Action.List.Option.Verify.pending
        case .done:
            L10n.Order.Account.Details.Action.List.Option.Verify.done
        case .other:
            L10n.Order.Account.Details.Action.List.Option.Unhandled.todo
        }
    }

    private func description(for requirement: AccountDetailsRequirement) -> String? {
        guard requirement.requiresUserAction else { return nil }

        switch requirement.type {
        case .fee:
            return profileType == .personal
                ? L10n.Order.Account.Details.Action.List.Option.Charge.Fee.description
                : L10n.Order.Account.Details.Action.List.Option.Fee.description
        case .topUp:
            return L10n.Order.Account.Details.Action.List.Option.Topup.description
        case .verification:
            switch profileType {
            case .personal:
                return L10n.Order.Account.Details.Action.List.Option.Verify.Description.personal
            case .business:
                return L10n.Order.Account.Details.Action.List.Option.Verify.Description.business
            }
        case .other,
             .profileCompletion:
            return nil
        }
    }

    private func info(for requirement: AccountDetailsRequirement) -> String? {
        guard requirement.requiresUserAction else { return nil }

        switch requirement.type {
        case .fee:
            return nil
        case .topUp:
            if let minAmount {
                let formattedAmount = MoneyFormatter.format(minAmount)
                return L10n.Order.Account.Details.Action.List.Option.Topup.Min.Amount.Explanation.body(formattedAmount)
            } else {
                return L10n.Order.Account.Details.Action.List.Option.Topup.Explanation.body
            }
        case .verification:
            return L10n.Order.Account.Details.Action.List.Option.Verify.Explanation.body
        case .other,
             .profileCompletion:
            return nil
        }
    }

    private func action(for requirement: AccountDetailsRequirement) -> (() -> Void)? {
        guard requirement.requiresUserAction,
              let info = info(for: requirement) else { return nil }

        return { [weak actionListRouter] in
            actionListRouter?.showInfoModal(
                title: title(for: requirement),
                message: info
            )
        }
    }
}
