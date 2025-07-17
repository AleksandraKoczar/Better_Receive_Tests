import BalanceKit
import Combine
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport
import XCTest

final class LoadAccountDetailsEligibilityPresenterTests: TWTestCase {
    private var presenter: LoadAccountDetailsEligibilityPresenter!
    private let profile = FakeBusinessProfileInfo().asProfile()
    private var view: DataLoadingViewMock!
    private var interactor: LoadAccountDetailsEligibilityInteractorMock!
    private var requirementsPublisher: PassthroughSubject<MultipleAccountDetailsEligibility, Error>!
    private var action: LoadAccountDetailsEligibilityRouterAction?

    override func setUp() {
        super.setUp()
        view = DataLoadingViewMock()
        interactor = LoadAccountDetailsEligibilityInteractorMock()
        requirementsPublisher = .init()
        interactor.eligibilityReturnValue = requirementsPublisher.eraseToAnyPublisher()
        presenter = LoadAccountDetailsEligibilityPresenter(
            profile: profile,
            router: self,
            interactor: interactor,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        view = nil
        interactor = nil
        requirementsPublisher = nil
        presenter = nil
        super.tearDown()
    }

    @MainActor
    func testConfigure_whenCallsInteractor_thenConfiguresViewWithLoadingState() {
        presenter.configure(view: view)
        XCTAssertEqual(view.configureReceivedInvocations.first, .loading)
    }

    @MainActor
    func testConfigure_whenEligibilityLoaded_thenConfiguresViewWithLoadedState() {
        presenter.configure(view: view)
        requirementsPublisher.send(.eligible(requirements: [.build()]))
        XCTAssertEqual(view.configureReceivedInvocations.last, .loaded)
    }

    @MainActor
    func testConfigure_whenEligible_thenRoutesWithEligibleAction() {
        let requirements = [AccountDetailsRequirement.build()]
        presenter.configure(view: view)
        requirementsPublisher.send(.eligible(requirements: requirements))
        XCTAssertEqual(
            action,
            .loaded(.eligible(.init(profile: profile, requirements: requirements)))
        )
    }

    @MainActor
    func testConfigure_whenIneligible_thenRoutesWithIneligibleAction() {
        presenter.configure(view: view)
        requirementsPublisher.send(.ineligible)
        XCTAssertEqual(
            action,
            .loaded(.ineligible(profile))
        )
    }

    @MainActor
    func testDismissSelected_whenViewDismissed_thenRoutesWithDismissedAction() {
        presenter.dismissSelected()
        XCTAssertEqual(action, .dismissed)
    }
}

extension LoadAccountDetailsEligibilityPresenterTests: LoadAccountDetailsEligibilityRouter {
    func route(action: LoadAccountDetailsEligibilityRouterAction) {
        self.action = action
    }
}

extension LoadAccountDetailsEligibilityRouterAction: @retroactive Equatable {
    public static func == (
        lhs: LoadAccountDetailsEligibilityRouterAction,
        rhs: LoadAccountDetailsEligibilityRouterAction
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.loaded(lhsResult), .loaded(rhsResult)):
            switch (lhsResult, rhsResult) {
            case let (.eligible(lhsInfo), .eligible(rhsInfo)):
                lhsInfo.profile.id == rhsInfo.profile.id
                    && lhsInfo.requirements == rhsInfo.requirements
            case let (.ineligible(lhsProfile), .ineligible(rhsProfile)):
                lhsProfile.id == rhsProfile.id
            default:
                false
            }
        case (.dismissed, .dismissed):
            true
        default:
            false
        }
    }
}
