import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit

final class WisetagContactOnWiseViewControllerTests: TWSnapshotTestCase {
    func test_screen() {
        let viewModel = makeViewModel()
        let presenter = WisetagContactOnWisePresenterMock()
        let viewController = WisetagContactOnWiseViewController(presenter: presenter)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController)
    }

    func test_screenWithAlert() {
        let viewModel = makeViewModelWithAlert()
        let presenter = WisetagContactOnWisePresenterMock()
        let viewController = WisetagContactOnWiseViewController(presenter: presenter)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController)
    }

    // MARK: - Helpers

    private func makeViewModelWithAlert() -> WisetagContactOnWiseViewModel {
        WisetagContactOnWiseViewModel(
            title: LoremIpsum.short,
            subtitle: LoremIpsum.medium,
            inlineAlert: .init(viewModel: .init(markdown: LoremIpsum.medium), style: .neutral),
            wisetagOption: makeWisetagOption(),
            action: Action(
                title: LoremIpsum.veryShort,
                handler: {}
            )
        )
    }

    private func makeViewModel() -> WisetagContactOnWiseViewModel {
        WisetagContactOnWiseViewModel(
            title: LoremIpsum.short,
            subtitle: LoremIpsum.medium,
            inlineAlert: nil,
            wisetagOption: makeWisetagOption(),
            action: Action(
                title: LoremIpsum.veryShort,
                handler: {}
            )
        )
    }

    private func makeWisetagOption() -> WisetagContactOnWiseViewModel.SwitchOption {
        WisetagContactOnWiseViewModel.SwitchOption(
            viewModel: SwitchOptionViewModel(
                model: OptionViewModel(
                    title: LoremIpsum.short,
                    subtitle: LoremIpsum.veryShort,
                    avatar: .initials(Initials(name: "Harry Potter"))
                )
            ),
            onToggle: { _ in }
        )
    }
}
