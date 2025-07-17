import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class AccountDetailsV3ListViewControllerTests: TWSnapshotTestCase {
    private var viewController: AccountDetailsV3ListViewController!
    private var presenter: AccountDetailsV3ListPresenterMock!

    override func setUp() {
        super.setUp()
        presenter = AccountDetailsV3ListPresenterMock()
        viewController = AccountDetailsV3ListViewController(presenter: presenter)
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

extension AccountDetailsV3ListViewControllerTests {
    func makeViewModel() -> AccountDetailsV3ListViewModel {
        AccountDetailsV3ListViewModel(
            title: "Your account details",
            subtitle: "Choose a currency to see your details",
            originalSections: [
                .init(
                    title: nil,
                    items: [
                        .init(
                            avatar: ._icon(Icons.bank.image, badge: Icons.alert.image),
                            title: "Singapore dollar",
                            subtitle: "Domestic and international",
                            keywords: ["SGD"],
                            onTapAction: {}
                        ),
                        .init(
                            avatar: ._icon(Icons.bank.image, badge: Icons.alert.image),
                            title: "Canadian dollar",
                            subtitle: "Domestic and international",
                            keywords: ["CAD"],
                            onTapAction: {}
                        ),
                        .init(
                            avatar: ._icon(Icons.bank.image, badge: nil),
                            title: "Canadian dollar",
                            subtitle: "Domestic and international",
                            keywords: ["CAD"],
                            onTapAction: {}
                        ),
                    ]
                ),
                .init(
                    title: "Get more account details",
                    items: [
                        .init(
                            avatar: ._icon(Icons.bank.image, badge: nil),
                            title: "British pound",
                            subtitle: "Domestic and international",
                            keywords: ["GBP"],
                            onTapAction: {}
                        ),
                        .init(
                            avatar: ._icon(Icons.bank.image, badge: nil),
                            title: "British pound",
                            subtitle: "Domestic and international",
                            keywords: ["GBP"],
                            onTapAction: {}
                        ),
                        .init(
                            avatar: ._icon(Icons.bank.image, badge: nil),
                            title: "British pound",
                            subtitle: "Domestic and international",
                            keywords: ["GBP"],
                            onTapAction: {}
                        ),
                    ]
                ),
            ],
            onSearchTapped: {}
        )
    }
}
