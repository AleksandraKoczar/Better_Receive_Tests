import Foundation
import Neptune

// sourcery: Buildable
struct PayWithWiseBalanceSelectorViewModel {
    let title: String
    let sections: [Section]
    let selectAction: (IndexPath) -> Void

    // sourcery: Buildable
    struct Section {
        let headerViewModel: SectionHeaderViewModel
        let options: [OptionViewModel]
    }
}
