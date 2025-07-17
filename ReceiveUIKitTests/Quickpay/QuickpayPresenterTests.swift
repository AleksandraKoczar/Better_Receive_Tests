@testable import Neptune
import NeptuneTestingSupport
import Prism
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TransferResources
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UserKitTestingSupport

@MainActor
final class QuickpayPresenterTests: TWTestCase {
    private let profile = FakeBusinessProfileInfo().asProfile()
    private let qrCodeImage = UIImage()
    private let qrCode = UIImage.qrCode(from: "https://wise.com/abcdefg1234")!
    private var presenter: QuickpayPresenterImpl!
    private var view: QuickpayViewMock!
    private var wisetagInteractor: WisetagInteractorMock!
    private var viewModelMapper: QuickpayViewModelMapperMock!
    private var quickpayUseCase: QuickpayUseCaseMock!
    private var analyticsTracker: BusinessProfileLinkTrackingMock!
    private var router: QuickpayRouterMock!
    private var pasteboard: MockPasteboard!
    private var featureService: StubFeatureService!

    override func setUp() {
        super.setUp()
        view = QuickpayViewMock()
        wisetagInteractor = WisetagInteractorMock()
        router = QuickpayRouterMock()
        pasteboard = MockPasteboard()
        quickpayUseCase = QuickpayUseCaseMock()
        viewModelMapper = QuickpayViewModelMapperMock()
        analyticsTracker = BusinessProfileLinkTrackingMock()
        featureService = StubFeatureService()

        presenter = QuickpayPresenterImpl(
            profile: profile,
            quickpayUseCase: quickpayUseCase,
            wisetagInteractor: wisetagInteractor,
            viewModelMapper: viewModelMapper,
            router: router,
            analyticsTracker: analyticsTracker,
            pasteboard: pasteboard,
            featureService: featureService,
            scheduler: .immediate
        )
    }

    func test_start_givenDiscoverableAndPersonalise_thenConfigureView() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just(.canned)

        let viewModel = makeQuickpayActiveViewModel()
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

        XCTAssertEqual(analyticsTracker.onLoadedCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onLoadedReceivedArguments?.success, true)
    }

    func test_start_givenShouldShowStory_thenNavigateToStory() throws {
        wisetagInteractor.fetchNextStepReturnValue = .just(.showStory)
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just(.canned)

        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(wisetagInteractor.fetchNextStepCallsCount, 1)
        XCTAssertEqual(router.showIntroStoryCallsCount, 1)
        XCTAssertEqual(viewModelMapper.makeCallsCount, 0)
    }

    func test_start_givenNotDiscoverable_thenConfigureView() throws {
        let status = ShareableLinkStatus.eligible(.notDiscoverable)

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just(.canned)

        let viewModel = makeQuickpayInactiveViewModel()
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

        XCTAssertEqual(analyticsTracker.onLoadedCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onLoadedReceivedArguments?.success, true)
        XCTAssertEqual(analyticsTracker.onLoadedReceivedArguments?.discoverable, false)
    }

    func test_start_givenNotDiscoverable_AndFooterButtonTapped_thenTurnOn() throws {
        let status = ShareableLinkStatus.eligible(.notDiscoverable)
        let status2 = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just(.canned)
        wisetagInteractor.updateShareableLinkStatusReturnValue = .just((status2, qrCodeImage))

        let viewModel = makeQuickpayInactiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)
        presenter.footerButtonTapped()

        XCTAssertEqual(view.showHudCallsCount, 2)
        XCTAssertEqual(view.hideHudCallsCount, 2)
        XCTAssertEqual(wisetagInteractor.updateShareableLinkStatusCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onActivateCallsCount, 1)
    }

    func test_start_givenDiscoverable_andQRCodeTapped_thenStartDownload() {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just(.canned)

        let viewModel = makeQuickpayActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)
        presenter.qrCodeTapped()

        XCTAssertTrue(router.startDownloadCalled)
        XCTAssertEqual(analyticsTracker.onQrCodeDownloadButtonCallsCount, 1)
    }

    func test_cardsIsEnabled_thenConfigureCorrectView() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just(.canned)

        let viewModel = makeQuickpayActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
    }

    func test_settingsButtonSelected_thenShowManageQuickpay() throws {
        presenter.showManageQuickpay()

        XCTAssertEqual(analyticsTracker.onSettingsButtonCallsCount, 1)
        XCTAssertEqual(router.showManageQuickpayCallsCount, 1)
    }

    func test_personaliseSelected_thenShowPersonaliseView() throws {
        let status = ShareableLinkStatus.eligible(.discoverable(urlString: "", nickname: ""))

        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just(.canned)

        let viewModel = makeQuickpayActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)
        presenter.personaliseTapped()

        XCTAssertEqual(analyticsTracker.onCustomLinkToggledCallsCount, 1)
        XCTAssertEqual(router.personaliseTappedCallsCount, 1)
    }
}

