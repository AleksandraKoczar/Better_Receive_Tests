import AnalyticsKit
import AnalyticsKitTestingSupport
import ApiKit
@testable import BalanceKit
import BalanceKitTestingSupport
import Combine
import Foundation
@testable import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import UserKit
import UserKitTestingSupport
import WiseCore

@MainActor
final class AccountDetailsV2PresenterTests: TWTestCase {
    private var view: AccountDetailsInfoV2ViewMock!
    private var presenter: AccountDetailsV2PresenterImpl!
    private var router: AccountDetailsInfoRouterMock!
    private var usecase: AccountDetailsUseCaseMock!
    private var payerPDFUseCase: AccountDetailsPayerPDFUseCaseMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var analyticsProvider: MockAccountDetailsAnalyticsProvider!
    private var profile: Profile!
    private var pasteboard: MockPasteboard!
    private var notificationCenter: MockNotificationCenter!

    private let uriString = "https://abc.com"

    override func setUp() {
        super.setUp()

        router = AccountDetailsInfoRouterMock()
        usecase = AccountDetailsUseCaseMock()
        payerPDFUseCase = AccountDetailsPayerPDFUseCaseMock()
        analyticsTracker = StubAnalyticsTracker()
        analyticsProvider = MockAccountDetailsAnalyticsProvider()
        profile = .personal(FakePersonalProfileInfo())
        view = AccountDetailsInfoV2ViewMock()
        view.documentInteractionControllerDelegate = MockViewController()
        pasteboard = MockPasteboard()
        notificationCenter = MockNotificationCenter()

        presenter = AccountDetailsV2PresenterImpl(
            router: router,
            accountDetailsUseCase: usecase,
            payerPDFUseCase: payerPDFUseCase,
            profile: profile,
            accountDetailsId: AccountDetailsId(128),
            accountDetailsType: .standard,
            pasteboard: pasteboard,
            activeAccountDetails: nil,
            invocationSource: .balanceHeaderAction,
            analyticsTracker: analyticsTracker,
            analyticsProvider: analyticsProvider,
            notificationCenter: notificationCenter,
            scheduler: .immediate
        )
    }

    override func tearDown() {
        router = nil
        usecase = nil
        analyticsProvider = nil
        profile = nil
        view = nil
        pasteboard = nil
        presenter = nil
        payerPDFUseCase = nil
        notificationCenter = nil

        super.tearDown()
    }

    func test_initialSetup_withAccountDetails() {
        // Doesn't need to load from the API, because they are already passed in
        presenter = AccountDetailsV2PresenterImpl(
            router: router,
            accountDetailsUseCase: usecase,
            payerPDFUseCase: payerPDFUseCase,
            profile: profile,
            accountDetailsId: AccountDetailsId(128),
            accountDetailsType: .standard,
            activeAccountDetails: activeAccountDetails,
            invocationSource: .balanceHeaderAction,
            analyticsTracker: analyticsTracker,
            analyticsProvider: analyticsProvider,
            notificationCenter: notificationCenter,
            scheduler: .immediate
        )
        setupPublisher()

        presenter.start(with: view)

        XCTAssertEqual(view.showHudCallsCount, 0)
        XCTAssertEqual(view.hideHudCallsCount, 0)
        let configuredModel = view.configureReceivedInvocations.first
        XCTAssertEqual(configuredModel?.title.title, activeAccountDetails.title)
        XCTAssertEqual(configuredModel?.receiveOptions.count, 1)

        let pageViewModel = configuredModel?.receiveOptions.first
        XCTAssertEqual(pageViewModel?.title, activeAccountDetails.receiveOptions.first?.title)
        XCTAssertEqual(
            pageViewModel?.alert?.viewModel.message.content,
            activeAccountDetails.receiveOptions.first?.alert?.content
        )
    }

