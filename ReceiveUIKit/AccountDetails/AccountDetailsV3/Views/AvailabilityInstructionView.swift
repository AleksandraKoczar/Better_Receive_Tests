import Neptune
import SwiftUI

struct AvailabilityInstructionView: View {
    enum Constants {
        static let titleTextStyle = LabelStyle.defaultBodyBold.with {
            $0.semanticColor = \.content.primary
            $0.paragraphSpacing = 0
        }

        static let subtitleTextStyle = LabelStyle.defaultBody.with {
            $0.semanticColor = \.content.tertiary
            $0.fontSize = 12.0
            $0.lineHeight = 18.6
            $0.paragraphSpacing = 0
        }
    }

    @Theme
    var theme

    let title: String
    let subtitle: String?
    let style: InstructionViewStyle

    init(
        title: String,
        subtitle: String?,
        style: InstructionViewStyle = .positive
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }

    @ViewBuilder
    var titleLabel: some View {
        MarkupText(model: title)
            .textStyle(Constants.titleTextStyle)
            .expandVertically()
    }

    @ViewBuilder
    var subtitleLabel: some View {
        if let subtitle {
            MarkupText(model: subtitle)
                .textStyle(Constants.subtitleTextStyle)
                .expandVertically()
                .lineSpacing(0)
        }
    }

    @ViewBuilder
    var imageLabel: some View {
        Image(uiImage: image)
            .resizable()
            .foregroundColor(tintColor)
            .frame(size: iconSize)
            .accessibility(hidden: true)
    }

    public var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.horizontal.value12) {
            imageLabel
            VStack(alignment: .leading, spacing: theme.spacing.horizontal.value4) {
                titleLabel
                subtitleLabel
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var image: UIImage {
        switch style {
        case .positive:
            Icons.checkCircleFill.image
        case .negative:
            Icons.crossCircleFill.image
        }
    }

    private var tintColor: SemanticStateColor {
        switch style {
        case .positive:
            \.sentiment.positive.primary
        case .negative:
            \.sentiment.negative.primary
        }
    }

    private var iconSize: CGSize {
        let font: UIFont = theme.font(Constants.titleTextStyle)
        return .init(square: font.lineHeight)
    }
}
