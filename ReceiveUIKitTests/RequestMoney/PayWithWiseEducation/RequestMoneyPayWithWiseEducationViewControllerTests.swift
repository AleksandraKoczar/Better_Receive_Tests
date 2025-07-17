import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class RequestMoneyPayWithWiseEducationViewControllerTests: TWSnapshotTestCase {
    private var viewController: RequestMoneyPayWithWiseEducationViewController!
    private var presenter: RequestMoneyPayWithWiseEducationPresenterMock!

    override func setUp() {
        super.setUp()
        presenter = RequestMoneyPayWithWiseEducationPresenterMock()
        viewController = RequestMoneyPayWithWiseEducationViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }

    func test_screen_withDescriptionLabel() {
        let description = RequestMoneyPayWithWiseEducationViewModel.MarkupLabel(
            text: "Use your <link>invite link</link> to earn rewards and get paid easy, every time.",
            action: {}
        )
        let viewModel = makeViewModel(description: description)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController)
    }

    func test_screen_withoutDescriptionLabel() {
        let viewModel = makeViewModel(description: nil)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController)
    }
}

// MARK: - Helpers

private extension RequestMoneyPayWithWiseEducationViewControllerTests {
    func makeViewModel(description: RequestMoneyPayWithWiseEducationViewModel.MarkupLabel?) -> RequestMoneyPayWithWiseEducationViewModel {
        RequestMoneyPayWithWiseEducationViewModel(
            image: Illustrations.megaphone.image,
            title: "What's Pay with Wise?",
            subtitle: "Receive free and instant payments from anyone on Wise.",
            description: description,
            action: Action(
                title: "Got it",
                handler: {}
            )
        )
    }
}
