import ContactsKit
import Neptune
import ReceiveKit

// sourcery: AutoEquatableForTest
struct PaymentLinkAllPaymentsViewModel {
    let title: LargeTitleViewModel
    var content: PaymentLinkAllPaymentsViewModel.Content
}

extension PaymentLinkAllPaymentsViewModel {
    // sourcery: AutoEquatableForTest
    enum Content {
        case empty(EmptyViewModel)
        case sections([PaymentLinkAllPaymentsViewModel.Section])
    }

    struct Section: Equatable {
        let id: String
        let title: String
        let viewModel: SectionHeaderViewModel
        let items: [PaymentLinkAllPaymentsViewModel.Section.OptionItem]
    }

    var sections: [PaymentLinkAllPaymentsViewModel.Section] {
        if case let .sections(sections) = content {
            return sections
        }
        return []
    }

    mutating func append(_ others: [PaymentLinkAllPaymentsViewModel.Section]) {
        guard case var .sections(newSections) = content else {
            content = .sections(others)
            return
        }
        for section in others {
            guard let index = newSections.firstIndex(where: { $0.id == section.id }),
                  let theSameSection = newSections[safe: index] else {
                newSections.append(section)
                continue
            }
            let mergedSection = PaymentLinkAllPaymentsViewModel.Section(
                id: theSameSection.id,
                title: theSameSection.title,
                viewModel: theSameSection.viewModel,
                items: theSameSection.items + section.items
            )
            newSections[index] = mergedSection
        }
        content = .sections(newSections)
    }
}

extension PaymentLinkAllPaymentsViewModel.Section {
    struct OptionItem: Equatable {
        let id: String
        let option: OptionViewModel
        let actionType: PaymentLinkAllPayments.Group.Content.OptionItemAction
    }
}
