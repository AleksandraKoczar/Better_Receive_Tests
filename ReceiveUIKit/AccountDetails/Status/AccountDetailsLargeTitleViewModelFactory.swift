import BalanceKit
import Neptune
import TransferResources
import TWFoundation
import WiseCore

public protocol AccountDetailsLargeTitleViewModelFactory {
    func make() -> LargeTitleViewModel
}

public struct PersonalAccountDetailsLargeTitleViewModelFactory: AccountDetailsLargeTitleViewModelFactory {
    private let accountDetails: AvailableAccountDetails
    private let requirementsProvider: AccountDetailsRequirementsProvider

    public init(
        accountDetails: AvailableAccountDetails,
        requirementsProvider: AccountDetailsRequirementsProvider
    ) {
        self.accountDetails = accountDetails
        self.requirementsProvider = requirementsProvider
    }

    public func make() -> LargeTitleViewModel {
        LargeTitleViewModel(
            title: L10n.Order.Account.Details.Requirements.Personal.title(accountDetails.currency.value),
            description: makeDescription()
        )
    }

    private func makeDescription() -> String {
        let hasPendingUnsupportedRequirements = requirementsProvider.requirements.contains {
            $0.requiresUserAction && !isSupported(requirement: $0)
        }
        if hasPendingUnsupportedRequirements {
            return L10n.Order.Account.Details.Requirements.Unsupported.description
        } else {
            return L10n.Order.Account.Details.Requirements.Personal.description(accountDetails.subtitle ?? "")
        }
    }

    private func isSupported(requirement: AccountDetailsRequirement) -> Bool {
        switch requirement.type {
        case .fee,
             .topUp,
             .verification:
            true
        case .profileCompletion,
             .other:
            false
        }
    }
}

public struct BusinessAccountDetailsLargeTitleViewModelFactory: AccountDetailsLargeTitleViewModelFactory {
    private let accountDetails: [AvailableAccountDetails]
    private let requirementsProvider: AccountDetailsRequirementsProvider

    public init(
        accountDetails: [AvailableAccountDetails],
        requirementsProvider: AccountDetailsRequirementsProvider
    ) {
        self.accountDetails = accountDetails
        self.requirementsProvider = requirementsProvider
    }

    private var fee: Money? {
        let feeRequirement = requirementsProvider.requirements.first {
            if case .fee = $0.type {
                return true
            }
            return false
        }
        return feeRequirement?.type.price
    }

    public func make() -> LargeTitleViewModel {
        LargeTitleViewModel(
            title: makeTitle(),
            description: makeDescription()
        )
    }

    private func makeTitle() -> String {
        if let fee {
            L10n.Order.Account.Details.Requirements.Business.Title.withFee(MoneyFormatter.format(fee))
        } else if accountDetails.count > 1 {
            L10n.Order.Account.Details.Requirements.Business.MultipleAccounts.title
        } else if let details = accountDetails.first {
            L10n.Order.Account.Details.Requirements.Business.SingleAccount.Title.withCurrency(details.currency.value)
        } else {
            L10n.Order.Account.Details.Requirements.Business.SingleAccount.title
        }
    }

    private func makeDescription() -> String {
        let hasPendingUnsupportedRequirements = requirementsProvider.requirements.contains {
            $0.requiresUserAction && !isSupported(requirement: $0)
        }
        if hasPendingUnsupportedRequirements {
            return L10n.Order.Account.Details.Requirements.Unsupported.description
        } else {
            return L10n.Order.Account.Details.Requirements.Business.description
        }
    }

    private func isSupported(requirement: AccountDetailsRequirement) -> Bool {
        switch requirement.type {
        case .fee,
             .verification:
            true
        case .topUp,
             .profileCompletion,
             .other:
            false
        }
    }
}
