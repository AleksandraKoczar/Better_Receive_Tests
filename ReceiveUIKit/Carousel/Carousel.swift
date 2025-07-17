import Neptune
import SwiftUI

struct CarouselCardView<Content: View>: View {
    let content: () -> Content

    init(content: @escaping () -> Content) {
        self.content = content
    }

    @Theme
    private var theme

    public var body: some View {
        theme.color.background.neutral.normal.color
            .cornerRadius(theme.radius.large)
            .frame(width: Constants.cardWidth)
            .overlay {
                content()
            }
    }
}

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

public enum CarouselCardStyle {
    case regular
    case pix
    case large
}

@available(iOS 17.0, *)
public struct CarouselView<Content: View, Item: Identifiable>: View {
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
    private var xOffset: CGPoint?
    @State
    private var initialOffset: CGPoint?
    @State
    private var position: Int? = 1
    @State
    private var contentSize: CGSize?

    public var activeIndexChanged: ((Int) -> Void)?

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: theme.spacing(Constants.pageControlSpacing).magnitude) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing(Constants.cardSpacing).magnitude) {
                        ForEach(items) { item in
                            CarouselCardView {
                                cardView(item)
                            }
                            .onTapGesture {
                                onTap(item)
                            }
                            .offset(
                                x: shouldCenterHorizontally(itemsCount: items.count)
                                    ? 0.0
                                    : -Constants.firstCardPadding
                            )
                        }
                    }
                    .padding(.horizontal, (proxy.size.width - Constants.cardWidth) / 2)
                    .scrollTargetLayout()
                    .readContentOffset(into: $xOffset)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $position)
                .frame(minHeight: minCardHeight)
                .backgroundColor()
                let pageControl = PageControlView(xOffset: xOffset, itemCount: items.count)
                pageControl
                    .onChange(of: xOffset) {
                        activeIndexChanged?(pageControl.currentIndex)
                    }
                    .opacity(items.count > 1 ? 1 : 0)
            }
            .readSize(into: $contentSize)
        }
        .frame(height: contentSize?.height)
    }

    private func shouldCenterHorizontally(itemsCount: Int) -> Bool {
        guard itemsCount > 1 else {
            return true
        }
        return position != 1
    }
}

private struct PageControlView: View {
    @Theme
    private var theme

    var xOffset: CGPoint?
    let itemCount: Int
    var currentIndex: Int {
        getIndices(xOffset?.x ?? .zero)[0] - 1
    }

    private func getIndices(_ x: CGFloat) -> [Int] {
        let width = Constants.cardWidth
        if x >= 0, x <= width {
            return [1, 2]
        } else {
            let index = Int(ceil((x - 1) / width))
            return [index, index + 1]
        }
    }

    private func getWidth(index: Int, xOffset: CGFloat) -> CGFloat {
        let width = Constants.cardWidth
        let maxWidth = Constants.capsuleMaxWidth
        let x = xOffset - (CGFloat(index) - 1) * width
        return CGFloat(Constants.pageControlWidthCoefficient * x + maxWidth)
    }

    var body: some View {
        HStack(spacing: theme.spacing(Constants.pageControlSpacing).magnitude) {
            ForEach(1..<itemCount + 1, id: \.self) { index in
                let indices = getIndices(xOffset?.x ?? 0.0)
                let width1 = getWidth(index: indices.first ?? 1, xOffset: xOffset?.x ?? 0.0)
                let width2 = (Constants.capsuleMaxWidth + Constants.capsuleMinWidth) - width1

                if index == indices.first {
                    Capsule()
                        .frame(width: width1, height: Constants.capsuleHeight)
                        .foregroundColor(theme.color.interactive.primary.normal.color)
                } else if index == indices.last {
                    Capsule()
                        .frame(width: width2, height: Constants.capsuleHeight)
                        .foregroundColor(theme.color.interactive.secondary.normal.color)
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
