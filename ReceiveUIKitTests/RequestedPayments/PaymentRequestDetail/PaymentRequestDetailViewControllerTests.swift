import AnalyticsKitTestingSupport
import Combine
import Foundation
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport

final class PaymentRequestDetailViewControllerTests: TWSnapshotTestCase {
    func test_screen() {
        let presenter = PaymentRequestDetailPresenterMock()
        let viewController = PaymentRequestDetailViewController(presenter: presenter)
        let viewModel = makeViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_avatar() {
        let presenter = PaymentRequestDetailPresenterMock()
        let viewController = PaymentRequestDetailViewController(presenter: presenter)
        let icon = AvatarViewModel.image(Icons.requestSend.image)
        let viewModel = makeViewModel(icon: icon)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_initials() {
        let presenter = PaymentRequestDetailPresenterMock()
        let viewController = PaymentRequestDetailViewController(presenter: presenter)
        let icon = AvatarViewModel.initials(Initials(value: LoremIpsum.short))
        let viewModel = makeViewModel(icon: icon)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_positiveActionOnly() {
        let viewController = PaymentRequestDetailViewController(presenter: PaymentRequestDetailPresenterMock())
        let viewModel = makeViewModel(
            footerViewModel: .init(
                primaryAction: .init(
                    title: "Mark as paid",
                    handler: {}
                ),
                secondaryAction: nil,
                configuration: .positiveOnly
            )
        )
        viewController.configure(with: viewModel)

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_positiveAndNegativeAction() {
        let viewController = PaymentRequestDetailViewController(presenter: PaymentRequestDetailPresenterMock())
        let viewModel = makeViewModel(
            footerViewModel: .init(
                primaryAction: .init(
                    title: "Mark as paid",
                    handler: {}
                ),
                secondaryAction: .init(
                    title: "Cancel request",
                    handler: {}
                ),
                configuration: .positiveAndNegative
            )
        )
        viewController.configure(with: viewModel)

        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    // MARK: - Helpers

    private func makeViewModel(
        icon: AvatarViewModel = .icon(Icons.requestSend.image),
        footerViewModel: PaymentRequestDetailViewModel.FooterViewModel? = nil
    ) -> PaymentRequestDetailViewModel {
        let headerViewModel = PaymentRequestDetailViewModel.HeaderViewModel(
            icon: icon,
            iconStyle: .size56,
            title: LoremIpsum.short,
            subtitle: LoremIpsum.medium
        )

        let defaultFooterViewModel = PaymentRequestDetailViewModel.FooterViewModel(
            primaryAction: Action(
                title: "paymentRequest.detail.footer.cancel",
                handler: {}
            ),
            secondaryAction: nil,
            configuration: .negativeOnly
        )
        return PaymentRequestDetailViewModel(
            header: headerViewModel,
            sections: [
                PaymentRequestDetailViewModel.SectionViewModel(
                    header: SectionHeaderViewModel(title: LoremIpsum.short),
                    items: [
                        .optionItem(
                            PaymentRequestDetailViewModel.SectionViewModel.OptionViewModel(
                                option: OptionViewModel(
                                    title: LoremIpsum.short,
                                    subtitle: LoremIpsum.medium,
                                    avatar: .icon(Icons.receive.image)
                                ),
                                onTap: {}
                            )
                        ),
                    ]
                ),
                PaymentRequestDetailViewModel.SectionViewModel(
                    header: SectionHeaderViewModel(title: LoremIpsum.short),
                    items: [
                        .listItem(
                            LegacyListItemViewModel(
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium
                            )
                        ),
                        .listItem(
                            LegacyListItemViewModel(
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                action: Action(
                                    title: LoremIpsum.short,
                                    handler: {}
                                )
                            )
                        ),
                    ]
                ),
            ],
            footer: footerViewModel ?? defaultFooterViewModel
        )
    }
}
