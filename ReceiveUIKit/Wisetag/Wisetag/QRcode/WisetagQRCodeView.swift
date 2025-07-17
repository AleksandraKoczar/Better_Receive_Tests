import Neptune
import SwiftUI
import TransferResources

struct WisetagQRCodeView: View {
    private enum Constants {
        static let imageSize: CGFloat = 270
        static let labelHeight: CGFloat = 40
        static let labelWidth: CGFloat = 150
        static let cornerRadius: CGFloat = 24
    }

    @ObservedObject
    var viewModel: WisetagQRCodeViewModel
    @Theme
    private var theme

    @State
    private var isAnimationInProgress = false
    @State
    private var counter = 0
    @State
    private var isHighlighted = false
    @State
    private var animateColorChange = false
    @State
    private var yOffset: CGFloat = 0
    @State
    private var scaleFactor: CGFloat = 1.0

    var animation: SwiftUI.Animation {
        .linear(duration: 0.1)
    }

    init(viewModel: WisetagQRCodeViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        switch viewModel.state {
        case let .qrCodeEnabled(qrCode, enabledText, enabledTextOnTap, didTap):
            VStack {
                VStack(spacing: .zero) {
                    Image(uiImage: qrCode ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.imageSize, height: Constants.imageSize)
                    Capsule()
                        .foregroundColor(animateColorChange ? theme.color.interactive.accent.normal.color : theme.color.background.screen.normal.color)
                        .animation(.easeInOut(duration: 0.25), value: animateColorChange)
                        .frame(width: Constants.labelWidth, height: Constants.labelHeight)
                        .overlay(alignment: .bottomTrailing) {
                            ZStack {
                                Text(enabledTextOnTap)
                                    .lineLimit(1)
                                    .font(theme.font.defaultBodyBold)
                                    .foregroundColor(theme.color.interactive.control.normal.color)
                                    .offset(x: 0, y: Constants.labelHeight + yOffset)
                                    .animation(animation, value: yOffset)
                                    .frame(maxWidth: Constants.labelWidth, maxHeight: Constants.labelHeight)
                                    .padding(.horizontal, theme.spacing.horizontal.value8)
                            }
                            ZStack {
                                Text(enabledText)
                                    .lineLimit(1)
                                    .font(theme.font.defaultBodyBold)
                                    .foregroundColor(theme.color.interactive.primary.normal.color)
                                    .offset(x: 0, y: yOffset)
                                    .animation(animation, value: yOffset)
                                    .frame(maxWidth: Constants.labelWidth, maxHeight: Constants.labelHeight)
                                    .padding(.horizontal, theme.spacing.horizontal.value8)
                            }
                        }
                        .clipped()
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: theme.spacing.vertical.value16, trailing: 0))
                }
                .background(theme.color.background.neutral.normal.color)
                .cornerRadius(Constants.cornerRadius)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .scaleEffect(scaleFactor)
            .onLongPressGesture(minimumDuration: 100, maximumDistance: .infinity, pressing: { pressing in
                if pressing {
                    if !isAnimationInProgress {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(Animation.linear(duration: 0.1)) {
                            animateColorChange.toggle()
                            isAnimationInProgress = true
                            yOffset -= Constants.labelHeight
                            counter = 1
                        }
                        withAnimation(Animation.linear(duration: 0.15)) {
                            isAnimationInProgress = true
                            scaleFactor = 0.96
                        }
                    }
                } else {
                    if counter == 1 {
                        counter = 0
                        withAnimation(Animation.linear(duration: 0.1)) {
                            scaleFactor = 1.0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                animateColorChange.toggle()
                                yOffset += Constants.labelHeight
                                isAnimationInProgress = false
                                didTap()
                            }
                        }
                    }
                }
            }, perform: {})
        case let .qrCodeDisabled(placeholderQRCode, button, didTap):
            VStack {
                VStack(spacing: .zero) {
                    Image(uiImage: placeholderQRCode ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.imageSize, height: Constants.imageSize)
                        .opacity(0.2)
                        .blur(radius: 3.0)
                    ZStack {
                        Capsule()
                            .foregroundColor(theme.color.background.screen.normal.color)
                            .frame(width: Constants.labelWidth, height: Constants.labelHeight)
                            .offset(x: 0, y: yOffset)
                        Text(button)
                            .lineLimit(1)
                            .font(theme.font.defaultBodyBold)
                            .foregroundColor(theme.color.interactive.primary.normal.color)
                            .offset(x: 0, y: yOffset)
                            .frame(maxWidth: Constants.labelWidth, maxHeight: Constants.labelHeight)
                            .padding(.horizontal, theme.spacing.horizontal.value8)
                    }
                    .frame(width: Constants.labelWidth, height: Constants.labelHeight)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: theme.spacing.vertical.value16, trailing: 0))
                }
                .background(isHighlighted ? theme.color.background.neutral.highlighted.color : theme.color.background.neutral.normal.color)
                .cornerRadius(Constants.cornerRadius)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .scaleEffect(scaleFactor)
            .onLongPressGesture(minimumDuration: 100, maximumDistance: .infinity, pressing: { pressing in
                if pressing {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(Animation.linear(duration: 0.1)) {
                        isHighlighted = false
                        scaleFactor = 0.96
                    }
                } else {
                    withAnimation(Animation.linear(duration: 0.1)) {
                        scaleFactor = 1.0
                        isHighlighted = false
                        didTap()
                    }
                }
            }, perform: {})
        }
    }
}