    func test_initialSetup_withoutAccountDetails() {
        presenter = AccountDetailsV2PresenterImpl(
            router: router,
            accountDetailsUseCase: usecase,
            payerPDFUseCase: payerPDFUseCase,
            profile: profile,
            accountDetailsId: AccountDetailsId(128),
            accountDetailsType: .standard,
            activeAccountDetails: nil,
            invocationSource: .balanceHeaderAction,
            analyticsTracker: analyticsTracker,
            analyticsProvider: analyticsProvider,
            notificationCenter: notificationCenter,
            scheduler: .immediate
        )
        let publisher = setupPublisher()

        presenter.start(with: view)

        precondition(view.hideHudCallsCount == 0)
        precondition(view.showHudCallsCount == 0)
        precondition(view.configureReceivedInvocations.isEmpty)

        publisher.send(.loading)
        publisher.send(.loaded([.active(activeAccountDetails)]))

        let configuredModel = view.configureReceivedInvocations.first
        XCTAssertEqual(configuredModel?.title.title, activeAccountDetails.title)
        XCTAssertEqual(configuredModel?.receiveOptions.count, 1)

        let pageViewModel = configuredModel?.receiveOptions.first
        XCTAssertEqual(pageViewModel?.title, activeAccountDetails.receiveOptions.first?.title)

        XCTAssertEqual(
            pageViewModel?.alert?.viewModel.message.content,
            activeAccountDetails.receiveOptions.first?.alert?.content
        )

        let infoViewModel = pageViewModel?.infoViewModel
        XCTAssertEqual(
            infoViewModel?.rows.first?.title,
            activeAccountDetails.receiveOptions.first?.details.first?.title
        )

        XCTAssertEqual(view.showHudCallsCount, 1)
        XCTAssertEqual(view.hideHudCallsCount, 1)
        XCTAssertEqual(view.configureReceivedInvocations.first?.title.title, activeAccountDetails.title)
    }

    func test_initialSetup_withoutAccountDetails_errorResponse() {
        let publisher = setupPublisher()
        presenter = AccountDetailsV2PresenterImpl(
            router: router,
            accountDetailsUseCase: usecase,
            payerPDFUseCase: payerPDFUseCase,
            profile: profile,
            accountDetailsId: AccountDetailsId(128),
            accountDetailsType: .standard,
            activeAccountDetails: nil,
            invocationSource: .balanceHeaderAction,
            analyticsTracker: analyticsTracker,
            analyticsProvider: analyticsProvider,
            notificationCenter: notificationCenter,
            scheduler: .immediate
        )

        presenter.start(with: view)

        precondition(view.hideHudCallsCount == 0)
        precondition(view.showHudCallsCount == 0)
        precondition(view.configureReceivedInvocations.isEmpty)

        publisher.send(.loading)
        publisher.send(.recoverableError(UseCaseError.noActiveProfile))

        XCTAssertTrue(view.configureReceivedInvocations.isEmpty)
        XCTAssertEqual(view.showErrorReceivedArguments?.message, "Unexpected error encountered when loading your account details")
    }

    func test_copy_copies() {
        _ = setupPublisher()
        setupWithAccountDetails()

        guard let item = activeAccountDetails.receiveOptions.first?.details.first else {
            XCTFail()
            return
        }

        presenter.showCopyableModal(accountDetailItem: item)

        XCTAssertEqual(router.showBottomSheetReceivedViewModel?.title, "Modal title")
        XCTAssertEqual(router.showBottomSheetReceivedViewModel?.description, "Modal description")
        XCTAssertEqual(
            router.showBottomSheetReceivedViewModel?.footerConfig?.title,
            "Copy Beep beep"
        )

        router.showBottomSheetReceivedViewModel?.footerConfig?.copyAction()
        XCTAssertEqual(pasteboard.clipboard.first, "Boop boop")
        XCTAssertEqual(view.generateHapticFeedbackCallsCount, 1)
        XCTAssertTrue(analyticsProvider.modalCopiedBool)
    }

    func test_bottomSheetShown() {
        _ = setupPublisher()
        setupWithAccountDetails()

        presenter.showInformationModal(title: "La la la", description: "Baby when I think about you", analyticsType: "ANALYTICS")

        XCTAssertEqual(router.showBottomSheetReceivedViewModel?.title, "La la la")
        XCTAssertEqual(router.showBottomSheetReceivedViewModel?.description, "Baby when I think about you")
        XCTAssertEqual(analyticsProvider.summaryDescriptionType, "ANALYTICS")
    }

    func test_routingToExplore() {
        _ = setupPublisher()
        setupWithAccountDetails()

        presenter.showExplore()
        XCTAssertTrue(router.showExploreCalled)
        XCTAssertEqual(analyticsProvider.exploreButtonCurrencyCode, .GBP)
    }

    func test_exploreVisibility_GivenStandartAccountDetails_ThenExploreVisible() {
        _ = setupPublisher()
        setupWithAccountDetails()

        XCTAssertEqual(view.configureReceivedInvocations.first?.isExploreEnabled, true)
    }

    func test_exploreVisibility_GivenBusinessProfile_ThenExploreNotVisible() {
        profile = .business(FakeBusinessProfileInfo())

        _ = setupPublisher()
        setupWithAccountDetails()

        XCTAssertEqual(view.configureReceivedInvocations.first?.isExploreEnabled, false)
    }

