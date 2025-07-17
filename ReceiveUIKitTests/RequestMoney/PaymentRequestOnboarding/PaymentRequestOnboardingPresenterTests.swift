import AnalyticsKitTestingSupport
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport

@MainActor
final class PaymentRequestOnboardingPresenterTests: TWTestCase {
    private var presenter: PaymentRequestOnboardingPresenterImpl!
    private var view: PaymentRequestOnboardingViewMock!
    private var paymentRequestOnboardingPreferenceUseCase: PaymentRequestOnboardingPreferenceUseCaseMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var routingDelegate: PaymentRequestOnboardingRoutingDelegateMock!

    override func setUp() {
        super.setUp()
        view = PaymentRequestOnboardingViewMock()
        paymentRequestOnboardingPreferenceUseCase = PaymentRequestOnboardingPreferenceUseCaseMock()
        analyticsTracker = StubAnalyticsTracker()
        routingDelegate = PaymentRequestOnboardingRoutingDelegateMock()
        let info = FakeBusinessProfileInfo()
        let profile = Profile.business(info)
        presenter = makePresenter(profile: profile)
    }

    override func tearDown() {
        view = nil
        paymentRequestOnboardingPreferenceUseCase = nil
        presenter = nil
        analyticsTracker = nil
        routingDelegate = nil
        super.tearDown()
    }

    func test_start_givenOnboardingIsRequired_andBusinessProfile_thenConfigureView() throws {
        paymentRequestOnboardingPreferenceUseCase.isOnboardingRequiredReturnValue = .just(true)

        let expectedSummaryViewModels: [PaymentRequestOnboardingViewModel.SummaryViewModel] = [
            .init(
                title: "Get paid by anyone, anywhere",
                description: "You say how much, what for, and by when.",
                icon: Icons.limit.image
            ),
            .init(
                title: "Share in seconds",
                description: "One link with everything someone needs to pay you.",
                icon: Icons.link.image
            ),
            .init(
                title: "Money in, job done",
                description: "Low or no fees mean you keep more of the money you make.",
                icon: Icons.requestReceive.image
            ),
        ]
        let expectedViewModel = PaymentRequestOnboardingViewModel(
            titleText: "Request a payment",
            subtitleText: "Get paid simply — set up and share a link with your customer.",
            image: Illustrations.receive.image,
            summaryViewModels: expectedSummaryViewModels,
            footerButtonAction: Action(title: "Start", handler: {})
        )

        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedInvocations.first)
        expectNoDifference(viewModel, expectedViewModel)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
    }

    func test_start_givenOnboardingIsRequired_andPersonalProfile_thenConfigureView() throws {
        let info = FakePersonalProfileInfo()
        let profile = Profile.personal(info)
        presenter = makePresenter(profile: profile)
        paymentRequestOnboardingPreferenceUseCase.isOnboardingRequiredReturnValue = .just(true)

        let expectedSummaryViewModels: [PaymentRequestOnboardingViewModel.SummaryViewModel] = [
            .init(
                title: "Get paid by anyone, anywhere",
                description: "You say how much, and what for.",
                icon: Icons.limit.image
            ),
            .init(
                title: "Share in seconds",
                description: "One link with everything someone needs to pay you.",
                icon: Icons.link.image
            ),
            .init(
                title: "Money in, move on",
                description: "Back in your balance and ready to spend.",
                icon: Icons.requestReceive.image
            ),
        ]
        let expectedViewModel = PaymentRequestOnboardingViewModel(
            titleText: "Request a payment",
            subtitleText: "Get paid back in a snap — set up and share a link with whoever owes you money.",
            image: Illustrations.receive.image,
            summaryViewModels: expectedSummaryViewModels,
            footerButtonAction: Action(title: "Start", handler: {})
        )

        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedInvocations.first)
        expectNoDifference(viewModel, expectedViewModel)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
    }

    func test_start_givenOnboardingIsNotRequired_thenMoveToNextStep() throws {
        paymentRequestOnboardingPreferenceUseCase.isOnboardingRequiredReturnValue = .just(false)

        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(routingDelegate.moveToNextStepAfterOnboardingCallsCount, 1)
        XCTAssertEqual(routingDelegate.moveToNextStepAfterOnboardingReceivedIsOnboardingRequired, false)
    }

    func test_startTapped_thenMoveToNextStep() throws {
        paymentRequestOnboardingPreferenceUseCase.isOnboardingRequiredReturnValue = .just(true)
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.footerButtonAction.handler()

        XCTAssertEqual(paymentRequestOnboardingPreferenceUseCase.setIsOnboardingRequiredCallsCount, 1)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Onboarding - Start pressed")
        let (isRequired, _) = try XCTUnwrap(paymentRequestOnboardingPreferenceUseCase.setIsOnboardingRequiredReceivedArguments)
        XCTAssertFalse(isRequired)
        XCTAssertEqual(routingDelegate.moveToNextStepAfterOnboardingCallsCount, 1)
        XCTAssertEqual(routingDelegate.moveToNextStepAfterOnboardingReceivedIsOnboardingRequired, true)
    }

    func test_dismissTapped_thenSetIsOnboardingRequired_andTrackCorrectEvent() throws {
        presenter.dismissTapped()

        XCTAssertEqual(paymentRequestOnboardingPreferenceUseCase.setIsOnboardingRequiredCallsCount, 1)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Onboarding - Exit pressed")
        XCTAssertEqual(routingDelegate.dismissCallsCount, 1)
    }

    // MARK: - Helpers

    private func makePresenter(profile: Profile) -> PaymentRequestOnboardingPresenterImpl {
        PaymentRequestOnboardingPresenterImpl(
            profile: profile,
            paymentRequestOnboardingPreferenceUseCase: paymentRequestOnboardingPreferenceUseCase,
            routingDelegate: routingDelegate,
            analyticsTracker: analyticsTracker,
            scheduler: .immediate
        )
    }
}
