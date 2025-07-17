import ContactsKit
import Neptune

// sourcery: AutoEquatableForTest
struct RequestMoneyContactPickerViewModel {
    let titleViewModel: LargeTitleViewModel
    let sections: [RequestMoneyContactPickerViewModel.Section]

    // sourcery: AutoEquatableForTest
    enum Cell {
        case search
        case optionItem(viewModel: OptionViewModel)
        case noContacts(viewModel: OptionViewModel)
        case contact(contact: Contact)
        case recentContacts(contacts: [Contact])
        case nudge(nudge: NudgeViewModel)
        case spacingBetweenNudgeAndOption
    }
}

extension RequestMoneyContactPickerViewModel {
    // sourcery: AutoEquatableForTest
    struct Section {
        let viewModel: SectionHeaderViewModel?
        let isSectionHeaderHidden: Bool
        let cells: [RequestMoneyContactPickerViewModel.Cell]
    }
}

extension RequestMoneyContactPickerViewModel {
    init(title: String, sections: [Section]) {
        titleViewModel = LargeTitleViewModel(title: title)
        self.sections = sections
    }
}
