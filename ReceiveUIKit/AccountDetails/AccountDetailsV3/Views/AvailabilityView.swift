import Neptune
import SwiftUI

struct AvailabilityViewModel {
    let title: String
    let containerViewModel: AvailabilityContainerViewModel
}

struct AvailabilityView: View {
    @Theme
    var theme

    let model: AvailabilityViewModel

    @ViewBuilder
    var titleLabel: some View {
        PlainText(model.title)
            .textStyle(\.bodyTitle)
            .expandVertically()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.horizontal.value16) {
            titleLabel
            ForEach(model.containerViewModel.items) { item in
                AvailabilityContainerView(model: item)
            }
        }
    }
}
