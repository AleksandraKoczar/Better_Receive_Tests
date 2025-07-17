@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UIKit

final class SalarySwitchOptionSelectionRouterTests: TWTestCase {
    private var router: SalarySwitchOptionSelectionRouterImpl!
    private var navigationHost: MockNavigationController!

    override func setUp() {
        super.setUp()

        navigationHost = MockNavigationController()
        router = SalarySwitchOptionSelectionRouterImpl(navigationHost: navigationHost)
    }

    override func tearDown() {
        router = nil
        navigationHost = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension SalarySwitchOptionSelectionRouterTests {
    func testDisplayingShareSheet_WhenDisplayingShareSheet_ThenClassTypeMatches() {
        router.displayShareSheet(content: "Hi John Doe,", sender: UIView())
        XCTAssertTrue(navigationHost.lastPresentedViewController is UIActivityViewController)
    }

    func testDisplayingOwnershipProofDocument_GivenFilePath_WhenDisplayTriggered_ThenDocumentPreviewWillStart() throws {
        let viewController = StubDocumentInteractionViewController()
        navigationHost.present(viewController, animated: false)
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(#function + ".pdf")

        try "Jane Doe"
            .data(using: .utf8)?
            .write(to: path)
        router.displayOwnershipProofDocument(url: path, delegate: viewController)

        XCTAssertTrue(viewController.previewWillStart)
    }
}
