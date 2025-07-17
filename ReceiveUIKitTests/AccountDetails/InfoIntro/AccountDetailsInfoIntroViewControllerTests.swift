import Neptune
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWTestingSupportKit
import UIKit
import UserKitTestingSupport

final class AccountDetailsInfoIntroViewControllerTests: TWSnapshotTestCase {
    private var viewController: AccountDetailsInfoIntroViewController!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()

        let presenter = AccountDetailsInfoIntroPresenterMock()
        viewController = AccountDetailsInfoIntroViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil

        super.tearDown()
    }

    func testInfoScreen_GivenSummary() {
        let viewModel = makeViewModel(showSummary: true)
        viewController.configure(viewModel: viewModel)

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func testInfoScreen_GivenNoSummary() {
        let viewModel = makeViewModel(showSummary: false)
        viewController.configure(viewModel: viewModel)

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}

// MARK: - Helpers

private extension AccountDetailsInfoIntroViewControllerTests {
    func makeViewModel(showSummary: Bool) -> AccountDetailsInfoIntroViewModel {
        let infoViewModel: AccountDetailsReceiveOptionInfoViewModel? = {
            guard showSummary else { return nil }
            return AccountDetailsReceiveOptionInfoViewModel(
                header: nil,
                rows: [
                    AccountDetailsInfoRowViewModel(
                        title: "Account holder",
                        information: "John Doe",
                        isObfuscated: false,
                        action: nil
                    ),
                    AccountDetailsInfoRowViewModel(
                        title: "Account number",
                        information: "123456789",
                        isObfuscated: false,
                        action: nil
                    ),
                ],
                footer: AccountDetailsInfoFooterViewModel(
                    title: "View full",
                    style: .link,
                    action: {}
                )
            )
        }()
        return AccountDetailsInfoIntroViewModel(
            title: LargeTitleViewModel(title: "My GBP account details"),
            infoViewModel: infoViewModel,
            sectionHeader: SectionHeaderViewModel(title: "Things you can do"),
            navigationActions: [
                AccountDetailsInfoIntroNavigationAction(
                    viewModel: OptionViewModel(
                        title: "Receive your salary",
                        avatar: AvatarViewModel.category(
                            Icons.payIn.image,
                            fillColor: SemanticColor.base.clear,
                            tintColor: SemanticColor.content.primary
                        )
                    ),
                    action: {}
                ),
                AccountDetailsInfoIntroNavigationAction(
                    viewModel: OptionViewModel(
                        title: "Receive money",
                        avatar: AvatarViewModel.category(
                            Icons.emailAndMobile.image,
                            fillColor: SemanticColor.base.clear,
                            tintColor: SemanticColor.content.primary
                        )
                    ),
                    action: {}
                ),
            ]
        )
    }
}
