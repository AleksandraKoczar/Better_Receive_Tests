import Foundation
import Neptune
import SwiftUI

struct PayWithWiseRequestDetailsView: View {
    var viewModel: ViewModel

    @Environment(\.dismiss)
    private var dismiss

    @Theme
    private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.rows, id: \.title) { model in
                LegacyListItem(viewModel: model)
            }
            if let config = viewModel.buttonConfiguration {
                Button(
                    action: Action(
                        title: config.title,
                        handler: {
                            dismiss()
                            config.handler()
                        }
                    )
                )
                .buttonStyle(.largeSecondaryNeutral)
                .padding(.vertical, theme.spacing.vertical.contentToButton)
            }
        }
        .preferredPadding(.horizontal, theme.padding.screen)
    }
}

// MARK: - ViewModel

extension PayWithWiseRequestDetailsView {
    struct ViewModel {
        let title: String
        let rows: [LegacyListItemViewModel]
        let buttonConfiguration: (title: String, handler: () -> Void)?
    }
}
