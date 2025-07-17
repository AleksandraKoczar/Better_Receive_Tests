import BalanceKit
import Neptune
import SwiftUI

struct AccountDetailsHeaderView: View {
    enum Constants {
        static let titleTextStyle = LabelStyle.subsectionTitle.with {
            $0.semanticColor = \.content.primary
            $0.paragraphSpacing = 0
        }

        static let subtitleTextStyle = LabelStyle.defaultBody.with {
            $0.semanticColor = \.content.tertiary
            $0.paragraphSpacing = 0
        }
    }

    @Theme
    var theme

    @Environment(\.preferredMaxLayoutWidth)
    var preferredMaxLayoutWidth

    let viewModel: DetailsHeaderViewModel

    init(
        viewModel: DetailsHeaderViewModel
    ) {
        self.viewModel = viewModel
    }

    @ViewBuilder
    var titleLabel: some View {
        MarkupText(model: viewModel.title)
            .textStyle(Constants.titleTextStyle)
            .expandVertically()
    }

    @ViewBuilder
    var subtitleLabel: some View {
        let markup = try? Markup(viewModel.subtitle.value)
        MarkupText(markup: markup)
            .textStyle(Constants.subtitleTextStyle)
            .expandVertically()
            .markupLinkAction(in: markup) { _ in
                viewModel.handleSubtitleMarkup?(viewModel.subtitle)
            }
    }

    @ViewBuilder
    var actionButtons: some View {
        HStack(alignment: .center) {
            ForEach(viewModel.actions) { action in
                Button(
                    title: action.title,
                    icon: nil,
                    handler: {
                        action.handleAction?()
                    }
                )
                .buttonStyle(.smallPrimary)
            }
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.horizontal.componentDefault) {
            VStack(alignment: .leading, spacing: theme.spacing.horizontal.value2) {
                titleLabel
                subtitleLabel
            }
            Spacer()
            actionButtons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
