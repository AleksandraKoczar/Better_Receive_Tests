import BalanceKit
import Combine
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport
import XCTest

final class LoadAccountDetailsStatusPresenterTests: TWTestCase {
    private let profile = FakeBusinessProfileInfo().asProfile()
    private var presenter: LoadAccountDetailsStatusPresenter!
    private var view: DataLoadingViewMock!
    private var interactor: LoadAccountDetailsStatusInteractorMock!
    private var accountDetailsPublisher: CurrentValueSubject<[AccountDetails], Error>!
    private var action: LoadAccountDetailsStatusRouterAction?

    override func setUp() {
        super.setUp()
        view = DataLoadingViewMock()
        accountDetailsPublisher = .init([])
        interactor = LoadAccountDetailsStatusInteractorMock()
        interactor.accountDetails = accountDetailsPublisher.eraseToAnyPublisher()
        presenter = LoadAccountDetailsStatusPresenter(
            profile: profile,
            router: self,
            interactor: interactor,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        accountDetailsPublisher = nil
        action = nil
        view = nil
        interactor = nil
        presenter = nil
        super.tearDown()
    }

    @MainActor
    func testConfigure_whenCallsInteractor_thenConfiguresViewWithLoadingState() {
        presenter.configure(view: view)
        XCTAssertEqual(view.configureReceivedInvocations.first, .loading)
    }

    @MainActor
    func testConfigure_whenAccountDetailsLoaded_thenConfiguresViewWithLoadedState() {
        accountDetailsPublisher.send([.active(.build())])
        presenter.configure(view: view)
        XCTAssertEqual(view.configureReceivedInvocations.last, .loaded)
    }

    @MainActor
    func testConfigure_whenAvailableAccountDetailsLoaded_thenRoutesWithLoadedAction() {
        accountDetailsPublisher.send([.available(.build())])
        presenter.configure(view: view)
        XCTAssertEqual(
            action,
            .loaded(.init(profile: profile, status: .inactive))
        )
    }

    @MainActor
    func testConfigure_whenActiveAccountDetailsLoaded_thenRoutesWithLoadedAction() {
        accountDetailsPublisher.send([.active(.build())])
        presenter.configure(view: view)
        XCTAssertEqual(
            action,
            .loaded(.init(profile: profile, status: .active))
        )
    }

    @MainActor
    func testDismissSelected_whenViewDismissed_thenRoutesWithDismissedAction() {
        presenter.dismissSelected()
        XCTAssertEqual(action, .dismissed)
    }

    @MainActor
    func testConfigure_whenAccountDetailsLoadingFailed_thenConfiguresViewWithErrorState() {
        accountDetailsPublisher.send(completion: .failure(NSError.canned))
        presenter.configure(view: view)
        XCTAssertEqual(view.configureReceivedInvocations.last, .error)
    }
}

extension LoadAccountDetailsStatusPresenterTests: LoadAccountDetailsStatusRouter {
    func route(action: LoadAccountDetailsStatusRouterAction) {
        self.action = action
    }
}

extension LoadAccountDetailsStatusRouterAction: @retroactive Equatable {
    public static func == (lhs: LoadAccountDetailsStatusRouterAction, rhs: LoadAccountDetailsStatusRouterAction) -> Bool {
        switch (lhs, rhs) {
        case let (.loaded(lhsInfo), .loaded(rhsInfo)):
            lhsInfo.profile.id == rhsInfo.profile.id
                && lhsInfo.status == rhsInfo.status
        case (.dismissed, .dismissed):
            true
        default:
            false
        }
    }
}
