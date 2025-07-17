import BalanceKit
import BalanceKitTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import WiseCore

final class PixRegistrationCheckerFlowTests: TWTestCase {
    private var accountDetailsUseCase: AccountDetailsUseCaseMock!
    private var receiveMethodsAliasUseCase: ReceiveMethodsAliasUseCaseMock!
    private var receiveMethodsDFFlowFactory: ReceiveMethodsDFFlowFactoryMock!
    private var flowDispatcher: TestFlowDispatcher!
    private var hostViewController: MockNavigationController!
    private var firstViewController: ViewControllerMock!

    private var flow: (any Flow<PixRegistrationCheckerFlowResult>)!
    private var receiveMethodsDFFlow: (any Flow<ReceiveMethodsDFFlowResult>)!
    private var flowResult: PixRegistrationCheckerFlowResult?

    private let profileId = ProfileId(128)
    private let accountDetailsId = AccountDetailsId(64)

    override func setUp() {
        super.setUp()

        hostViewController = MockNavigationController()
        firstViewController = ViewControllerMock()
        hostViewController.setViewControllers([firstViewController], animated: false)
        accountDetailsUseCase = AccountDetailsUseCaseMock()
        receiveMethodsAliasUseCase = ReceiveMethodsAliasUseCaseMock()
        receiveMethodsDFFlowFactory = ReceiveMethodsDFFlowFactoryMock()
        flowDispatcher = TestFlowDispatcher()

        receiveMethodsDFFlow = MockFlow<ReceiveMethodsDFFlowResult>()

        flow = PixRegistrationCheckerFlow(
            profileId: profileId,
            hostViewController: hostViewController,
            accountDetailsUseCase: accountDetailsUseCase,
            receiveMethodsAliasUseCase: receiveMethodsAliasUseCase,
            receiveMethodsDFFlowFactory: receiveMethodsDFFlowFactory,
            flowPresenter: .test(with: flowDispatcher),
            scheduler: .immediate
        )
        flow.onFinish { [weak self] result, _ in
            self?.flowResult = result
        }
    }

    override func tearDown() {
        super.tearDown()

        flow = nil
        accountDetailsUseCase = nil
        receiveMethodsAliasUseCase = nil
        receiveMethodsDFFlowFactory = nil
        flowDispatcher = nil
        hostViewController = nil
        firstViewController = nil
        flowResult = nil
        receiveMethodsDFFlow = nil
    }
}

// MARK: - Tests

