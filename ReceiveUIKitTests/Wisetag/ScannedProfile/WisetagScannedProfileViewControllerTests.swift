import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class WisetagScannedProfileViewControllerTests: TWSnapshotTestCase {
    private var viewController: WisetagScannedProfileViewController!
    private var presenter: WisetagScannedProfilePresenterMock!

    override func setUp() {
        super.setUp()
        presenter = WisetagScannedProfilePresenterMock()
        viewController = WisetagScannedProfileViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }

    func test_screen_givenFindingUser() {
        let viewModel = makeFindingUserViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_givenUserFound() {
        let viewModel = makeUserFoundViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_givenRecipientAdded() {
        let viewModel = makeRecipientAddedViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    // MARK: - Helpers

    private func makeRecipientAddedViewModel() -> WisetagScannedProfileViewModel {
        let header = WisetagScannedProfileViewModel.HeaderViewModel(
            avatar: .canned,
            title: LoremIpsum.veryShort,
            subtitle: LoremIpsum.veryShort,
            alert: nil
        )

        let button = WisetagScannedProfileViewModel.ButtonViewModel(
            icon: Icons.fastFlag.image,
            title: LoremIpsum.veryShort,
            enabled: true,
            action: nil
        )

        let buttons = Array(repeating: button, count: 3)

        let footer = WisetagScannedProfileViewModel.FooterViewModel(
            buttons: buttons,
            isLoading: false
        )

        return WisetagScannedProfileViewModel(
            header: header,
            footer: footer
        )
    }

    private func makeFindingUserViewModel() -> WisetagScannedProfileViewModel {
        let footer = WisetagScannedProfileViewModel.FooterViewModel(
            buttons: nil,
            isLoading: true
        )

        return WisetagScannedProfileViewModel(
            header: nil,
            footer: footer
        )
    }

    private func makeUserFoundViewModel() -> WisetagScannedProfileViewModel {
        let header = WisetagScannedProfileViewModel.HeaderViewModel(
            avatar: .canned,
            title: LoremIpsum.veryShort,
            subtitle: LoremIpsum.veryShort,
            alert: nil
        )

        let button = WisetagScannedProfileViewModel.ButtonViewModel(
            icon: Icons.fastFlag.image,
            title: LoremIpsum.veryShort,
            enabled: true,
            action: nil
        )

        let buttons = Array(repeating: button, count: 3)

        let footer = WisetagScannedProfileViewModel.FooterViewModel(
            buttons: buttons,
            isLoading: false
        )

        return WisetagScannedProfileViewModel(
            header: header,
            footer: footer
        )
    }
}
