import Neptune
import SwiftUI

struct KeyInformationListItemViewModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String?
}

struct KeyInformationListItemView: View {
    enum Constants {
        static var titleStyle = LabelStyle.bodyTitle.with {
            $0.semanticFont = \.largeBodyBold
        }

        static let descriptionStyle = LabelStyle.defaultBody.with {
            $0.semanticColor = \.content.secondary
        }

        static let smallBodyTextStyle = LabelStyle.defaultBody.with {
            $0.semanticColor = \.content.tertiary
            $0.paragraphSpacing = 0
            $0.fontSize = 12.0
        }

        static let iconSpacing = SemanticSpacing.horizontal.componentDefault
        static let infoButtonSpacing = SemanticSpacing.horizontal.componentDefault
        static var textSpacing = SemanticSpacing(tokens.value4, scale: .default)

        static let subtitlePadding: CGFloat = 40
    }

    @Theme
    var theme

    var viewModel: KeyInformationListItemViewModel

    public init(viewModel: KeyInformationListItemViewModel) {
        self.viewModel = viewModel
    }

    @ViewBuilder
    var topLabel: some View {
        MarkupText(string: viewModel.title)
            .textStyle(Constants.descriptionStyle)
            .expandVertically()
    }

    @ViewBuilder
    var middleLabel: some View {
        PlainText(viewModel.subtitle)
            .textStyle(Constants.titleStyle)
            .expandVertically()
    }

    @ViewBuilder
    var bottomLabel: some View {
        if let description = viewModel.description {
            PlainText(description)
                .textStyle(Constants.smallBodyTextStyle)
                .expandVertically()
        }
    }

    private var iconSize: CGSize {
        let font: UIFont = theme.font(Constants.titleStyle)
        return .init(square: font.lineHeight)
    }

    public var body: some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: theme.spacing(Constants.infoButtonSpacing)
        ) {
            VStack(
                alignment: .leading,
                spacing: theme.spacing(Constants.textSpacing)
            ) {
                HStack(
                    alignment: .center,
                    spacing: theme.spacing.horizontal.value4
                ) {
                    topLabel
                }
                middleLabel
                bottomLabel
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .paddingPreference(theme.padding.value16)
    }
}
