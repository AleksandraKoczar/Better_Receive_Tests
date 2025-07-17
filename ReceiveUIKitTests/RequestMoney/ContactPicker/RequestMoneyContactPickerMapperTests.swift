import ContactsKit
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport

final class RequestMoneyContactPickerMapperTests: TWTestCase {
    func test_makeModel_withNoContacts_AndNudges() {
        let mapper = RequestMoneyContactPickerMapperImpl()

        let vm = mapper.makeModel(
            recentContacts: [],
            contacts: [],
            contactList: [],
            nudge: NudgeViewModel(title: "title", asset: .plane, ctaTitle: "title", onSelect: {}, onDismiss: nil)
        )

        let expected = makeExpectedViewModelForNoContacts()
        expectNoDifference(vm, expected)
    }

    func test_makeModel_withContacts_AndRecentContacts_AndNudges() {
        let mapper = RequestMoneyContactPickerMapperImpl()

        let contacts = [Contact.build(), Contact.build(), Contact.build()]
        let vm = mapper.makeModel(
            recentContacts: contacts,
            contacts: contacts,
            contactList: [ContactList.build()],
            nudge: NudgeViewModel(title: "title", asset: .plane, ctaTitle: "title", onSelect: {}, onDismiss: nil)
        )

        let expected = makeExpectedViewModelForContacts()
        expectNoDifference(vm, expected)
    }
}

private extension RequestMoneyContactPickerMapperTests {
    func makeExpectedViewModelForContacts() -> RequestMoneyContactPickerViewModel {
        let defaultOption = makeDefaultOption()
        let title = L10n.PaymentRequest.ContactPicker.NewRequest.title
        let nudge = NudgeViewModel(title: "title", asset: .plane, ctaTitle: "title", onSelect: {}, onDismiss: nil)

        let firstSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: nil,
            isSectionHeaderHidden: true,
            cells: [
                .search,
                .nudge(nudge: nudge),
                .spacingBetweenNudgeAndOption,
                defaultOption,
            ]
        )

        let allSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: .init(title: L10n.PaymentRequest.ContactPicker.Section.All.title), isSectionHeaderHidden: false,
            cells: [
                RequestMoneyContactPickerViewModel.Cell.contact(
                    contact: Contact.build()
                ),
                RequestMoneyContactPickerViewModel.Cell.contact(
                    contact: Contact.build()
                ),
                RequestMoneyContactPickerViewModel.Cell.contact(
                    contact: Contact.build()
                ),
            ]
        )

        let contacts = [Contact.build(), Contact.build(), Contact.build()]
        let recentContactsCells = RequestMoneyContactPickerViewModel.Cell.recentContacts(contacts: contacts)

        let recentSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: .init(title: L10n.PaymentRequest.ContactPicker.Section.Recent.title),
            isSectionHeaderHidden: false,
            cells: [recentContactsCells]
        )

        let sections: [RequestMoneyContactPickerViewModel.Section] = [
            firstSection,
            recentSection,
            allSection,
        ]

        return RequestMoneyContactPickerViewModel(title: title, sections: sections)
    }

    func makeExpectedViewModelForNoContacts() -> RequestMoneyContactPickerViewModel {
        let defaultOption = makeDefaultOption()
        let title = L10n.PaymentRequest.ContactPicker.NewRequest.title

        let nudge = NudgeViewModel(title: "title", asset: .plane, ctaTitle: "title", onSelect: {}, onDismiss: nil)

        let firstSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: nil,
            isSectionHeaderHidden: true,
            cells: [
                .search,
                .nudge(nudge: nudge),
                .spacingBetweenNudgeAndOption,
                defaultOption,
            ]
        )

        let allSection = RequestMoneyContactPickerViewModel.Section(
            viewModel: .init(title: L10n.PaymentRequest.ContactPicker.Section.All.title), isSectionHeaderHidden: false,
            cells: [
                .noContacts(viewModel: OptionViewModel(
                    title: L10n.PaymentRequest.ContactPicker.NoContacts.title,
                    avatar: AvatarViewModel.icon(
                        Icons.person.image
                    ),
                    isEnabled: false
                )),
            ]
        )

        let sections: [RequestMoneyContactPickerViewModel.Section] = [
            firstSection,
            allSection,
        ]

        return RequestMoneyContactPickerViewModel(title: title, sections: sections)
    }

    func makeDefaultOption() -> RequestMoneyContactPickerViewModel.Cell {
        .optionItem(
            viewModel: OptionViewModel(
                title: L10n.PaymentRequest.ContactPicker.Anyone.title,
                subtitle: L10n.PaymentRequest.ContactPicker.DefaultOption.subtitle,
                avatar: AvatarViewModel.icon(
                    Icons.people.image
                )
            )
        )
    }
}
