import ContactsKit
import Foundation
import Neptune
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import SwiftUI
import TWFoundation
import TWTestingSupportKit
import WiseAtomsAssets
import WiseCore

final class PayWithWiseViewControllerTests: TWSnapshotTestCase {
    func testLayout() {
        let presenter = PayWithWisePresenterMock()
        let breakdownViewFactory = BreakdownViewFactoryMock()
        breakdownViewFactory.makeReturnValue = AnyView(EmptyView())

        let viewController = PayWithWiseViewController(
            presenter: presenter,
            breakdownViewFactory: breakdownViewFactory
        )

        let option = OptionViewModel(
            title: "John Doe",
            subtitle: "Payment to personal profile",
            avatar: AvatarViewModel.initials(
                Initials(
                    name: "Doe Jane"
                )
            )
        )

        let sectionOption1 = PayWithWiseViewModel.Section.SectionOption(option: option, action: {})
        let profileSection = PayWithWiseViewModel.Section.build(header: SectionHeaderViewModel(
            title: "Where you're paying from "
        ), sectionOptions: [sectionOption1])

        viewController.configure(
            viewModel: PayWithWiseViewModel.loaded(
                PayWithWiseViewModel.Loaded(
                    shouldHideDetailsButton: false,
                    header: PayWithWiseHeaderView.ViewModel(
                        title: .init(title: "100 EUR"),
                        recipientName: "Aleksandra",
                        description: "cookies",
                        avatarImage: .just(AvatarViewModel(avatar: AvatarModel.image(Illustrations.electricPlug.image)))
                    ),
                    paymentSection: profileSection,
                    breakdownItems: [],
                    inlineAlert: PayWithWiseViewModel.Alert(
                        viewModel: InlineAlertViewModel(message: LoremIpsum.medium),
                        style: InlineAlertStyle.negative
                    ),
                    footer: PayWithWiseFooterViewModel(
                        firstButton: PayWithWiseFooterViewModel.FirstButtonConfig(
                            title: "Pay",
                            style: .primary,
                            isEnabled: true,
                            action: {}
                        ),
                        secondButton: PayWithWiseFooterViewModel.SecondButtonConfig(
                            title: "Reject",
                            style: .negative,
                            isEnabled: true,
                            action: {}
                        )
                    )
                )
            )
        )
        TWSnapshotVerifyViewController(viewController.navigationWrapped())
    }
}