// MARK: - Card Onbaording Nudge

extension QuickpayPresenterTests {
    func test_onboardingNudgeShouldShow_thenMapperGetsNudge() throws {
        let status = ShareableLinkStatus.eligible(.discoverable(urlString: "", nickname: ""))

        wisetagInteractor.shouldShowNudgeReturnValue = .init(true)
        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just([PaymentMethodDynamicForm.build(
            flowId: "acquiringOnboardingConsentForm",
            url: .canned
        )])

        let viewModel = makeQuickpayActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)

        let receivedViewModel = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertTrue(receivedViewModel.nudge.isNonNil)
        XCTAssertEqual(analyticsTracker.onCardSetupNudgeViewedCallsCount, 1)
    }

    func test_onboardingNudgeShouldNotShow_thenMapperDoesNotGetNudge() throws {
        let status = ShareableLinkStatus.eligible(.discoverable(urlString: "", nickname: ""))

        wisetagInteractor.shouldShowNudgeReturnValue = .init(false)
        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just([PaymentMethodDynamicForm.build(
            flowId: "acquiringOnboardingConsentForm",
            url: .canned
        )])

        let viewModel = makeQuickpayActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)

        let receivedViewModel = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        XCTAssertTrue(receivedViewModel.nudge.isNil)
    }

    func test_onboardingNudgeSelected_thenDynamicFlowStarts() throws {
        let status = ShareableLinkStatus.eligible(.discoverable(urlString: "", nickname: ""))

        wisetagInteractor.shouldShowNudgeReturnValue = .init(true)
        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just([PaymentMethodDynamicForm.build(
            flowId: "acquiringOnboardingConsentForm",
            url: .canned
        )])

        let viewModel = makeQuickpayActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)

        let receivedModel = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        receivedModel.nudge?.onSelect()

        XCTAssertEqual(analyticsTracker.onCardSetupNudgeOpenedCallsCount, 1)
        XCTAssertTrue(router.showDynamicFormsMethodManagementCalled)
    }

    func test_onboardingNudgeDismissed_thenHideNudgeAndTrack() throws {
        let status = ShareableLinkStatus.eligible(.discoverable(urlString: "", nickname: ""))

        wisetagInteractor.shouldShowNudgeReturnValue = .init(true)
        wisetagInteractor.fetchNextStepReturnValue = .just(.showWisetag(image: qrCode, status: status, isCardsEnabled: true))
        wisetagInteractor.fetchCardDynamicFormsReturnValue = .just([PaymentMethodDynamicForm.build(
            flowId: "acquiringOnboardingConsentForm",
            url: .canned
        )])

        let viewModel = makeQuickpayActiveViewModel()
        viewModelMapper.makeReturnValue = viewModel

        presenter.start(with: view)

        let receivedModel = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        receivedModel.nudge?.onDismiss!()

        XCTAssertEqual(analyticsTracker.onCardSetupNudgeDismissCallsCount, 1)
        XCTAssertTrue(view.updateNudgeReceivedNudge.isNil)
    }
}