    func test_exploreVisibility_GivenDirectDebit_ThenExploreHidden() {
        _ = setupPublisher()

        presenter = AccountDetailsV2PresenterImpl(
            router: router,
            accountDetailsUseCase: usecase,
            payerPDFUseCase: payerPDFUseCase,
            profile: profile,
            accountDetailsId: AccountDetailsId(128),
            accountDetailsType: .directDebit,
            pasteboard: pasteboard,
            activeAccountDetails: nil,
            invocationSource: .balanceHeaderAction,
            analyticsTracker: analyticsTracker,
            analyticsProvider: analyticsProvider,
            notificationCenter: notificationCenter,
            scheduler: .immediate
        )
        let publisher = setupPublisher()

        presenter.start(with: view)

        publisher.send(.loading)
        publisher.send(.loaded([.active(activeAccountDetails)]))

        XCTAssertEqual(view.configureReceivedInvocations.first?.isExploreEnabled, false)
    }

    func test_shareActionSheetShown() {
        _ = setupPublisher()
        setupWithAccountDetails()

        presenter.shareAccountDetails(shareText: "Hellooooo", sender: UIView())

        XCTAssertTrue(router.showShareActionsCalled)
        XCTAssertEqual(analyticsProvider.shareActionSheetShownCurrencyCode, .GBP)
    }

    func test_shareSheet_WhenShareSheetSelectedFromActionList_ThenShareSheetShown() {
        let text = LoremIpsum.medium
        setupPublisher()
        setupWithAccountDetails()

        presenter.shareAccountDetails(shareText: text, sender: UIView())
        router.showShareActionsReceivedArguments?.actions[1].handler()
        XCTAssertEqual(router.showShareSheetReceivedArguments?.text, text)
        XCTAssertEqual(analyticsProvider.shareSheetCurrencyCode, .GBP)
    }

    func test_shareSheet_WhenCopySelectedFromActionList_ThenTextCopied() {
        let text = LoremIpsum.medium
        setupPublisher()
        setupWithAccountDetails()

        XCTAssertFalse(view.showConfirmationCalled)
        presenter.shareAccountDetails(shareText: text, sender: UIView())
        router.showShareActionsReceivedArguments?.actions[0].handler()
        XCTAssertTrue(view.showConfirmationCalled)
        XCTAssertEqual(pasteboard.clipboard.last, text)
        XCTAssertEqual(analyticsProvider.copiedFromActionSheetCurrencyCode, .GBP)
    }

    func test_shareSheet_WhenPDFNotAvailable_ThenItemCountsMatch() {
        setupPublisher()
        setupWithAccountDetails()
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(false))
        presenter.shareAccountDetails(shareText: LoremIpsum.medium, sender: UIView())

