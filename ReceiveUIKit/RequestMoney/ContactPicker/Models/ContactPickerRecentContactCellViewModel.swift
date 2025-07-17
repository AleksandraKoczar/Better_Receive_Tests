import Combine
import Neptune
import SwiftUI

final class RecentContactCellViewModel: ObservableObject {
    @Published
    private(set) var title: String
    @Published
    private(set) var avatar: AvatarViewModel

    init(
        title: String,
        avatarPublisher: AnyPublisher<AvatarViewModel, Never>
    ) {
        self.title = title
        avatar = .initials(
            .init(name: title),
            badge: nil
        )

        avatarPublisher
            .assign(to: &$avatar)
    }
}

struct RecentContactCellView: View {
    @Theme
    private var theme

    @ObservedObject
    private var viewModel: RecentContactCellViewModel

    init(viewModel: RecentContactCellViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Avatar(viewModel.avatar)
                .style(.size72)
                .outline(false)

            PlainText(viewModel.title)
                .textStyle(\.defaultBody.centered)
                .lineLimit(2)
                .expandVertically() // to make lineLimit work
        }
        .frame(width: 72)
    }
}
