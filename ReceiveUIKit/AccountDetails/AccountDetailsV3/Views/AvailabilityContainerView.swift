import Neptune
import SwiftUI

struct AvailabilityContainerViewModel {
    let items: [AvailabilityItemViewModel]

    struct AvailabilityItemViewModel: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String?
        let iconStyle: InstructionViewStyle
    }
}

struct AvailabilityContainerView: View {
    enum Constants {
        static let cornerRadius = tokens.value16
        static let itemSpacing = tokens.value16
    }

    @Theme
    private var theme

    var model: AvailabilityContainerViewModel.AvailabilityItemViewModel

    public var body: some View {
        HStack(
            alignment: .center,
            spacing: theme.spacing.horizontal.value8
        ) {
            HStack {
                VStack(spacing: Constants.itemSpacing) {
                    AvailabilityInstructionView(
                        title: model.title,
                        subtitle: model.subtitle,
                        style: model.iconStyle
                    )
                }
            }
            .padding(theme.padding.value16)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(theme.color.border.neutral.normal.color, lineWidth: 1)
            )
        }
        .cornerRadius(Constants.cornerRadius)
    }
}
