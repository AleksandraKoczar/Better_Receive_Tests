import Foundation
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWTestingSupportKit

final class ReceiveRestrictionViewControllerTests: TWSnapshotTestCase {
    private var presenter: ReceiveRestrictionPresenterMock!
    private var viewController: ReceiveRestrictionViewController!

    override func setUp() {
        super.setUp()

        presenter = ReceiveRestrictionPresenterMock()
        viewController = ReceiveRestrictionViewController(
            presenter: presenter
        )
    }

    override func tearDown() {
        presenter = nil
        viewController = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension ReceiveRestrictionViewControllerTests {
    func testFullLayout() {
        let viewModel = ReceiveRestrictionViewModel(
            restriction: ReceiveRestriction.build(
                title: LoremIpsum.veryShort,
                illustration: "exclamation-mark",
                body: LoremIpsum.short,
                alert: ReceiveRestriction.Alert.build(
                    type: .warning,
                    message: LoremIpsum.medium
                ),
                sections: [
                    summarySection,
                    instructionSection,
                ],
                footer: [
                    ReceiveRestriction.Footer.build(
                        type: .dismiss,
                        label: "Dusmuss"
                    ),
                    ReceiveRestriction.Footer.build(
                        type: .link(nil),
                        label: "Learn more"
                    ),
                ]
            )
        )
        viewController.configure(viewModel: viewModel)
        viewController.view.layoutForTest(fittingWidth: 400, fittingHeight: 1000)

        TWSnapshotVerifyView(
            viewController.view
        )
    }

    func testInstructionAndPrimaryButtonOnly() {
        let viewModel = ReceiveRestrictionViewModel(
            restriction: ReceiveRestriction.build(
                title: LoremIpsum.veryShort,
                illustration: "electric-plug",
                body: LoremIpsum.short,
                alert: ReceiveRestriction.Alert.build(
                    type: .warning,
                    message: LoremIpsum.medium
                ),
                sections: [
                    instructionSection,
                ],
                footer: [
                    ReceiveRestriction.Footer.build(
                        type: .dismiss,
                        label: "Dusmuss"
                    ),
                ]
            )
        )
        viewController.configure(viewModel: viewModel)
        viewController.view.layoutForTest(fittingWidth: 400, fittingHeight: 850)

        TWSnapshotVerifyView(
            viewController.view
        )
    }

    func testSummaryAndLinkButtonOnly() {
        let viewModel = ReceiveRestrictionViewModel(
            restriction: ReceiveRestriction.build(
                title: LoremIpsum.veryShort,
                illustration: "magnifying-glass",
                body: LoremIpsum.short,
                alert: ReceiveRestriction.Alert.build(
                    type: .warning,
                    message: LoremIpsum.medium
                ),
                sections: [
                    summarySection,
                ],
                footer: [
                    ReceiveRestriction.Footer.build(
                        type: .link(nil),
                        label: "Learn more"
                    ),
                ]
            )
        )
        viewController.configure(viewModel: viewModel)
        viewController.view.layoutForTest(fittingWidth: 400, fittingHeight: 850)

        TWSnapshotVerifyView(
            viewController.view
        )
    }
}

// MARK: - Helpers

private extension ReceiveRestrictionViewControllerTests {
    var summarySection: ReceiveRestriction.Section {
        .summary(
            ReceiveRestriction.Section.SummarySection.build(
                header: ReceiveRestriction.Section.Header.build(
                    title: "Section title",
                    action: ReceiveRestriction.Section.Action.build(
                        label: "Tap me",
                        uri: "UriStr"
                    )
                ),
                summaries: [
                    ReceiveRestriction.Section.Summary.build(
                        content: "Camiryo",
                        icon: "info-circle"
                    ),
                    .build(
                        content: LoremIpsum.short,
                        icon: "insurance"
                    ),
                    .build(
                        content: String(LoremIpsum.short.reversed()),
                        icon: "limit"
                    ),
                ]
            )
        )
    }

    var instructionSection: ReceiveRestriction.Section {
        .instruction(
            ReceiveRestriction.Section.InstructionSection.build(
                header: ReceiveRestriction.Section.Header.build(
                    title: "Section title",
                    action: nil
                ),
                instructions: [
                    ReceiveRestriction.Section.Instruction.build(
                        type: .positive,
                        content: LoremIpsum.short
                    ),
                    .build(
                        type: .negative,
                        content: String(LoremIpsum.short.reversed())
                    ),
                ]
            )
        )
    }
}
