import Neptune
@testable import ReceiveUIKit
import TWFoundation
import TWTestingSupportKit

final class CreatePaymentRequestConfirmationPrivacyNoticeViewControllerFactoryTests: TWTestCase {
    func testViewController_GivenViewModel_ThenFieldValuesMatch() throws {
        let title = LoremIpsum.short
        let info = LoremIpsum.long
        let viewModel = CreatePaymentRequestConfirmationPrivacyNoticeViewModel(title: title, info: info)
        let presenter = CreatePaymentRequestConfirmationPresenterMock()

        let viewController = CreatePaymentRequestConfirmationPrivacyNoticeViewControllerFactory.make(
            viewModel: viewModel,
            presenter: presenter
        )
        XCTAssertEqual(viewController.title, title)

        guard let bottomSheet = viewController as? BottomSheetViewController else {
            XCTFail("View controller type mismatches")
            return
        }
        guard let subview = bottomSheet.arrangedSubviews.first,
              let container = subview as? StackContainerView<MarkdownLabel> else {
            XCTFail("Container view type mismatches")
            return
        }
        let infoLabel = container.view
        XCTAssertEqual(infoLabel.text, info)
        let urlString = Branding.current.urlString
        infoLabel.linkActionHandler(urlString)
        XCTAssertEqual(presenter.privacyPolicyTappedCallsCount, 1)
    }
}
