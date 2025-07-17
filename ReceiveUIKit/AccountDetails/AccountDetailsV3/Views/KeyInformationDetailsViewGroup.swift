import Foundation
import Neptune
import ReceiveKit
import SwiftUI

struct KeyInformationDetailsViewGroup: View {
    enum Constants {
        static let cornerRadius = tokens.value16
        static let titleTextStyle = LabelStyle.defaultBodyBold.with {
            $0.semanticColor = \.content.primary
            $0.paragraphSpacing = 0
        }
    }

    @Theme
    var theme

    var model: DetailedSummaryViewModel.DetailedSummaryGroupViewModel

    @ViewBuilder
    var titleLabel: some View {
        PlainText(model.title)
            .textStyle(\.bodyTitle)
            .expandVertically()
    }

    @ViewBuilder
    func markupLabel(for item: DetailedSummaryViewModel.DetailedSummaryGroupViewModel.DetailedSummaryGroupItemViewModel) -> some View {
        MarkupText(string: item.body)
            .textStyle(\.defaultBody)
            .expandVertically()
            .environment(\.openURL, OpenURLAction(handler: { url in
                item.handleURLMarkup?(url)
                return .handled
            }))
    }

    @ViewBuilder
    var icon: some View {
        if let icon = model.icon {
            Image(uiImage: icon)
                .resizable()
                .frame(size: SemanticSize.icon.size24)
                .clipShape(Circle())
                .overlay(Circle().stroke(theme.color.background.neutral.normal.color, lineWidth: 1))
                .accessibility(hidden: true)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.horizontal.value24) {
            HStack(spacing: theme.spacing.horizontal.value16) {
                titleLabel
                Spacer()
                icon
            }
            VStack(alignment: .leading, spacing: theme.spacing.horizontal.value12) {
                ForEach(model.items, id: \.id) { item in
                    if item.title.isNonEmpty {
                        PlainText(item.title)
                            .textStyle(Constants.titleTextStyle)
                            .expandVertically()
                    }
                    markupLabel(for: item)
                }
            }
        }
        .padding(theme.padding.value16)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .stroke(theme.color.border.neutral.normal.color, lineWidth: 1)
        )
    }
}
