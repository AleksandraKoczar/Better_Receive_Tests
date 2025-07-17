import Neptune
import SwiftUI

struct ContactPickerRecentContactsHorizontalSectionView: View {
    let models: [ContactPickerRecentContact]
    let onTapped: (ContactPickerRecentContact) -> Void

    @Theme
    private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: theme.spacing.horizontal.value32) {
                ForEach(models) { model in
                    RecentContactCellView(
                        viewModel: model.asCellViewModel()
                    )
                    .onTapGesture {
                        onTapped(model)
                    }
                }
            }
            .padding(.horizontal, theme.spacing.horizontal.componentDefault)
            .backgroundColor()
            .theme(\.primary)
        }
        .padding(.top, theme.spacing.vertical.value16)
    }
}

private extension ContactPickerRecentContact {
    func asCellViewModel() -> RecentContactCellViewModel {
        RecentContactCellViewModel(
            title: title,
            avatarPublisher: avatarPublisher
        )
    }
}
