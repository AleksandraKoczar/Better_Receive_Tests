import Neptune
import SwiftUI

struct AccountDetailsV3SplitterScreenView: View {
    @Theme
    private var theme

    let model: AccountDetailsV3SplitterScreenViewModel

    init(model: AccountDetailsV3SplitterScreenViewModel) {
        self.model = model
    }

    var body: some View {
        VStack(alignment: .center, spacing: theme.spacing.horizontal.value16) {
            ForEach(model.items) { item in
                AccountDetailsV3SplitterScreenItemView(model: item)
            }
        }
    }
}
