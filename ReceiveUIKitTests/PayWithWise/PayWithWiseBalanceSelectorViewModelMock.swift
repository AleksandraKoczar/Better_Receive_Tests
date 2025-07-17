import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit
import WiseCore

extension PayWithWiseBalanceSelectorViewModel {
    static func build() -> PayWithWiseBalanceSelectorViewModel {
        let eligibleCurrencies: [CurrencyCode] = [
            .GBP,
            .SGD,
            .NZD,
            .USD,
        ]

        let ineligibleCurrencies: [CurrencyCode] = [
            .TRY,
            .CAD,
            .AED,
            .PEN,
        ]

        return PayWithWiseBalanceSelectorViewModel(
            title: LoremIpsum.veryShort,
            sections: [
                PayWithWiseBalanceSelectorViewModel.Section(
                    headerViewModel: SectionHeaderViewModel(
                        title: "Eligible balances"
                    ),
                    options: eligibleCurrencies.map {
                        OptionViewModel(
                            title: $0.value,
                            avatar: AvatarViewModel.image(
                                $0.squareIcon
                            )
                        )
                    }
                ),
                PayWithWiseBalanceSelectorViewModel.Section(
                    headerViewModel: SectionHeaderViewModel(
                        title: "Ineligible balances"
                    ),
                    options: ineligibleCurrencies.map {
                        OptionViewModel(
                            title: $0.value,
                            avatar: AvatarViewModel.image(
                                $0.squareIcon
                            )
                        )
                    }
                ),
            ],
            selectAction: { _ in }
        )
    }
}
