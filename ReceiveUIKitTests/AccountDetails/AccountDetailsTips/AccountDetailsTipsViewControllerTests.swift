import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit
import TWUI

final class AccountDetailsTipsViewControllerTests: TWSnapshotTestCase {
    @MainActor
    func test_Screen() {
        let presenter = AccountDetailsTipsPresenterMock()
        let viewController = AccountDetailsTipsViewController(presenter: presenter)
        let viewModel = UpsellViewModel(
            headerModel: .init(title: "How to use GBP account details"),
            imageView: IllustrationView(asset: .image(Illustrations.globe.image)),
            leadingView: StackInlineAlertView().with {
                $0.setStyle(.warning)
                $0.configure(with: .init(message: "These are your old account details. They still work for now but they’ll be removed in the future. Use your new account details instead."))
            },
            items: [
                .init(
                    title: "Receive USD",
                    description: "You can only receive USD payments to your USD account details. To receive different currencies, open more account details.",
                    icon: Icons.money.image
                ),
                .init(
                    title: "Local payments from inside the US",
                    description: "Use your 'inside the US' details to receive local payments from people and businesses inside the US.",
                    icon: Icons.house.image
                ),
                .init(
                    title: "International payments from outside the US",
                    description: "Use your 'outside the US' details to receive international payments from people and businesses outside the US.",
                    icon: Icons.globe.image
                ),
            ],
            linkAction: .init(title: "Learn more about using USD account details"),
            footerModel: .init(primaryAction: .init(title: "Got it", handler: {}))
        )
        viewController.configure(with: viewModel)

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}
