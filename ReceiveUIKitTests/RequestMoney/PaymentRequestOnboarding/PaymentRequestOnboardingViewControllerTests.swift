import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class PaymentRequestOnboardingViewControllerTests: TWSnapshotTestCase {
    func test_screen() throws {
        try XCTSkipAlways("flaky - Contains illustration")
        let presenter = PaymentRequestOnboardingPresenterMock()
        let viewController = PaymentRequestOnboardingViewController(presenter: presenter)
        let summaryViewModels: [PaymentRequestOnboardingViewModel.SummaryViewModel] = [
            .init(
                title: "Get paid by anyone, anywhere",
                description: "You say how much, what for, and by when.",
                icon: Icons.limit.image
            ),
            .init(
                title: "Share in seconds",
                description: "One link with everything someone needs to pay you.",
                icon: Icons.link.image
            ),
            .init(
                title: "Money in, job done",
                description: "Low or no fees mean you keep more of the money you make.",
                icon: Icons.requestReceive.image
            ),
        ]
        let viewModel = PaymentRequestOnboardingViewModel(
            titleText: "Request a payment",
            subtitleText: "Get paid simply — set up and share a link with your customer.",
            image: Neptune.Illustrations.receive.image,
            summaryViewModels: summaryViewModels,
            footerButtonAction: Action(title: "Start", handler: {})
        )
        viewController.configure(with: viewModel)

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}
