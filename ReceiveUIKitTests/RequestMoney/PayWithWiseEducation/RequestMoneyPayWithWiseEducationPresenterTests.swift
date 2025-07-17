import Neptune
import ReceiveKit
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit

@MainActor
final class RequestMoneyPayWithWiseEducationPresenterTests: TWTestCase {
    private var presenter: RequestMoneyPayWithWiseEducationPresenterImpl!
    private var routingDelegate: RequestMoneyPayWithWiseEducationRoutingDelegateMock!
    private var view: RequestMoneyPayWithWiseEducationViewMock!

    override func setUp() {
        super.setUp()
        routingDelegate = RequestMoneyPayWithWiseEducationRoutingDelegateMock()
        view = RequestMoneyPayWithWiseEducationViewMock()
        presenter = RequestMoneyPayWithWiseEducationPresenterImpl(routingDelegate: routingDelegate)
    }

    override func tearDown() {
        presenter = nil
        routingDelegate = nil
        view = nil
        super.tearDown()
    }

    func test_start() throws {
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        let expectedDescription = makeDescriptionMarkupLabel()
        let expected = makeViewModel(description: expectedDescription)
        expectNoDifference(viewModel, expected)
    }

    func test_primaryButtonTapped_thenDismiss() throws {
        presenter.start(with: view)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.action.handler()

        XCTAssertEqual(routingDelegate.dismissCallsCount, 1)
    }

    func test_descriptionInviteFriendsLinkTapped_thenShowInviteFriends() throws {
        presenter.start(with: view)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)

        viewModel.description?.action()

        XCTAssertEqual(routingDelegate.showInviteFriendsCallsCount, 1)
    }
}

// MARK: - Helpers

private extension RequestMoneyPayWithWiseEducationPresenterTests {
    func makeDescriptionMarkupLabel() -> RequestMoneyPayWithWiseEducationViewModel.MarkupLabel {
        RequestMoneyPayWithWiseEducationViewModel.MarkupLabel(
            text: L10n.RequestMoney.PayWithWiseEducation.description,
            action: {}
        )
    }

    func makeViewModel(description: RequestMoneyPayWithWiseEducationViewModel.MarkupLabel?) -> RequestMoneyPayWithWiseEducationViewModel {
        RequestMoneyPayWithWiseEducationViewModel(
            image: Illustrations.megaphone.image,
            title: L10n.RequestMoney.PayWithWiseEducation.title,
            subtitle: L10n.RequestMoney.PayWithWiseEducation.subtitle,
            description: description,
            action: Action(
                title: L10n.RequestMoney.PayWithWiseEducation.PrimaryButton.title,
                handler: {}
            )
        )
    }
}
