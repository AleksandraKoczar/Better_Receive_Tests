import Neptune

struct SalarySwitchOptionSelectionViewModel {
    struct Section {
        let title: String
        let options: [OptionViewModel]
    }

    let titleViewModel: LargeTitleViewModel
    let sections: [Section]
}
