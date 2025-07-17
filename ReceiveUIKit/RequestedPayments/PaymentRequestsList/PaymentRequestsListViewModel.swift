import ContactsKit
import Neptune
import UIKit

// sourcery: AutoEquatableForTest
enum PaymentRequestsListViewModel {
    case emptyState(EmptyState)
    case paymentRequests(PaymentRequests)
}

extension PaymentRequestsListViewModel {
    // sourcery: AutoEquatableForTest
    struct EmptyState {
        let illustration: IllustrationView.ViewModel
        let title: String
        let summaries: [SummaryViewModel]
        let primaryButton: LargeButtonView.ViewModel
        let secondaryButton: LargeButtonView.ViewModel?
    }

    // sourcery: AutoEquatableForTest
    struct PaymentRequests {
        let navigationBarButtons: [ButtonViewModel]
        let header: PaymentRequestsListHeaderView.ViewModel
        var content: PaymentRequestsListViewModel.PaymentRequests.Content
        let isCreatePaymentRequestHidden: Bool
    }
}

extension PaymentRequestsListViewModel.PaymentRequests {
    // sourcery: AutoEquatableForTest
    struct ButtonViewModel {
        let title: String?
        let icon: UIImage
        // sourcery: skipEquality
        let action: () -> Void
    }

    // sourcery: AutoEquatableForTest
    enum Content {
        case empty(EmptyViewModel)
        case sections([Section])
    }

    // This type has to be Equatable because of difference comparison
    struct Section: Equatable {
        let id: String
        let viewModel: SectionHeaderViewModel
        let isSectionHeaderHidden: Bool
        let rows: [Section.Row]
    }

    var sections: [Section] {
        if case let .sections(sections) = content {
            return sections
        }
        return []
    }

    mutating func append(_ others: [Section]) {
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
            let mergedSection = Section(
                id: theSameSection.id,
                viewModel: theSameSection.viewModel,
                isSectionHeaderHidden: theSameSection.isSectionHeaderHidden,
                rows: theSameSection.rows + section.rows
            )
            newSections[index] = mergedSection
        }
        content = .sections(newSections)
    }
}

extension PaymentRequestsListViewModel.PaymentRequests.Section {
    // This type has to be Equatable because of difference comparison
    struct Row: Equatable {
        let id: String
        let title: String
        let subtitle: String
        let avatarStyle: AvatarViewStyle
        let avatarPublisher: AvatarPublisher
    }
}