private extension QuickpayPresenterTests {
    private func makeQuickpayActiveViewModel() -> QuickpayViewModel {
        let cardItems = [
            QuickpayCardViewModel(
                id: 1,
                image: Neptune.Illustrations.plane.image,
                title: L10n.Quickpay.Carousel.Item1.title,
                subtitle: L10n.Quickpay.Carousel.Item1.subtitle,
                articleId: "plane"
            ),
            QuickpayCardViewModel(
                id: 2,
                image: Neptune.Illustrations.businessCard.image,
                title: L10n.Quickpay.Carousel.Item2.title,
                subtitle: L10n.Quickpay.Carousel.Item2.subtitle,
                articleId: "businessCard"
            ),
            QuickpayCardViewModel(
                id: 3,
                image: Neptune.Illustrations.shoppingBag.image,
                title: L10n.Quickpay.Carousel.Item3.title,
                subtitle: L10n.Quickpay.Carousel.Item3.subtitle,
                articleId: "shoppingBag"
            ),
        ]

        let circularButtons: [QuickpayViewModel.ButtonViewModel] = [
            QuickpayViewModel.ButtonViewModel(
                icon: Icons.shareIos.image,
                title: "Share",
                action: {}
            ),
            QuickpayViewModel.ButtonViewModel(
                icon: Icons.shareIos.image,
                title: "Personalise",
                action: {}
            ),
            QuickpayViewModel.ButtonViewModel(
                icon: Icons.shareIos.image,
                title: "Give feedback",
                action: {}
            ),
        ]

        return QuickpayViewModel(
            avatar: ._initials(.init(name: LoremIpsum.short), badge: nil),
            title: LoremIpsum.short,
            subtitle: LoremIpsum.short,
            linkType: .active(link: "active link", touchHandler: {}),
            footerAction: nil,
            nudge: .init(title: LoremIpsum.short, asset: .calendar, ctaTitle: "", onSelect: {}),
            qrCode: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeEnabled(
                qrCode: qrCode,
                enabledText: LoremIpsum.veryShort,
                enabledTextOnTap: LoremIpsum.veryShort,
                onTap: {}
            )),
            navigationBarButtons: [
                QuickpayViewModel.ButtonViewModel(
                    icon: Icons.slider.image,
                    title: "",
                    action: {}
                ),
            ],
            circularButtons: circularButtons,
            cardItems: cardItems,
            onCardTap: { _ in }
        )
    }

    private func makeQuickpayInactiveViewModel() -> QuickpayViewModel {
        let cardItems = [
            QuickpayCardViewModel(
                id: 1,
                image: Neptune.Illustrations.plane.image,
                title: L10n.Quickpay.Carousel.Item1.title,
                subtitle: L10n.Quickpay.Carousel.Item1.subtitle,
                articleId: "plane"
            ),
            QuickpayCardViewModel(
                id: 2,
                image: Neptune.Illustrations.businessCard.image,
                title: L10n.Quickpay.Carousel.Item2.title,
                subtitle: L10n.Quickpay.Carousel.Item2.subtitle,
                articleId: "businessCard"
            ),
            QuickpayCardViewModel(
                id: 3,
                image: Neptune.Illustrations.shoppingBag.image,
                title: L10n.Quickpay.Carousel.Item3.title,
                subtitle: L10n.Quickpay.Carousel.Item3.subtitle,
                articleId: "shoppingBag"
            ),
        ]

        return QuickpayViewModel(
            avatar: ._initials(.init(name: LoremIpsum.short), badge: nil),
            title: LoremIpsum.short,
            subtitle: LoremIpsum.short,
            linkType: .inactive(inactiveLink: "Inactive"),
            footerAction: nil,
            nudge: nil,
            qrCode: WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeDisabled(
                placeholderQRCode: qrCode,
                disabledText: LoremIpsum.short,
                onTap: {}
            )),
            navigationBarButtons: [
                QuickpayViewModel.ButtonViewModel(
                    icon: Icons.slider.image,
                    title: "",
                    action: {}
                ),
            ],
            circularButtons: [],
            cardItems: cardItems,
            onCardTap: { _ in }
        )
    }
}