        XCTAssertEqual(router.showShareActionsReceivedArguments?.actions.count, 2)
    }

    func test_shareSheet_GivenHappyPath_WhenSharePDFSelected_ThenPDFDownloaded() {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(#function + ".pdf")
        setupPublisher()
        setupWithAccountDetails()
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(path)

        presenter.start(with: view)
        presenter.shareAccountDetails(shareText: LoremIpsum.medium, sender: UIView())
        router.showShareActionsReceivedArguments?.actions[2].handler()
        XCTAssertEqual(router.showFileReceivedArguments?.url, path)
        XCTAssertEqual(analyticsProvider.pdfSharedCurrencyCode, .GBP)
    }

    func test_shareSheet_GivenFailure_WhenSharePDFSelected_ThenErrorMessagesMatch() {
        let error = AccountDetailsPayerPDFUseCaseError.downloadFileFailed(error: MockError.dummy)
        setupPublisher()
        setupWithAccountDetails()
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .fail(with: error)

        presenter.start(with: view)
        presenter.shareAccountDetails(shareText: LoremIpsum.medium, sender: UIView())
        router.showShareActionsReceivedArguments?.actions[2].handler()
        XCTAssertEqual(view.showErrorAlertReceivedArguments?.message, error.localizedDescription)
    }

    func test_shareSheet_GivenHappyPath_WhenSharePDFSelected_ThenLoaderDisplaysMatch() {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(#function + ".pdf")
        setupPublisher()
        setupWithAccountDetails()
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(true))
        payerPDFUseCase.pdfReturnValue = .just(path)

        presenter.start(with: view)
        presenter.shareAccountDetails(shareText: LoremIpsum.medium, sender: UIView())
        let hudShowCount = view.showHudCallsCount
        let hudHideCount = view.hideHudCallsCount
        router.showShareActionsReceivedArguments?.actions[2].handler()
        XCTAssertEqual(view.showHudCallsCount, hudShowCount + 1)
        XCTAssertEqual(view.hideHudCallsCount, hudHideCount + 1)
    }

    func testConfirmation_WhenCopyTriggered_ThenSheetIsShown() {
        let target = "Field"
        setupPublisher()
        setupWithAccountDetails()

        XCTAssertFalse(view.showConfirmationCalled)
        presenter.copyAccountDetails("Sth", for: "Field", analyticsType: "Info")
        XCTAssertEqual("\(target) copied", view.showConfirmationReceivedMessage)
    }

    func testCopyAnalytics_WhenCopyTriggered_ThenCorrectAnalyticsItemsTracked() {
        setupWithAccountDetails()

        presenter.copyAccountDetails(
            "Sth",
            for: "Field",
            analyticsType: "Info"
        )

        XCTAssertEqual(
            (analyticsTracker.trackedEventItems.last as? MockAnalyticsItem)?.name,
            "copyButtonTapped"
        )
        XCTAssertEqual(analyticsProvider.copyButtonAnalyticsType, "Info")
    }

    func testSharingScreenShot_GivenNotification_ThenShareAlertShown() {
        view.activeView = UIView()
        setupWithAccountDetails()

        notificationCenter.post(
            Notification(
                name: UIApplication.userDidTakeScreenshotNotification
            )
        )

        XCTAssertTrue(router.presentCalled)
    }

    private lazy var activeAccountDetails = ActiveAccountDetails.build(
        id: AccountDetailsId(128),
        balanceId: BalanceId(32),
        currency: .GBP,
        currencyName: "British Pound",
        isDeprecated: false,
        title: "I remember it",
        subtitle: "All too well",
        receiveOptions: [AccountDetailsReceiveOption(
            type: .international, title: "Here we are again",
            description: nil,
            summaries: [
                AccountDetailsSummaryItem(
                    type: .info,
                    title: "Dancing around the kitchen",
                    description: AccountDetailsDescription(
                        title: nil,
                        body: "Maybe we got lost in translation, maybe I asked for too much",
                        cta: AccountDetailsCallToAction(
                            label: "Beep beep",
                            content: "Boop boop"
                        )
                    )
                ),
            ],
            details: [
                AccountDetailsDetailItem(
                    title: "And you call me up again",
                    body: "Just to break me like a promise",
                    description: AccountDetailsDescription(
                        title: "Modal title",
                        body: "Modal description",
                        cta: AccountDetailsCallToAction(
                            label: "Beep beep",
                            content: "Boop boop"
                        )
                    ),
                    analyticsType: nil,
                    shouldObfuscate: false
                ),
            ],
            shareText: "Because I remember it all too well",
            alert: .build(
                content: "",
                type: .error,
                action: AccountDetailsAlert.Action.build(
                    text: "",
                    uri: uriString
                )
            )
        )],
        features: [AccountDetailsFeature(key: .directDebits, title: "Plaid shirt nights", isSupported: true)]
    )
}

// MARK: - Helpers

private extension AccountDetailsV2PresenterTests {
    func setupWithAccountDetails() {
        presenter = AccountDetailsV2PresenterImpl(
            router: router,
            accountDetailsUseCase: usecase,
            payerPDFUseCase: payerPDFUseCase,
            profile: profile,
            accountDetailsId: AccountDetailsId(128),
            accountDetailsType: .standard,
            pasteboard: pasteboard,
            activeAccountDetails: activeAccountDetails,
            invocationSource: .balanceHeaderAction,
            analyticsTracker: analyticsTracker,
            analyticsProvider: analyticsProvider,
            notificationCenter: notificationCenter,
            scheduler: .immediate
        )
        let publisher = setupPublisher()

        presenter.start(with: view)

        publisher.send(.loading)
        publisher.send(.loaded([.active(activeAccountDetails)]))

        XCTAssertEqual(analyticsProvider.pageShownContext, .standard)
        XCTAssertEqual(analyticsProvider.pageShownCurrencyCode, .GBP)
    }

    @discardableResult
    func setupPublisher() -> CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never> {
        payerPDFUseCase.checkAvailabilityReturnValue = .just(.content(false))

        let publisher = CurrentValueSubject<LoadableDataState<[AccountDetails]>?, Never>(nil)
        usecase.accountDetails = publisher.eraseToAnyPublisher()
        return publisher
    }
}

// MARK: - Alert action

extension AccountDetailsV2PresenterTests {
    func testAlertAction_WhenAlertActionTriggerred_ThenRouterReceivedTheURI() {
        setupPublisher()
        setupWithAccountDetails()

        XCTAssertFalse(router.handleURICalled)
        view.configureReceivedModel?.receiveOptions.first?.alert?.viewModel.action?.handler()
        XCTAssertEqual(router.handleURIReceivedUri?.description, uriString)
    }
}

private final class MockViewController: UIViewController, UIDocumentInteractionControllerDelegate {}
