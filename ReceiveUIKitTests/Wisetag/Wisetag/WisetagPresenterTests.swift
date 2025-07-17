import AnalyticsKitTestingSupport
import BalanceKit
import DeepLinkKitTestingSupport
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

final class WisetagPresenterTests: TWTestCase {
    private let profile = FakePersonalProfileInfo().asProfile()
    private let qrCodeImage = UIImage()
    private let qrCode = UIImage.qrCode(from: "https://wise.com/abcdefg1234")!
    private var presenter: WisetagPresenterImpl!
    private var view: WisetagViewMock!
    private var wisetagInteractor: WisetagInteractorMock!
    private var viewModelMapper: WisetagViewModelMapperMock!
    private var router: WisetagRouterMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var pasteboard: MockPasteboard!

    override func setUp() {
        super.setUp()
        view = WisetagViewMock()
        wisetagInteractor = WisetagInteractorMock()
        viewModelMapper = WisetagViewModelMapperMock()
        router = WisetagRouterMock()
        analyticsTracker = StubAnalyticsTracker()
        pasteboard = MockPasteboard()
        presenter = makePresenter(shouldBecomeDiscoverable: false)
    }

    override func tearDown() {
        presenter = nil
        view = nil
        wisetagInteractor = nil
        viewModelMapper = nil
        router = nil
        analyticsTracker = nil
        pasteboard = nil
        super.tearDown()
    }

