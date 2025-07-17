import AnalyticsKitTestingSupport
import Neptune
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

final class RequestFromAnyonePresenterTests: TWTestCase {
    private let profile = FakePersonalProfileInfo().asProfile()
    private let qrCode = UIImage.qrCode(from: "https://wise.com/abcdefg1234")!
    private let qrCodeImage = UIImage()
    private var presenter: RequestFromAnyonePresenterImpl!
    private var view: RequestPaymentFromAnyoneViewMock!
    private var wisetagUseCase: WisetagUseCaseMock!
    private var routingDelegate: RequestFromAnyoneRoutingDelegateMock!
    private var pasteboard: MockPasteboard!
    private var analyticsTracker: StubAnalyticsTracker!

    override func setUp() {
        super.setUp()
        view = RequestPaymentFromAnyoneViewMock()
        wisetagUseCase = WisetagUseCaseMock()
        routingDelegate = RequestFromAnyoneRoutingDelegateMock()
        pasteboard = MockPasteboard()
        analyticsTracker = StubAnalyticsTracker()
        presenter = RequestFromAnyonePresenterImpl(
            wisetagUseCase: wisetagUseCase,
            routingDelegate: routingDelegate,
            profile: profile,
            pasteboard: pasteboard,
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
        wisetagUseCase = nil
        routingDelegate = nil
        pasteboard = nil
        super.tearDown()
    }

    func test_start_GivenEligibleAndDiscoverableWisetag_thenConfigureCorrectView() throws {
        wisetagUseCase.shareableLinkStatusReturnValue = .just(.eligible(.discoverable(urlString: "string", nickname: "nickname")))
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)
        presenter.start(with: view)

        // let viewModel = makeWisetagActiveViewModel()
        // let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        // expectNoDifference(receivedViewModel, viewModel)
        XCTAssertEqual(wisetagUseCase.shareableLinkStatusCallsCount, 1)
        XCTAssertEqual(wisetagUseCase.qrCodeCallsCount, 1)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)

        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share Profile Link - Started")
    }

    func test_start_GivenEligibleAndNotDiscoverableWisetag_thenConfigureCorrectView() throws {
        wisetagUseCase.shareableLinkStatusReturnValue = .just(.eligible(.notDiscoverable))
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)
        presenter.start(with: view)

        // let viewModel = makeWisetagInactiveViewModel()
        // let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        // expectNoDifference(receivedViewModel, viewModel)
        XCTAssertEqual(wisetagUseCase.shareableLinkStatusCallsCount, 1)
        XCTAssertEqual(wisetagUseCase.qrCodeCallsCount, 1)
        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)

        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share Profile Link - Started")
    }

    func test_start_givenIneligible_thenUseOldFlow() {
        wisetagUseCase.shareableLinkStatusReturnValue = .just(.ineligible)

        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(routingDelegate.useOldFlowCallsCount, 1)
    }

    func test_shareTapped() throws {
        wisetagUseCase.shareableLinkStatusReturnValue = .just(.canned)
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)
        presenter.start(with: view)

        let urlString = LoremIpsum.medium
        presenter.shareTapped(urlString)
        XCTAssertEqual(view.showShareSheetCallsCount, 1)

        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share Profile Link - Share clicked")
    }

    func test_addAmountTapped() throws {
        wisetagUseCase.shareableLinkStatusReturnValue = .just(.canned)
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)
        presenter.start(with: view)

        presenter.addAmmountAndNoteTapped()
        XCTAssertEqual(routingDelegate.addAmountAndNoteCallsCount, 1)

        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share Profile Link - Create step click")
    }

    func test_doneButtonTapped() throws {
        wisetagUseCase.shareableLinkStatusReturnValue = .just(.canned)
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)
        presenter.start(with: view)

        presenter.handleDoneAction()

        XCTAssertEqual(routingDelegate.endFlowCallsCount, 1)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share Profile Link - Finished")
        let propertyName = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["Result"] as? String)
        XCTAssertEqual(propertyName, "Dismissed")
    }

    func test_turnOnWisetagTapped_thenUpdateSharableLinkStatus() throws {
        wisetagUseCase.updateShareableLinkStatusReturnValue = .just(.canned)
        wisetagUseCase.shareableLinkStatusReturnValue = .just(.canned)
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)
        presenter.start(with: view)

        presenter.turnOnWisetagTapped()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(wisetagUseCase.updateShareableLinkStatusCallsCount, 1)
        let isDiscoverable = try XCTUnwrap(wisetagUseCase.updateShareableLinkStatusReceivedArguments?.isDiscoverable)
        XCTAssertTrue(isDiscoverable)
        XCTAssertEqual(wisetagUseCase.qrCodeCallsCount, 2)

        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share Profile Link - Activate")
    }

    func test_FinishedSharing_ResultSuccessThenLogCorrectEvent() throws {
        wisetagUseCase.updateShareableLinkStatusReturnValue = .just(.canned)
        wisetagUseCase.shareableLinkStatusReturnValue = .just(.canned)
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)
        presenter.start(with: view)

        presenter.finishSharing(didShareWisetag: true)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share Profile Link - Finished")
        let propertyName = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["Result"] as? String)
        XCTAssertEqual(propertyName, "Success")
    }

    func test_FinishedSharing_ResultDismissedThenLogCorrectEvent() throws {
        wisetagUseCase.updateShareableLinkStatusReturnValue = .just(.canned)
        wisetagUseCase.shareableLinkStatusReturnValue = .just(.canned)
        wisetagUseCase.qrCodeReturnValue = .just(qrCodeImage)
        presenter.start(with: view)

        presenter.finishSharing(didShareWisetag: true)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share Profile Link - Finished")
        let propertyName = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["Result"] as? String)
        XCTAssertEqual(propertyName, "Success")
    }
}

