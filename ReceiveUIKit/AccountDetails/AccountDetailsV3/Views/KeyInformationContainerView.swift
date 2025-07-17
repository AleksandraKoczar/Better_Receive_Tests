import Neptune
import SwiftUI

struct KeyInformationContainerView: View {
    enum Constants {
        static let cornerRadius = tokens.value16
        static let itemSpacing = 20.0
    }

    @Theme
    private var theme

    @ObservedObject
    var model: KeyInformationItem

    init(
        model: KeyInformationItem
    ) {
        self.model = model
    }

    var arrowIcon: some View {
        Image(uiImage: Icons.chevronRight.image)
            .resizable()
            .foregroundColor(theme.color.interactive.primary.normal.color)
            .frame(size: SemanticSize.icon.size16)
            .accessibility(hidden: true)
    }

    public var body: some View {
        HStack(
            alignment: .center,
            spacing: theme.spacing.horizontal.value8
        ) {
            HStack {
                VStack(spacing: theme.spacing.horizontal.value24) {
                    ForEach(model.items) { item in
                        KeyInformationListItemView(viewModel: KeyInformationListItemViewModel(
                            title: item.title,
                            subtitle: item.subtitle,
                            description: item.description
                        ))
                    }
                }
                if model.isDetailSupported {
                    arrowIcon
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
