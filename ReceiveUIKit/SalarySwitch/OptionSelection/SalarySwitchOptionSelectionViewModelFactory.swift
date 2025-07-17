import Neptune
import TransferResources
import TWFoundation

enum SalarySwitchOptionSelectionViewModelFactory {
    typealias L10n = TransferResources.L10n.Account.Details.Receive.Salary.Option.Selection

    static func make(
        view: SalarySwitchOptionSelectionView
    ) -> SalarySwitchOptionSelectionViewModel {
        SalarySwitchOptionSelectionViewModel(
            titleViewModel: LargeTitleViewModel(
                title: L10n.title,
                description: L10n.description
            ),
            sections: [
                SalarySwitchOptionSelectionViewModel.Section(
                    title: L10n.Section.title,
                    options: [
                        OptionViewModel(
                            title: L10n.Option.Share.Account.Details.title,
                            subtitle: L10n.Option.Share.Account.Details.description,
                            avatar: AvatarViewModel.icon(
                                Icons.shareIos.image
                            ),
                            isEnabled: true
                        ),
                        OptionViewModel(
                            title: L10n.Option.Prove.Account.Ownership.title,
                            subtitle: L10n.Option.Prove.Account.Ownership.description,
                            avatar: AvatarViewModel.icon(
                                Icons.receipt.image
                            ),
                            isEnabled: true
                        ),
                    ]
                ),
            ]
        )
    }
}