// MARK: - Helpers

private extension RequestFromAnyonePresenterTests {
    func makeWisetagActiveViewModel() -> RequestPaymentFromAnyoneViewModel {
        let qrCodeViewModel = WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeEnabled(
            qrCode: qrCode,
            enabledText: LoremIpsum.veryShort,
            enabledTextOnTap: LoremIpsum.veryShort,
            onTap: {}
        ))

        let primaryAction = Action(
            title: "Share",
            handler: {}
        )

        let secondaryAction = Action(
            title: "Add amount and note",
            handler: {}
        )

        return RequestPaymentFromAnyoneViewModel(
            titleViewModel: .init(
                title: "Request payment from anyone",
                description: "Share a payment link and QR code to get paid by anyone."
            ),
            qrCodeViewModel: qrCodeViewModel,
            doneAction: SmallButtonView(viewModel: .init(title: "Done", handler: {})),
            primaryActionFooter: primaryAction,
            secondaryActionFooter: secondaryAction
        )
    }

    func makeWisetagInactiveViewModel() -> RequestPaymentFromAnyoneViewModel {
        let qrCodeViewModel = WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeDisabled(
            placeholderQRCode: qrCode,
            disabledText: "Wisetag inactive",
            onTap: {}
        ))

        let primaryAction = Action(
            title: "Turn on and share",
            handler: {}
        )

        let secondaryAction = Action(
            title: "Add amount and note",
            handler: {}
        )

        let actionButton = SmallButtonView(viewModel: .init(title: "Done", handler: {}))

        return RequestPaymentFromAnyoneViewModel(
            titleViewModel: .init(
                title: "Request payment from anyone",
                description: "Share a payment link and QR code to get paid by anyone."
            ),
            qrCodeViewModel: qrCodeViewModel,
            doneAction: actionButton,
            primaryActionFooter: primaryAction,
            secondaryActionFooter: secondaryAction
        )
    }
}