    func test_start_GivenNoAccountDetailsActive_ThenStartADFlow() {
        wisetagInteractor.fetchNextStepReturnValue = .just(.showADFlow)

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)
        router.startAccountDetailsFlow(host: UIViewControllerMock())

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(router.startAccountDetailsFlowCallsCount, 1)
    }

    func test_start_givenFetchShareableLinkStatusSuccess_andScanBarButtonIsEnabled_thenConfigureView() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(wisetagInteractor.fetchNextStepCallsCount, 1)

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertEqual(arguments.qrCodeImage, qrCode)
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Profile Link - Loaded")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Success"] as? Bool, true)
    }

    func test_start_givenFetchShareableLinkStatusSuccessWithDiscoverable_andBecomeDiscoverable_thenConfigureView() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter = makePresenter(shouldBecomeDiscoverable: true)
        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(wisetagInteractor.fetchNextStepCallsCount, 1)
        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertEqual(arguments.qrCodeImage, qrCode)
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Profile Link - Loaded")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Success"] as? Bool, true)
    }

    func test_start_givenFetchShareableLinkStatusSuccessWithNotDiscoverable_andBecomeDiscoverable_thenConfigureView() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter = makePresenter(shouldBecomeDiscoverable: true)
        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(wisetagInteractor.fetchNextStepCallsCount, 1)

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertEqual(arguments.qrCodeImage, qrCode)
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Profile Link - Loaded")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Success"] as? Bool, true)
    }

    func test_start_givenFetchShareableLinkStatusSuccessWithIneligible_thenShowError() throws {
        wisetagInteractor.fetchNextStepReturnValue = .fail(with: WisetagError.loadingError(error: WisetagError.ineligible))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter = makePresenter(shouldBecomeDiscoverable: true)
        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(wisetagInteractor.fetchNextStepCallsCount, 1)
        XCTAssertEqual(view.configureWithErrorCallsCount, 1)

        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Profile Link - Loaded")?.last)
        let properties = event.eventProperties()

        let eventProperties: [String: Any] = try XCTUnwrap(
            analyticsTracker.trackedMixpanelEvents("Profile Link - Wisetag Failed"
            )?.last).eventProperties()

        XCTAssertEqual(
            eventProperties["Type"] as? String,
            "Wisetag Loading Failed"
        )

        XCTAssertEqual(
            eventProperties["Identifier"] as? String,
            "loadingError"
        )

        XCTAssertEqual(properties["Success"] as? Bool, false)
    }

    func test_start_givenFetchShareableLinkStatusSuccess_andScanBarButtonIsDisabled_thenConfigureView() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(wisetagInteractor.fetchNextStepCallsCount, 1)
        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertEqual(arguments.qrCodeImage, qrCode)
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Profile Link - Loaded")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Success"] as? Bool, true)
    }

    func test_start_givenFetchShareableLinkStatusSuccess_butFetchQRcodeFails_thenConfigureView() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: nil, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(wisetagInteractor.fetchNextStepCallsCount, 1)

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertNil(arguments.qrCodeImage)
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Profile Link - Loaded")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Success"] as? Bool, true)
    }

    func test_start_givenFetchShareableLinkStatusFails_thenShowError() throws {
        wisetagInteractor.fetchNextStepReturnValue = .fail(with: WisetagError.loadingError(error: MockError.dummy))

        presenter.start(with: view)

        XCTAssertEqual(wisetagInteractor.fetchNextStepCallsCount, 1)

        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Profile Link - Loaded")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Success"] as? Bool, false)

        let eventProperties: [String: Any] = try XCTUnwrap(
            analyticsTracker.trackedMixpanelEvents("Profile Link - Wisetag Failed"
            )?.last).eventProperties()

        XCTAssertEqual(
            eventProperties["Type"] as? String,
            "Wisetag Loading Failed"
        )

        XCTAssertEqual(
            eventProperties["Identifier"] as? String,
            "loadingError"
        )
        XCTAssertEqual(view.configureWithErrorCallsCount, 1)
    }

    func test_start_GivenPersonalProfile_And_NotDiscoverable_AndShouldShowStory_ThenShowStory() {
        wisetagInteractor.fetchNextStepReturnValue = .just(.showStory)

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)

        XCTAssertEqual(router.showStoryCallsCount, 1)
    }

    func test_start_GivenPersonalProfile_And_NotDiscoverable_AndShouldNotShowStory_ThenShowWisetag() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagInactiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertEqual(arguments.qrCodeImage, qrCode)
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        XCTAssertEqual(router.showStoryCallsCount, 0)
    }

    func test_start_GivenPersonalProfile_And_Discoverable_ThenNotShowStory() {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)

        XCTAssertEqual(router.showStoryCallsCount, 0)
    }

    func test_shareLinkTapped() {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)

        let urlString = LoremIpsum.medium
        presenter.shareLinkTapped(urlString)

        XCTAssertEqual(view.showShareSheetCallsCount, 1)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Profile Link - Share started"
        )
    }

    func test_downloadTapped() {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)
        presenter.downloadTapped()
        XCTAssertEqual(router.showDownloadCallsCount, 1)
    }

    func test_downloadTapped_AndSavingImageFails() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: nil, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)
        presenter.downloadTapped()

        let eventProperties: [String: Any] = try XCTUnwrap(
            analyticsTracker.trackedMixpanelEvents("Profile Link - Wisetag Failed")?.last).eventProperties()

        XCTAssertEqual(
            eventProperties["Type"] as? String,
            "Wisetag Download Image Failed"
        )

        XCTAssertEqual(
            eventProperties["Identifier"] as? String,
            "downloadWisetagImageError"
        )

        XCTAssertEqual(router.showDownloadCallsCount, 0)
    }

    func test_footerButtonTapped_givenUpdateShareableLinkStatusSucceeds_andScanBarButtonIsEnabled_thenConfigureView() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        let status2 = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        wisetagInteractor.updateShareableLinkStatusReturnValue = .just((status2, qrCodeImage))

        let viewModel = makeWisetagInactiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)

        presenter.footerButtonTapped()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(wisetagInteractor.fetchNextStepCallsCount, 1)
        XCTAssertEqual(wisetagInteractor.updateShareableLinkStatusCallsCount, 1)
        XCTAssertEqual(viewModelMapper.makeCallsCount, 2)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertEqual(arguments.qrCodeImage, qrCodeImage)
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Profile Link - Activate started"
        )
    }

    func test_footerButtonTapped_givenUpdateShareableLinkStatusFails_thenShowError() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        wisetagInteractor.updateShareableLinkStatusReturnValue = .fail(with: WisetagError.updateSharableLinkError(error: GenericError("")))

        let viewModel = makeWisetagInactiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)

        presenter.footerButtonTapped()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(view.configureWithErrorCallsCount, 1)
        XCTAssertEqual(wisetagInteractor.updateShareableLinkStatusCallsCount, 1)

        XCTAssertEqual(
            analyticsTracker.trackedMixpanelEventNames,
            ["Profile Link - Loaded", "Profile Link - Activate started", "Profile Link - Wisetag Failed"]
        )

        let eventProperties: [String: Any] = try XCTUnwrap(
            analyticsTracker.trackedMixpanelEvents("Profile Link - Wisetag Failed")?.last).eventProperties()

        XCTAssertEqual(
            eventProperties["Type"] as? String,
            "Wisetag Update Sharable Link Failed"
        )

        XCTAssertEqual(
            eventProperties["Identifier"] as? String,
            "updateSharableLinkError"
        )
    }

    func test_contactOnWiseTapped() {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )
        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)

        presenter.showDiscoverabilityBottomSheet()

        XCTAssertEqual(router.showContactOnWiseCallsCount, 1)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Profile Link - Settings opened"
        )
    }

    func test_scanQRCodeTapped() {
        presenter.scanQRcodeTapped()

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Profile Link - Scan opened"
        )
    }

    func test_updateShareableLinkStatusFromInactiveToActive_givenUpdateShareableLinkStatusSucceeds_thenConfigureView() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let status2 = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.updateShareableLinkStatusReturnValue = .just((status2, qrCodeImage))

        let activeViewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = activeViewModel

        presenter.start(with: view)
        presenter.updateShareableLinkStatus(isDiscoverable: true)

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, activeViewModel)
        XCTAssertEqual(wisetagInteractor.updateShareableLinkStatusCallsCount, 1)
        let isDiscoverable = try XCTUnwrap(wisetagInteractor.updateShareableLinkStatusReceivedArguments?.isDiscoverable)
        XCTAssertTrue(isDiscoverable)
        XCTAssertEqual(viewModelMapper.makeCallsCount, 2)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertEqual(arguments.qrCodeImage, qrCodeImage)
    }

    func test_dismiss_givenShareableLinkStatusIsDiscoverable_thenDimiss() throws {
        presenter.dismiss()

        XCTAssertEqual(router.dismissCallsCount, 1)
        let isDiscoverable = try XCTUnwrap(router.dismissReceivedIsShareableLinkDiscoverable)
        XCTAssertFalse(isDiscoverable)
    }

    func test_dismiss_givenShareableLinkStatusIsNotDiscoverable_thenDismiss() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))

        let viewModel = makeWisetagActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel
        presenter.start(with: view)

        presenter.dismiss()

        XCTAssertEqual(router.dismissCallsCount, 1)
        let isDiscoverable = try XCTUnwrap(router.dismissReceivedIsShareableLinkDiscoverable)
        XCTAssertTrue(isDiscoverable)
    }
}

