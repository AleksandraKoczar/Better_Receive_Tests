import Neptune
import SwiftUI
import TransferResources

struct QuickpayCardContent: View {
    @Theme
    private var theme

    let item: QuickpayCardViewModel

    var body: some View {
        VStack(alignment: .center, spacing: theme.spacing.horizontal.value12) {
            Image(uiImage: item.image)
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .padding(.horizontal, theme.spacing.horizontal.value32)
            VStack(alignment: .leading, spacing: theme.spacing.horizontal.value12) {
                PlainText(item.title)
                    .textStyle(\.bodyTitle)
                    .truncationMode(.tail)
                PlainText(item.subtitle)
                    .textStyle(\.defaultBody)
                    .truncationMode(.tail)
            }
            .padding(.bottom, theme.spacing.horizontal.value24)
            .padding(.horizontal, theme.spacing.horizontal.value16)
        }
    }
}
