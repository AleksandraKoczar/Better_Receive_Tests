import NeptuneTestingSupport
import Prism
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

final class AccountDetailsV3SplitterScreenPresenterTests: TWTestCase {
    private var presenter: AccountDetailsV3SplitterScreenPresenterImpl!
    private let profile = FakeBusinessProfileInfo().asProfile()
    private var router: ReceiveMethodActionHandlerMock!
    private var receiveMethodNavigationUseCase: ReceiveMethodNavigationUseCaseMock!
    private var view: AccountDetailsV3SplitterScreenListViewMock!
    private var analyticsTracker: ReceiveMethodsNavigationTrackingMock!
    private let currency = CurrencyCode("PLN")

    override func setUp() {
        super.setUp()

        view = AccountDetailsV3SplitterScreenListViewMock()
        receiveMethodNavigationUseCase = ReceiveMethodNavigationUseCaseMock()
        router = ReceiveMethodActionHandlerMock()
        analyticsTracker = ReceiveMethodsNavigationTrackingMock()

        presenter = AccountDetailsV3SplitterScreenPresenterImpl(
            currency: currency,
            profile: profile,
            router: router,
            receiveMethodNavigationUseCase: receiveMethodNavigationUseCase,
            analyticsTracker: analyticsTracker,
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
        router = nil
        analyticsTracker = nil
        super.tearDown()
    }

    func test_start_GivenSuccess_thenConfigureModel() {
        receiveMethodNavigationUseCase.getReceiveMethodNavigationReturnValue = .just(makeReceiveMethodNavigation())

        presenter.start(with: view)

        XCTAssertEqual(view.configureCallsCount, 1)
        XCTAssertEqual(view.configureReceivedWith?.items[0].title, LoremIpsum.short)
        XCTAssertEqual(view.configureReceivedWith?.items[0].subtitle, LoremIpsum.medium)
        XCTAssertEqual(analyticsTracker.onLoadedCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onLoadedReceivedArguments?.isSuccess, true)
    }

    func test_start_GivenError_thenConfigureModelWithError() {
        receiveMethodNavigationUseCase.getReceiveMethodNavigationReturnValue = .fail(with: GenericError("Failed to fetch receive method"))

        let expectedViewModel = ErrorViewModel.canned

        presenter.start(with: view)

        XCTAssertEqual(view.configureWithErrorCallsCount, 1)
        XCTAssertEqual(expectedViewModel, view.configureWithErrorReceivedErrorViewModel)
        XCTAssertEqual(analyticsTracker.onLoadedCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onLoadedReceivedArguments?.isSuccess, false)
    }

    func test_start_handleAction() throws {
        receiveMethodNavigationUseCase.getReceiveMethodNavigationReturnValue = .just(makeReceiveMethodNavigation())

        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedWith)

        viewModel.items[0].onTapAction!()

        XCTAssertEqual(router.handleReceiveMethodActionCallsCount, 1)
        XCTAssertEqual(router.handleReceiveMethodActionReceivedAction, .view(id: .canned, methodType: .accountDetails))
        XCTAssertEqual(analyticsTracker.onSelectedCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onSelectedReceivedArguments?.actionType, .View())
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