// MARK: - Helpers

private extension WisetagPresenterTests {
    func makePresenter(
        shouldBecomeDiscoverable: Bool,
        profile: Profile = FakePersonalProfileInfo().asProfile()
    ) -> WisetagPresenterImpl {
        WisetagPresenterImpl(
            shouldBecomeDiscoverable: shouldBecomeDiscoverable,
            profile: profile,
            interactor: wisetagInteractor,
            viewModelMapper: viewModelMapper,
            router: router,
            analyticsTracker: analyticsTracker,
            pasteboard: pasteboard,
            scheduler: .immediate
        )
    }

    private func makeWisetagInactiveViewModel() -> WisetagViewModel {
        WisetagViewModel(
            header: WisetagHeaderViewModel(
                avatar: AvatarViewModel.initials(Initials(name: "Harry Potter")),
                title: LoremIpsum.veryShort,
                linkType: .inactive(inactiveLink: LoremIpsum.medium)
            ),
            qrCode: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeDisabled(
                placeholderQRCode: qrCode,
                disabledText: LoremIpsum.medium,
                onTap: {}
            )),
            shareButtons: [
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.link.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.shareIos.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.download.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
            ],
            footerAction: nil,
            navigationBarButtons: [
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.slider.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.scanQrCode.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
            ]
        )
    }

    private func makeWisetagActiveViewModel() -> WisetagViewModel {
        WisetagViewModel(
            header: WisetagHeaderViewModel(
                avatar: AvatarViewModel.initials(Initials(name: "Harry Potter")),
                title: LoremIpsum.veryShort,
                linkType: .active(link: LoremIpsum.veryShort, touchHandler: {})
            ),
            qrCode: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeEnabled(
                qrCode: qrCode,
                enabledText: LoremIpsum.veryShort,
                enabledTextOnTap: LoremIpsum.veryShort,
                onTap: {}
            )),
            shareButtons: [
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.link.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.shareIos.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.download.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
            ],
            footerAction: nil,
            navigationBarButtons: [
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.slider.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
                WisetagViewModel.ButtonViewModel(
                    icon: Icons.scanQrCode.image,
                    title: LoremIpsum.veryShort,
                    action: {}
                ),
            ]
        )
    }
}
