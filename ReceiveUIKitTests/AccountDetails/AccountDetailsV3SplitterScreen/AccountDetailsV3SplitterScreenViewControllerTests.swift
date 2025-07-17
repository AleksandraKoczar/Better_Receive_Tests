import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class AccountDetailsV3SplitterScreenViewControllerTests: TWSnapshotTestCase {
    private var viewController: AccountDetailsV3SplitterScreenViewController!
    private var presenter: AccountDetailsV3SplitterScreenPresenterMock!

    override func setUp() {
        super.setUp()
        presenter = AccountDetailsV3SplitterScreenPresenterMock()
        viewController = AccountDetailsV3SplitterScreenViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }

    func test_screen() {
        let viewModel = makeViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}

extension AccountDetailsV3SplitterScreenViewControllerTests {
    func makeViewModel() -> AccountDetailsV3SplitterScreenViewModel {
        AccountDetailsV3SplitterScreenViewModel(
            currency: .PLN,
            items: [
                .init(
                    title: LoremIpsum.short,
                    subtitle: LoremIpsum.medium,
                    body: LoremIpsum.medium,
                    avatar: .icon(Icons.bank.image, badge: Icons.alert.image),
                    onTapAction: {},
                    state: .active
                ),
                .init(
                    title: LoremIpsum.short,
                    subtitle: LoremIpsum.medium,
                    body: LoremIpsum.medium,
                    avatar: .icon(Icons.bank.image, badge: nil),
                    onTapAction: {},
                    state: .active
                ),
            ]
        )
    }
}
