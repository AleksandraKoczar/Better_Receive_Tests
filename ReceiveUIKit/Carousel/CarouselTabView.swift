import Neptune
import SwiftUI

private enum Constants {
    static let cardWidth: CGFloat = 320
    static let cardSpacing = SemanticSpacing.vertical.value12
    static let firstCardPadding: CGFloat = 16
    static let capsuleHeight: CGFloat = 12
    static let capsuleMaxWidth: CGFloat = 24
    static let capsuleMinWidth: CGFloat = 12
    static let pageControlPadding = SemanticPadding.horizontal.value8
    static let pageControlSpacing = SemanticSpacing.vertical.value8
    static let pageControlWidthCoefficient: CGFloat = -(2.0 / 55.0)
}

public struct CarouselTabView<Content: View, Item: Identifiable>: View {
    @ViewBuilder
    var cardView: (Item) -> Content
    @Theme
    private var theme
    var items: [Item]
    let onTap: (Item) -> Void
    let cardStyle: CarouselCardStyle

    // style dependent: .large (400px), .small (320px)
    var minCardHeight: CGFloat {
        switch cardStyle {
        case .regular:
            320.0
        case .pix:
            382.0
        case .large:
            400.0
        }
    }

    init(
        items: [Item],
        @ViewBuilder cardView: @escaping (Item) -> Content,
        onTap: @escaping (Item) -> Void,
        cardStyle: CarouselCardStyle = .regular
    ) {
        self.items = items
        self.cardView = cardView
        self.onTap = onTap
        self.cardStyle = cardStyle
    }

    @State
    private var isScrollDisabled = false
    @State
    private var selectedIndex = 1
    @State
    private var contentSize: CGSize?

    public var body: some View {
        GeometryReader { _ in
            VStack(spacing: theme.spacing(Constants.pageControlSpacing).magnitude) {
                TabView(selection: $selectedIndex) {
                    ForEach(items) { item in
                        CarouselCardView {
                            cardView(item)
                        }
                        .onTapGesture {
                            onTap(item)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(minHeight: minCardHeight)
                .backgroundColor()
                PageControlView(selectedIndex: selectedIndex, itemCount: items.count)
            }
            .padding(.bottom, theme.spacing.vertical.value16)
            .readSize(into: $contentSize)
        }
        .frame(height: contentSize?.height)
    }
}

private struct PageControlView: View {
    @Theme
    private var theme

    var selectedIndex = 1
    let itemCount: Int

    var body: some View {
        HStack(spacing: theme.spacing(Constants.pageControlSpacing).magnitude) {
            ForEach(1..<itemCount + 1, id: \.self) { index in

                if index == selectedIndex {
                    Capsule()
                        .frame(width: Constants.capsuleMaxWidth, height: Constants.capsuleHeight)
                        .foregroundColor(theme.color.interactive.primary.normal.color)
                } else {
                    Capsule()
                        .frame(width: Constants.capsuleMinWidth, height: Constants.capsuleHeight)
                        .foregroundColor(theme.color.interactive.secondary.normal.color)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.padding(Constants.pageControlPadding).magnitude)
        .backgroundColor()
    }
}
