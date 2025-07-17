import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class WisetagHeaderViewTests: TWSnapshotTestCase {
    func test_view_withLinkButton() {
        let viewModel = makeViewModel(
            linkButton: .init(
                title: LoremIpsum.veryShort,
                leadingIcon: Icons.fastFlag.image,
                handler: {}
            )
        )
        let view = WisetagHeaderView()
        view.configure(with: viewModel)
        view.layoutForTest(fittingWidth: 390)
        TWSnapshotVerifyView(view)
    }

    func test_view_withoutLinkButton() {
        let viewModel = makeViewModel(linkButton: nil)
        let view = WisetagHeaderView()
        view.configure(with: viewModel)
        view.layoutForTest(fittingWidth: 390)
        TWSnapshotVerifyView(view)
    }

    // MARK: - Helpers

    private func makeViewModel(linkButton: SmallButtonView.ViewModel?) -> WisetagHeaderViewModel {
        WisetagHeaderViewModel(
            avatar: AvatarViewModel.initials(Initials(name: "Harry Potter")),
            title: LoremIpsum.veryShort,
            linkType: .active(link: LoremIpsum.veryShort, touchHandler: {})
        )
    }
}
