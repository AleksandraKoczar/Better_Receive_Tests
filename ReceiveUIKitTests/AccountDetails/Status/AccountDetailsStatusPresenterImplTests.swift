import Combine
import Foundation
import Neptune
import NeptuneTestingSupport
import ReceiveKit
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWTestingSupportKit
import WiseCore

final class AccountDetailsStatusPresenterImplTests: TWTestCase {
    private var routingDelegate: AccountDetailsActionsListDelegateMock!
    private var router: AccountDetailsStatusRouterMock!
    private var interactor: AccountDetailsStatusInteractorMock!
    private var presenter: AccountDetailsStatusPresenterImpl!

    private let profileId = ProfileId(64)

    override func setUpWithError() throws {
        try super.setUpWithError()
        routingDelegate = AccountDetailsActionsListDelegateMock()
        router = AccountDetailsStatusRouterMock()
        interactor = AccountDetailsStatusInteractorMock()
        interactor.statusReturnValue = .just(.build())
        presenter = AccountDetailsStatusPresenterImpl(
            profileId: profileId,
            currencyCode: .GBP,
            routingDelegate: routingDelegate,
            router: router,
            interactor: interactor,
            scheduler: .immediate
        )
    }

    override func tearDownWithError() throws {
        router = nil
        interactor = nil
        presenter = nil
        router = nil
        routingDelegate = nil

        try super.tearDownWithError()
    }

    func testConfigureView_whenStatusResponseIsSuccess_thenConfiguresViewWithHudAndSuccessState() {
        let view = AccountDetailsStatusViewMock()
        presenter.configure(view: view)
        XCTAssertEqual(
            view.configureReceivedInvocations,
            [
                .loading,
                .loaded(.build()),
            ]
        )
    }

    func testConfigureView_whenStatusResponseIsError_thenConfiguresViewWithHudAndFailureState() {
        interactor.statusReturnValue = .fail(with: NSError.canned)
        let view = AccountDetailsStatusViewMock()
        presenter.configure(view: view)
        XCTAssertEqual(
            view.configureReceivedInvocations,
            [
                .loading,
                .failedToLoad(ErrorViewModel.canned),
            ]
        )
    }

    func testShowInfo_whenInvoked_thenCallsRouter() {
        let info = AccountDetailsStatus.Section.Summary.Info.build()
        presenter.infoSelected(info: info)
        XCTAssertEqual(
            router.routeReceivedAction,
            .showInfo(AccountDetailsStatusRouterAction.Info(
                title: info.title,
                content: info.content
            ))
        )
    }

    func testDismissSelected_whenInvoked_thenCallsRouter() {
        presenter.dismissSelected()
        XCTAssertTrue(routingDelegate.dismissCalled)
    }

    func testButtonSelected_whenActionProceed_thenCallsRouter() {
        presenter.buttonSelected(action: .proceed)
        XCTAssertTrue(routingDelegate.nextStepCalled)
    }
}
