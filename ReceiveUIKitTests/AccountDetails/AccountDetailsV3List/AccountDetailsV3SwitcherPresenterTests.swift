import Neptune
import NeptuneTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKit
import UserKitTestingSupport
import WiseCore

final class AccountDetailsV3SwitcherPresenterTests: TWTestCase {
    private var presenter: AccountDetailsV3SwitcherPresenterImpl!
    private let profile = FakeBusinessProfileInfo().asProfile()
    private var actionHandler: ReceiveMethodActionHandlerMock!
    private var receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCaseMock!
    private var view: AccountDetailsV3ListViewMock!

    override func setUp() {
        super.setUp()

        view = AccountDetailsV3ListViewMock()
        receiveMethodNavigationUseCase = ReceiveMethodNavigationUseCaseMock()
        actionHandler = ReceiveMethodActionHandlerMock()
        presenter = AccountDetailsV3SwitcherPresenterImpl(
            profile: profile,
            actionHandler: actionHandler,
            receiveMethodNavigationUseCase: receiveMethodNavigationUseCase,
            scheduler: .immediate
        )

        trackForMemoryLeak(instance: presenter) { [weak self] in
            self?.presenter = nil
        }
    }

    override func tearDown() {
        presenter = nil
        view = nil
        receiveMethodNavigationUseCase = nil
        actionHandler = nil
        super.tearDown()
    }

    func test_start_GivenSuccess_thenConfigureModel() {
        receiveMethodNavigationUseCase.getReceiveMethodNavigationReturnValue = .just(makeReceiveMethodNavigation())

        presenter.start(with: view)

        XCTAssertEqual(view.configureCallsCount, 1)
        XCTAssertEqual(view.configureReceivedWith?.sections[0].items[0].title, LoremIpsum.short)
        XCTAssertEqual(view.configureReceivedWith?.sections[0].items[0].subtitle, LoremIpsum.medium)
    }

    func test_start_GivenError_thenConfigureModelWithError() {
        receiveMethodNavigationUseCase.getReceiveMethodNavigationReturnValue = .fail(with: GenericError("Failed to fetch receive method"))

        let expectedViewModel = ErrorViewModel.canned

        presenter.start(with: view)

        XCTAssertEqual(view.configureWithErrorCallsCount, 1)
        XCTAssertEqual(expectedViewModel, view.configureWithErrorReceivedErrorViewModel)
    }

    func test_start_handleAction() throws {
        receiveMethodNavigationUseCase.getReceiveMethodNavigationReturnValue = .just(makeReceiveMethodNavigation())

        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedWith)

        viewModel.sections[0].items[0].onTapAction!()

        XCTAssertEqual(actionHandler.handleReceiveMethodActionCallsCount, 1)
        XCTAssertEqual(actionHandler.handleReceiveMethodActionReceivedAction, .view(id: .canned, methodType: .accountDetails))
    }

    private func makeReceiveMethodNavigation() -> ReceiveMethodNavigation {
        ReceiveMethodNavigation.build(
            sections: [
                .build(
                    title: nil,
                    items: [
                        .build(
                            avatars: [.build(type: .image, value: "urn:wise:bank:image")],
                            badge: nil,
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium,
                            body: nil,
                            action: .build(
                                type: .view,
                                payload: .view(.build(id: .canned, methodType: .accountDetails))
                            ),
                            state: .active
                        ),
                    ]
                ),
            ])
    }
}
