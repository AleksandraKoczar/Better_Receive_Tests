import Neptune
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit

final class QuickpayViewControllerTests: TWSnapshotTestCase {
    private let qrCode = UIImage.qrCode(from: "https://wise.com/abcdefg1234")!

    private var viewController: QuickpayViewController!
    private var presenter: QuickpayPresenterMock!

    override func setUp() {
        super.setUp()
        presenter = QuickpayPresenterMock()
        viewController = QuickpayViewController(presenter: presenter)
    }

    override func tearDown() {
        viewController = nil
        presenter = nil
        super.tearDown()
    }

    func test_screen_givenWisetagIsInactive() {
        let viewModel = makeWisetagInactiveViewModel()
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_givenWisetagIsActive() {
        let viewModel = makeWisetagActiveViewModel(isPersonaliseEnabled: true)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    func test_screen_givenWisetagIsActiveAndPersonaliseDisabled() {
        let viewModel = makeWisetagActiveViewModel(isPersonaliseEnabled: false)
        viewController.configure(with: viewModel)
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }

    // MARK: - Helpers

    private func makeWisetagInactiveViewModel() -> QuickpayViewModel {
        let cardItems = [
            QuickpayCardViewModel(
                id: 1,
                image: Neptune.Illustrations.plane.image,
                title: L10n.Quickpay.Carousel.Item1.title,
                subtitle: L10n.Quickpay.Carousel.Item1.subtitle,
                articleId: "plane"
            ),
            QuickpayCardViewModel(
                id: 2,
                image: Neptune.Illustrations.businessCard.image,
                title: L10n.Quickpay.Carousel.Item2.title,
                subtitle: L10n.Quickpay.Carousel.Item2.subtitle,
                articleId: "businessCard"
            ),
            QuickpayCardViewModel(
                id: 3,
                image: Neptune.Illustrations.shoppingBag.image,
                title: L10n.Quickpay.Carousel.Item3.title,
                subtitle: L10n.Quickpay.Carousel.Item3.subtitle,
                articleId: "shoppingBag"
            ),
        ]

        return QuickpayViewModel(
            avatar: ._initials(.init(name: LoremIpsum.short), badge: nil),
            title: LoremIpsum.short,
            subtitle: LoremIpsum.short,
            linkType: .inactive(inactiveLink: "Inactive"),
            footerAction: .init(title: "Turn on", handler: {}),
            nudge: nil,
            qrCode: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeDisabled(
                placeholderQRCode: qrCode,
                disabledText: LoremIpsum.short,
                onTap: {}
            )),
            navigationBarButtons: [
                QuickpayViewModel.ButtonViewModel(
                    icon: Icons.slider.image,
                    title: "",
                    action: {}
                ),
            ],
            circularButtons: [],
            cardItems: cardItems,
            onCardTap: { _ in }
        )
    }

    private func makeWisetagActiveViewModel(isPersonaliseEnabled: Bool) -> QuickpayViewModel {
        let cardItems = [
            QuickpayCardViewModel(
                id: 1,
                image: Neptune.Illustrations.plane.image,
                title: L10n.Quickpay.Carousel.Item1.title,
                subtitle: L10n.Quickpay.Carousel.Item1.subtitle,
                articleId: "plane"
            ),
            QuickpayCardViewModel(
                id: 2,
                image: Neptune.Illustrations.businessCard.image,
                title: L10n.Quickpay.Carousel.Item2.title,
                subtitle: L10n.Quickpay.Carousel.Item2.subtitle,
                articleId: "businessCard"
            ),
            QuickpayCardViewModel(
                id: 3,
                image: Neptune.Illustrations.shoppingBag.image,
                title: L10n.Quickpay.Carousel.Item3.title,
                subtitle: L10n.Quickpay.Carousel.Item3.subtitle,
                articleId: "shoppingBag"
            ),
        ]

        var circularButtons: [QuickpayViewModel.ButtonViewModel] = [
            QuickpayViewModel.ButtonViewModel(
                icon: Icons.shareIos.image,
                title: "Share",
                action: {}
            ),
        ]

        if isPersonaliseEnabled {
            circularButtons.append(QuickpayViewModel.ButtonViewModel(
                icon: Icons.shareIos.image,
                title: "Personalise",
                action: {}
            ))
        }

        return QuickpayViewModel(
            avatar: ._initials(.init(name: LoremIpsum.short), badge: nil),
            title: LoremIpsum.short,
            subtitle: LoremIpsum.short,
            linkType: .active(link: "active link", touchHandler: {}),
            footerAction: nil,
            nudge: nil,
            qrCode: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeEnabled(
                qrCode: qrCode,
                enabledText: LoremIpsum.veryShort,
                enabledTextOnTap: LoremIpsum.veryShort,
                onTap: {}
            )),
            navigationBarButtons: [
                QuickpayViewModel.ButtonViewModel(
                    icon: Icons.slider.image,
                    title: "",
                    action: {}
                ),
            ],
            circularButtons: circularButtons,
            cardItems: cardItems,
            onCardTap: { _ in }
        )
    }
}
