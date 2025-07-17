import Neptune
import SwiftUI
import TransferResources

struct ReviewRefundView: View {
    @ObservedObject
    private var viewModel: ReviewRefundViewModel

    @Theme
    var theme

    init(viewModel: ReviewRefundViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        LCEView(
            viewModel: viewModel,
            refreshAction: {},
            content: content(for:)
        )
        .footer(item: viewModel.state.content) {
            PrimaryButton(viewModel: .init(title: $0.buttonTitle, handler: {
                Task {
                    await viewModel.refundTapped()
                }
            }))
            SecondaryButton(viewModel: .init(Action(title: L10n.PaymentRequest.Refund.Review.Button.edit, handler: {
                viewModel.editTapped()
            })))
        }
        .task {
            viewModel.configureView()
        }
    }

    @ViewBuilder
    private func content(for content: ReviewRefundContent) -> some View {
        VStack(alignment: .leading) {
            PlainText(L10n.PaymentRequest.Refund.Review.title)
                .textStyle(\.screenTitle)
                .padding(.bottom, theme.spacing.vertical.betweenSections)

            InlineAlert(viewModel: .init(message: L10n.PaymentRequest.Refund.Review.disclaimer))
                .padding(.bottom, theme.spacing.vertical.componentDefault)

            ForEach(content.sections) { section in
                VStack {
                    SectionHeader(viewModel: .init(title: section.title))
                    ForEach(section.items) { item in
                        LegacyListItem(viewModel: .init(
                            title: item.title,
                            subtitle: item.subtitle,
                            avatar: nil
                        ))
                    }
                }
                .padding(.bottom, theme.spacing.vertical.betweenSections)
            }
        }
        .padding(.horizontal, theme.spacing.horizontal.componentDefault)
    }
}
