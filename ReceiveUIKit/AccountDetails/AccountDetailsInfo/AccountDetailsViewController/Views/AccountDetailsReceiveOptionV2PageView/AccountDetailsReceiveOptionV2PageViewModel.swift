import Foundation
import Neptune

// sourcery: AutoEquatableForTest
struct AccountDetailsReceiveOptionV2PageViewModel {
    let title: String?
    let type: AccountDetailsReceiveOptionReceiveType
    let alert: Alert?
    let summaries: [SummaryViewModel]
    let infoViewModel: AccountDetailsReceiveOptionInfoV2ViewModel?
    let nudge: NudgeViewModel

    // sourcery: AutoEquatableForTest
    struct Alert {
        let style: InlineAlertStyle
        let viewModel: InlineAlertViewModel
    }
}
