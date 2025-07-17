import Foundation
import Neptune
import SwiftUI

struct PixCardContentView: View {
    @Theme
    private var theme

    let item: PixCardContentViewModel

    var body: some View {
        VStack(alignment: .center, spacing: theme.spacing.horizontal.value24) {
            HStack {
                Image(uiImage: item.titleIcon)
                    .frame(width: 16, height: 16)
                    .scaledToFit()
                PlainText(item.titleName)
                    .textStyle(\.defaultBodyBold)
                Spacer()
                PlainText(item.typeName)
                    .textStyle(\.defaultBody)
            }
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: theme.spacing.horizontal.value32,
                    bottom: 0,
                    trailing: theme.spacing.horizontal.value32
                )
            )
            Image(uiImage: item.image)
                .resizable()
                .scaledToFill()
                .frame(height: 230)
                .padding(.horizontal, theme.spacing.horizontal.value32)
            Capsule()
                .foregroundColor(theme.color.background.screen.normal.color)
                .frame(width: Constants.labelWidth, height: Constants.labelHeight)
                .overlay(alignment: .bottomTrailing) {
                    ZStack {
                        Text(item.value)
                            .padding(.horizontal, theme.spacing.horizontal.value12)
                            .padding(.vertical, theme.spacing.vertical.value8)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .font(theme.font.defaultBodyBold)
                            .foregroundColor(theme.color.interactive.primary.normal.color)
                            .frame(maxWidth: Constants.labelWidth, maxHeight: Constants.labelHeight)
                            .padding(.horizontal, theme.spacing.horizontal.value8)
                    }
                }
                .clipped()
                .padding(.horizontal, theme.spacing.horizontal.value16)
        }
    }

    private enum Constants {
        static let labelHeight: CGFloat = 40
        static let labelWidth: CGFloat = 220
    }
}

struct PixCardContentViewModel: Identifiable {
    let id = UUID()
    let image: UIImage
    let value: String
    let titleIcon = Icons.pix.image
    let titleName: String
    let typeName: String
}
