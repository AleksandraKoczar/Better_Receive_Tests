import Neptune
import SwiftUI

struct KeyInformationDetailsView: View {
    @Theme
    var theme

    var model: DetailedSummaryViewModel

    public init(
        model: DetailedSummaryViewModel
    ) {
        self.model = model
    }

    @ViewBuilder
    var titleLabel: some View {
        PlainText(model.title)
            .textStyle(\.screenTitle)
            .expandVertically()
    }

    @ViewBuilder
    var subtitleLabel: some View {
        PlainText(model.subtitle)
            .textStyle(\.largeBody)
            .expandVertically()
    }

    @ViewBuilder
    var linkActions: some View {
        ForEach(model.actions, id: \.id) { action in
            HStack {
                Spacer()
                Button(
                    action: .init(
                        title: action.title,
                        handler: {
                            action.handleAction?(action.uri)
                        }
                    )
                )
                .buttonStyle(.largeTertiary)
                Spacer()
            }
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.vertical.value32) {
                VStack(alignment: .leading, spacing: theme.spacing.vertical.value8) {
                    titleLabel
                    subtitleLabel
                }
                VStack(spacing: theme.spacing.vertical.value16) {
                    ForEach(model.groups, id: \.id) { group in
                        KeyInformationDetailsViewGroup(model: group)
                    }
                }
            }
            .padding(theme.spacing.vertical.value24)
            VStack {
                linkActions
            }
        }
    }
}
