import Neptune
import SwiftUI

struct AccountDetailsV3SplitterScreenItemView: View {
    enum Constants {
        static let cornerRadius = tokens.value16
        static let smallBodyTextStyle = LabelStyle.defaultBody.with {
            $0.semanticColor = \.content.tertiary
            $0.paragraphSpacing = 0
            $0.fontSize = 12.0
        }

        static let imageSize = tokens.value24
        static let iconSize = tokens.value48
        static let avatarStyle = AvatarViewStyle.size48.with {
            $0.badge = .iconStyle(
                tintColor: \.base.dark,
                secondaryTintColor: \.sentiment.warning.primary
            )
        }
    }

    @Theme
    private var theme

    let model: AccountDetailsV3SplitterScreenViewModel.ItemViewModel

    public var body: some View {
        switch model.state {
        case .active:
            activeView
        case .available:
            activeView
        }
    }

    @ViewBuilder
    private var titleLabel: some View {
        PlainText(model.title)
            .textStyle(\.bodyTitle)
            .expandVertically()
    }

    @ViewBuilder
    private var subtitleLabel: some View {
        if let text = model.subtitle {
            PlainText(text)
                .textStyle(\.defaultBody)
                .expandVertically()
        }
    }

    @ViewBuilder
    private var bodyLabel: some View {
        if let text = model.body {
            PlainText(text)
                .textStyle(Constants.smallBodyTextStyle)
                .expandVertically()
        }
    }

    @ViewBuilder
    var avatarView: some View {
        Avatar(model.avatar)
            .style(Constants.avatarStyle)
    }

    var activeView: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: theme.spacing.horizontal.value16) {
                HStack(
                    alignment: .top,
                    spacing: theme.spacing.horizontal.value16
                ) {
                    VStack(alignment: .leading, spacing: theme.spacing.horizontal.value4) {
                        titleLabel
                        subtitleLabel
                    }
                    Spacer()
                    avatarView
                }
                bodyLabel
            }
            .contentShape(Rectangle())
            .onTapGesture {
                model.onTapAction?()
            }
        }
        .padding(theme.spacing.horizontal.value16)
        .background(theme.color.background.neutral.normal.color)
        .cornerRadius(Constants.cornerRadius)
    }
}
