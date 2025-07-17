import Neptune
import TWFoundation

struct AccountDetailsListItemViewModel {
    let title: String
    let subtitle: MarkupTextModel
    let action: Action?
    let tooltip: IconButtonView.ViewModel?

    init(
        title: String,
        subtitle: MarkupTextModel,
        action: Action? = nil,
        tooltip: IconButtonView.ViewModel? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.tooltip = tooltip
    }
}