extension PixRegistrationCheckerFlowTests {
    func testPixRegistration_GivenHappyPath_ThenCorrectResultReturns() {
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(
                        ActiveAccountDetails.build(
                            id: accountDetailsId,
                            currency: .BRL,
                            isDeprecated: false
                        )
                    ),
                ]
            )
        )
        receiveMethodsAliasUseCase.aliasesReturnValue = .just(
            [ReceiveMethodAlias.build(aliasScheme: "BLA")]
        )
        receiveMethodsDFFlowFactory.makeReturnValue = receiveMethodsDFFlow
        flow.start()

        XCTAssertTrue(firstViewController.didShowHud)
        XCTAssertEqual(accountDetailsUseCase.clearDataCallsCount, 1)
        XCTAssertEqual(accountDetailsUseCase.refreshAccountDetailsCallsCount, 1)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesReceivedArguments?.profileId, profileId)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesReceivedArguments?.accountDetailsId, accountDetailsId)
        XCTAssertEqual(receiveMethodsDFFlowFactory.makeCallsCount, 1)
        XCTAssertTrue(firstViewController.didHideHud)
        XCTAssertTrue(flowDispatcher.lastFlowPresented === receiveMethodsDFFlow)

        receiveMethodsDFFlow.flowHandler.flowFinished(result: .registrationCompleted, dismisser: nil)

        XCTAssertEqual(flowResult, .finished(pixRegistered: true))
    }

    func testPixRegistration_GivenKeyRegistrationDismissed_ThenCorrectResultReturns() {
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(
                        ActiveAccountDetails.build(
                            id: accountDetailsId,
                            currency: .BRL,
                            isDeprecated: false
                        )
                    ),
                ]
            )
        )
        receiveMethodsAliasUseCase.aliasesReturnValue = .just(
            [ReceiveMethodAlias.build(aliasScheme: "BLA")]
        )
        receiveMethodsDFFlowFactory.makeReturnValue = receiveMethodsDFFlow
        flow.start()

        XCTAssertTrue(firstViewController.didShowHud)
        XCTAssertEqual(accountDetailsUseCase.clearDataCallsCount, 1)
        XCTAssertEqual(accountDetailsUseCase.refreshAccountDetailsCallsCount, 1)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesReceivedArguments?.profileId, profileId)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesReceivedArguments?.accountDetailsId, accountDetailsId)
        XCTAssertEqual(receiveMethodsDFFlowFactory.makeCallsCount, 1)
        XCTAssertTrue(firstViewController.didHideHud)

        receiveMethodsDFFlow.flowHandler.flowFinished(result: .dismissed, dismisser: nil)

        XCTAssertEqual(flowResult, .finished(pixRegistered: false))
    }

    func testPixRegistration_GivenKeyRegistrationFailed_ThenCorrectResultReturns() {
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(
                        ActiveAccountDetails.build(
                            id: accountDetailsId,
                            currency: .BRL,
                            isDeprecated: false
                        )
                    ),
                ]
            )
        )
        receiveMethodsAliasUseCase.aliasesReturnValue = .just(
            [ReceiveMethodAlias.build(aliasScheme: "BLA")]
        )
        receiveMethodsDFFlowFactory.makeReturnValue = receiveMethodsDFFlow
        flow.start()

        XCTAssertTrue(firstViewController.didShowHud)
        XCTAssertEqual(accountDetailsUseCase.clearDataCallsCount, 1)
        XCTAssertEqual(accountDetailsUseCase.refreshAccountDetailsCallsCount, 1)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesReceivedArguments?.profileId, profileId)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesReceivedArguments?.accountDetailsId, accountDetailsId)
        XCTAssertEqual(receiveMethodsDFFlowFactory.makeCallsCount, 1)
        XCTAssertTrue(firstViewController.didHideHud)

        receiveMethodsDFFlow.flowHandler.flowFinished(result: .registrationFailed, dismisser: nil)

        XCTAssertEqual(flowResult, .finished(pixRegistered: false))
    }

    func testPixRegistration_GivenNoBRLDetails_ThenCorrectResultReturns() {
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(
                        ActiveAccountDetails.build(
                            id: accountDetailsId,
                            currency: .GBP,
                            isDeprecated: false
                        )
                    ),
                ]
            )
        )
        flow.start()

        XCTAssertTrue(firstViewController.didShowHud)
        XCTAssertEqual(accountDetailsUseCase.clearDataCallsCount, 1)
        XCTAssertEqual(accountDetailsUseCase.refreshAccountDetailsCallsCount, 1)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesCallsCount, 0)
        XCTAssertEqual(receiveMethodsDFFlowFactory.makeCallsCount, 0)
        XCTAssertTrue(firstViewController.didHideHud)

        XCTAssertEqual(flowResult, .finished(pixRegistered: false))
    }

    func testPixRegistration_GivenDeprecatedBRLDetails_ThenCorrectResultReturns() {
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(
                        ActiveAccountDetails.build(
                            id: accountDetailsId,
                            currency: .BRL,
                            isDeprecated: true
                        )
                    ),
                ]
            )
        )
        flow.start()

        XCTAssertTrue(firstViewController.didShowHud)
        XCTAssertEqual(accountDetailsUseCase.clearDataCallsCount, 1)
        XCTAssertEqual(accountDetailsUseCase.refreshAccountDetailsCallsCount, 1)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesCallsCount, 0)
        XCTAssertEqual(receiveMethodsDFFlowFactory.makeCallsCount, 0)
        XCTAssertTrue(firstViewController.didHideHud)

        XCTAssertEqual(flowResult, .finished(pixRegistered: false))
    }

    func testPixRegistration_GivenPixAlias_ThenCorrectResultReturns() {
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(
                        ActiveAccountDetails.build(
                            id: accountDetailsId,
                            currency: .BRL,
                            isDeprecated: false
                        )
                    ),
                ]
            )
        )
        receiveMethodsAliasUseCase.aliasesReturnValue = .just(
            [ReceiveMethodAlias.build(aliasScheme: "PIX")]
        )
        flow.start()

        XCTAssertTrue(firstViewController.didShowHud)
        XCTAssertEqual(accountDetailsUseCase.clearDataCallsCount, 1)
        XCTAssertEqual(accountDetailsUseCase.refreshAccountDetailsCallsCount, 1)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesCallsCount, 1)
        XCTAssertEqual(receiveMethodsDFFlowFactory.makeCallsCount, 0)
        XCTAssertTrue(firstViewController.didHideHud)

        XCTAssertEqual(flowResult, .finished(pixRegistered: false))
    }

    func testPixRegistration_GivenPixAliasFetchingFailure_ThenCorrectResultReturns() {
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(
                        ActiveAccountDetails.build(
                            id: accountDetailsId,
                            currency: .BRL,
                            isDeprecated: false
                        )
                    ),
                ]
            )
        )
        receiveMethodsAliasUseCase.aliasesReturnValue = .fail(with: MockError.dummy)
        flow.start()

        XCTAssertTrue(firstViewController.didShowHud)
        XCTAssertEqual(accountDetailsUseCase.clearDataCallsCount, 1)
        XCTAssertEqual(accountDetailsUseCase.refreshAccountDetailsCallsCount, 1)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesCallsCount, 1)
        XCTAssertEqual(receiveMethodsDFFlowFactory.makeCallsCount, 0)
        XCTAssertTrue(firstViewController.didHideHud)

        XCTAssertEqual(flowResult, .finished(pixRegistered: false))
    }

    func testPixRegistration_GivenAccountDetailsFetchingFailure_ThenCorrectResultReturns() {
        accountDetailsUseCase.accountDetails = .just(.recoverableError(MockError.dummy))
        flow.start()

        XCTAssertTrue(firstViewController.didShowHud)
        XCTAssertEqual(accountDetailsUseCase.clearDataCallsCount, 1)
        XCTAssertEqual(accountDetailsUseCase.refreshAccountDetailsCallsCount, 1)
        XCTAssertEqual(receiveMethodsAliasUseCase.aliasesCallsCount, 0)
        XCTAssertEqual(receiveMethodsDFFlowFactory.makeCallsCount, 0)
        XCTAssertTrue(firstViewController.didHideHud)

        XCTAssertEqual(flowResult, .finished(pixRegistered: false))
    }
}
