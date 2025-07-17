import CombineSchedulers
import ContactsKit
import ContactsKitTestingSupport
import Neptune
import ReceiveKit
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import WiseCore

final class RequestMoneyContactPickerViewControllerTests: TWSnapshotTestCase {
    func test_layout_withAllComponents() {
        let presenter = RequestMoneyContactPickerPresenterMock()
        let viewController = RequestMoneyContactPickerViewController(
            presenter: presenter,
            scheduler: .immediate
        )

        let contact = Contact.build(
            title: "John Doe",
            subtitle: "GBP account ending 2048",
            avatarPublisher: AvatarPublisher.icon(
                avatarPublisher: .just(
                    AvatarModel.icon(
                        CurrencyCode.GBP.icon
                    )
                ),
                gradientPublisher: .canned, path: .canned
            )
        )

        let arrayContacts = Array(repeating: contact, count: 5)

        let defaultOption = makeDefaultOption()
        let nudge = NudgeViewModel(
            title: LoremIpsum.short,
            asset: .plane,
            ctaTitle: LoremIpsum.short,
            onSelect: {},
            onDismiss: nil
        )
        let firstSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: nil,
            isSectionHeaderHidden: true,
            cells: [.search, .nudge(nudge: nudge), defaultOption]
        )

        let recentContacts = RequestMoneyContactPickerViewModel.Cell.recentContacts(contacts: arrayContacts)
        let recentSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: .init(title: "Recent"),
            isSectionHeaderHidden: false,
            cells: [recentContacts]
        )

        let allContacts = [RequestMoneyContactPickerViewModel.Cell.contact(
            contact: contact
        ), RequestMoneyContactPickerViewModel.Cell.contact(
            contact: contact
        ), RequestMoneyContactPickerViewModel.Cell.contact(
            contact: contact
        )]

        let allSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: .init(title: "All"),
            isSectionHeaderHidden: false,
            cells: [].appending(contentsOf: allContacts)
        )

        let sections = [firstSection, recentSection, allSection]

        let viewModel = RequestMoneyContactPickerViewModel(title: LoremIpsum.veryShort, sections: sections)

        viewController.configure(viewModel: viewModel)

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_layout_withoutRecentContacts() {
        let presenter = RequestMoneyContactPickerPresenterMock()
        let viewController = RequestMoneyContactPickerViewController(
            presenter: presenter,
            scheduler: .immediate
        )

        let contact = Contact.build(
            title: "John Doe",
            subtitle: "GBP account ending 2048",
            avatarPublisher: AvatarPublisher.icon(
                avatarPublisher: .just(
                    AvatarModel.icon(
                        CurrencyCode.GBP.icon
                    )
                ),
                gradientPublisher: .canned, path: .canned
            )
        )

        let defaultOption = makeDefaultOption()
        let nudge = NudgeViewModel(
            title: LoremIpsum.short,
            asset: .plane,
            ctaTitle: LoremIpsum.short,
            onSelect: {},
            onDismiss: nil
        )
        let firstSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: nil,
            isSectionHeaderHidden: true,
            cells: [.search, .nudge(nudge: nudge), defaultOption]
        )

        let allContacts = [RequestMoneyContactPickerViewModel.Cell.contact(
            contact: contact
        ), RequestMoneyContactPickerViewModel.Cell.contact(
            contact: contact
        ), RequestMoneyContactPickerViewModel.Cell.contact(
            contact: contact
        )]

        let allSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: .init(title: "All"),
            isSectionHeaderHidden: false,
            cells: [].appending(contentsOf: allContacts)
        )

        let sections = [firstSection, allSection]

        let viewModel = RequestMoneyContactPickerViewModel(title: LoremIpsum.veryShort, sections: sections)

        viewController.configure(viewModel: viewModel)

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_layout_noContactsWithNudges() {
        let presenter = RequestMoneyContactPickerPresenterMock()
        let viewController = RequestMoneyContactPickerViewController(
            presenter: presenter,
            scheduler: .immediate
        )

        let defaultOption = makeDefaultOption()
        let nudge = NudgeViewModel(
            title: LoremIpsum.short,
            asset: .plane,
            ctaTitle: LoremIpsum.short,
            onSelect: {},
            onDismiss: nil
        )
        let firstSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: nil,
            isSectionHeaderHidden: true,
            cells: [.search, .nudge(nudge: nudge), defaultOption]
        )

        let allContacts = [RequestMoneyContactPickerViewModel.Cell.noContacts(
            viewModel: OptionViewModel(
                title: LoremIpsum.short,
                avatar: AvatarViewModel.icon(
                    Icons.person.image
                ),
                isEnabled: false
            )
        )]

        let allSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: .init(title: "All"),
            isSectionHeaderHidden: false,
            cells: [].appending(contentsOf: allContacts)
        )

        let sections = [firstSection, allSection]

        let viewModel = RequestMoneyContactPickerViewModel(title: LoremIpsum.veryShort, sections: sections)

        viewController.configure(viewModel: viewModel)

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func makeDefaultOption() -> RequestMoneyContactPickerViewModel.Cell {
        .optionItem(
            viewModel: OptionViewModel(
                title: "Anyone",
                subtitle: "Share a  link",
                avatar: AvatarViewModel.icon(
                    Icons.people.image
                )
            )
        )
    }
}
