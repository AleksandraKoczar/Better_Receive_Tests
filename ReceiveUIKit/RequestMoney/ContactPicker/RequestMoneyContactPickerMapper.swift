import ContactsKit
import Neptune
import TransferResources

// sourcery: AutoMockable
protocol RequestMoneyContactPickerMapper {
    func makeModel(
        recentContacts: [Contact],
        contacts: [Contact],
        contactList: [ContactList],
        nudge: NudgeViewModel?
    ) -> RequestMoneyContactPickerViewModel
}

struct RequestMoneyContactPickerMapperImpl: RequestMoneyContactPickerMapper {
    func makeModel(
        recentContacts: [Contact],
        contacts: [Contact],
        contactList: [ContactList],
        nudge: Neptune.NudgeViewModel?
    ) -> RequestMoneyContactPickerViewModel {
        makeModelFor(
            recentContacts: recentContacts,
            contactList: contactList,
            contacts: contacts,
            nudge: nudge
        )
    }
}

// MARK: - Helpers

private extension RequestMoneyContactPickerMapperImpl {
    func makeFirstSection(
        nudge: Neptune.NudgeViewModel?
    ) -> RequestMoneyContactPickerViewModel.Section {
        let defaultOption = makeDefaultOption()
        guard let nudge else {
            return RequestMoneyContactPickerViewModel.Section(
                viewModel: nil,
                isSectionHeaderHidden: true,
                cells: [.search, defaultOption]
            )
        }
        return RequestMoneyContactPickerViewModel.Section(
            viewModel: nil,
            isSectionHeaderHidden: true,
            cells: [
                .search,
                .nudge(nudge: nudge),
                .spacingBetweenNudgeAndOption,
                defaultOption,
            ]
        )
    }

    func makeModelFor(
        recentContacts: [Contact],
        contactList: [ContactList],
        contacts: [Contact],
        nudge: Neptune.NudgeViewModel?
    ) -> RequestMoneyContactPickerViewModel {
        let title = L10n.PaymentRequest.ContactPicker.NewRequest.title

        /*
         Note: the order in this array is crucial for UI to work properly. Please, do not modify.
         */
        let sections = [
            makeFirstSection(nudge: nudge),
            makeRecentsContactsSection(recentContacts: recentContacts),
            makeAllContactsSection(contactsList: contactList, contacts: contacts),
        ].compactMap { $0 }
        return RequestMoneyContactPickerViewModel(title: title, sections: sections)
    }

    func makeAllContactsSection(
        contactsList: [ContactList],
        contacts: [Contact]
    ) -> RequestMoneyContactPickerViewModel.Section {
        guard contactsList.isNonEmpty else {
            return RequestMoneyContactPickerViewModel.Section(
                viewModel: .init(title: L10n.PaymentRequest.ContactPicker.Section.All.title),
                isSectionHeaderHidden: false,
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
        }

        let allContacts = contacts
            .map { contact in
                RequestMoneyContactPickerViewModel.Cell.contact(
                    contact: contact
                )
            }

        return RequestMoneyContactPickerViewModel.Section(
            viewModel: .init(title: L10n.PaymentRequest.ContactPicker.Section.All.title),
            isSectionHeaderHidden: false,
            cells: [].appending(contentsOf: allContacts)
        )
    }

    func makeNudgeSection(nudge: NudgeViewModel?) -> RequestMoneyContactPickerViewModel.Section? {
        guard let nudge else {
            return nil
        }

        return RequestMoneyContactPickerViewModel.Section(
            viewModel: nil,
            isSectionHeaderHidden: true,
            cells: [.nudge(nudge: nudge)]
        )
    }

    func makeRecentsContactsSection(
        recentContacts: [Contact]
    ) -> RequestMoneyContactPickerViewModel.Section? {
        guard recentContacts.isNonEmpty else {
            return nil
        }

        let recentContacts = RequestMoneyContactPickerViewModel.Cell.recentContacts(contacts: recentContacts)

        return RequestMoneyContactPickerViewModel.Section(
            viewModel: .init(title: L10n.PaymentRequest.ContactPicker.Section.Recent.title),
            isSectionHeaderHidden: false,
            cells: [recentContacts]
        )
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
