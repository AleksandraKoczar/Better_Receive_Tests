import Foundation
import Neptune
import ReceiveKit
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentLinkPaymentDetailsViewModelDelegate: AnyObject {
    func optionItemTapped(
        action: PaymentLinkPaymentDetails.Section.Item.OptionItemAction
    )
}

// sourcery: AutoMockable
protocol PaymentLinkPaymentDetailsViewModelFactory {
    func make(
        from paymentLinkPaymentDetails: PaymentLinkPaymentDetails,
        delegate: PaymentLinkPaymentDetailsViewModelDelegate
    ) -> PaymentLinkPaymentDetailsViewModel
}

struct PaymentLinkPaymentDetailsViewModelFactoryImpl: PaymentLinkPaymentDetailsViewModelFactory {
    func make(
        from paymentLinkPaymentDetails: PaymentLinkPaymentDetails,
        delegate: PaymentLinkPaymentDetailsViewModelDelegate
    ) -> PaymentLinkPaymentDetailsViewModel {
        PaymentLinkPaymentDetailsViewModel(
            title: LargeTitleViewModel(
                title: paymentLinkPaymentDetails.title,
                description: MarkupLabelModel(
                    text: paymentLinkPaymentDetails.subtitle,
                    actions: []
                )
            ),
            sections: paymentLinkPaymentDetails.sections.map { section in
                makeSectionViewModel(
                    from: section,
                    delegate: delegate
                )
            }
        )
    }
}

// MARK: - Sections

private extension PaymentLinkPaymentDetailsViewModelFactoryImpl {
    func makeIcon(from urnString: String) -> UIImage {
        guard let urn = try? URN(urnString),
              let image = IconFactory.icon(urn: urn) else {
            return Icons.fastFlag.image
        }
        return image
    }

    func makeSectionItemViewModel(
        from item: PaymentLinkPaymentDetails.Section.Item,
        delegate: PaymentLinkPaymentDetailsViewModelDelegate
    ) -> PaymentLinkPaymentDetailsViewModel.Section.Item {
        switch item {
        case let .listItem(label, value):
            .listItem(
                LegacyListItemViewModel(
                    title: label,
                    subtitle: value
                )
            )
        case let .optionItem(label, value, icon, action):
            .optionItem(
                PaymentLinkPaymentDetailsViewModel.Section.OptionItem(
                    option: OptionViewModel(
                        title: label,
                        subtitle: value,
                        avatar: .icon(makeIcon(from: icon))
                    ),
                    onTap: { [weak delegate] in
                        delegate?.optionItemTapped(action: action)
                    }
                )
            )
        }
    }

    func makeSectionViewModel(
        from section: PaymentLinkPaymentDetails.Section,
        delegate: PaymentLinkPaymentDetailsViewModelDelegate
    ) -> PaymentLinkPaymentDetailsViewModel.Section {
        PaymentLinkPaymentDetailsViewModel.Section(
            title: section.title,
            items: section.items.map { item in
                makeSectionItemViewModel(
                    from: item,
                    delegate: delegate
                )
            }
        )
    }
}
