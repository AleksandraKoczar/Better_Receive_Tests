import AnalyticsKitTestingSupport
import Combine
import ContactsKit
import ContactsKitTestingSupport
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import UserKit
import UserKitTestingSupport
import WiseCore

final class PaymentRequestsListPresenterTests: TWTestCase {
    private let paymentRequestId = PaymentRequestId("XYZ")
    private let seekPosition = "2023-08-03T12:26:48.395873Z"
    private let urlString = "https://wise.com/xyz"

    private var presenter: PaymentRequestsListPresenterImpl!
    private var flowDismissed = false
    private var view: PaymentRequestsListViewMock!
    private var router: PaymentRequestsListRouterMock!
    private var paymentRequestListUseCase: PaymentRequestListUseCaseMock!
    private var paymentRequestsListViewModelFactory: PaymentRequestsListViewModelFactoryMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var imageLoader: URIImageLoaderMock!
    private var featureService: StubFeatureService!

    override func setUp() {
        super.setUp()
        view = PaymentRequestsListViewMock()
        router = PaymentRequestsListRouterMock()
        paymentRequestListUseCase = PaymentRequestListUseCaseMock()
        paymentRequestsListViewModelFactory = PaymentRequestsListViewModelFactoryMock()
        analyticsTracker = StubAnalyticsTracker()
        imageLoader = URIImageLoaderMock()
        featureService = StubFeatureService()
        presenter = makePresenter(
            supportedPaymentRequestType: .singleUseOnly,
            visibleState: .unpaid(.closestToExpiry)
        )

        paymentRequestListUseCase.paymentRequestStatusReturnValue = .just(.hasPaymentRequests)
    }

    override func tearDown() {
        view = nil
        router = nil
        paymentRequestListUseCase = nil
        paymentRequestsListViewModelFactory = nil
        imageLoader = nil
        analyticsTracker = nil
        presenter = nil
        super.tearDown()
    }

    func test_start_withPaymentLinks() throws {
        presenter = makePresenter(
            supportedPaymentRequestType: .singleUseAndReusable,
            visibleState: .active
        )
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        let viewModel = makeViewModelForPaymentLinksWithMethodManagementDisabled()
        paymentRequestsListViewModelFactory.makeReturnValue = viewModel

        presenter.start(with: view)

        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        XCTAssertEqual(view.showLoadingCallsCount, 1)
        XCTAssertEqual(view.hideLoadingCallsCount, 1)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 1)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .publishedAt,
            sortOrder: .descend
        )
        XCTAssertEqual(arguments.statuses, [.published])
        XCTAssertEqual(arguments.requestTypes, [.singleUse, .reusable])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)
    }

    func test_start_withPaymentRequests() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        let viewModel = makeViewModelForPaymentRequests()
        paymentRequestsListViewModelFactory.makeReturnValue = viewModel

        presenter.start(with: view)

        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        XCTAssertEqual(view.showLoadingCallsCount, 1)
        XCTAssertEqual(view.hideLoadingCallsCount, 1)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 1)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .expirationAt,
            sortOrder: .ascend
        )
        XCTAssertEqual(arguments.statuses, [.published])
        XCTAssertEqual(arguments.requestTypes, [.singleUse])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)
    }

    func test_start_givenSupportInvoices_thenConfigureView() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        let viewModel = makeViewModelForPaymentRequests()
        paymentRequestsListViewModelFactory.makeReturnValue = viewModel
        presenter = makePresenter(
            supportedPaymentRequestType: .invoiceOnly,
            visibleState: .upcoming(.closestToExpiry)
        )

        presenter.start(with: view)

        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
        XCTAssertEqual(view.showLoadingCallsCount, 1)
        XCTAssertEqual(view.hideLoadingCallsCount, 1)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 1)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .expirationAt,
            sortOrder: .ascend
        )
        XCTAssertEqual(arguments.statuses, [.published])
        XCTAssertEqual(arguments.requestTypes, [.invoice])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)
    }

    func test_start_givenFetchPaymentRequestSummariesFails_thenShowError() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .fail(with: MockError.dummy)

        presenter.start(with: view)

        XCTAssertEqual(view.showLoadingCallsCount, 1)
        XCTAssertEqual(view.hideLoadingCallsCount, 1)
        XCTAssertEqual(view.showDismissableAlertCallsCount, 1)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 1)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .expirationAt,
            sortOrder: .ascend
        )
        XCTAssertEqual(arguments.statuses, [.published])
        XCTAssertEqual(arguments.requestTypes, [.singleUse])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)
    }

    func test_inactiveChipTapped() throws {
        presenter = makePresenter(
            supportedPaymentRequestType: .singleUseAndReusable,
            visibleState: .active
        )
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        presenter.start(with: view)

        presenter.segmentedControlSelected(at: 1)

        XCTAssertEqual(view.showLoadingCallsCount, 2)
        XCTAssertEqual(view.hideLoadingCallsCount, 2)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 2)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .updatedAt,
            sortOrder: .descend
        )
        XCTAssertEqual(arguments.statuses, [.completed, .invalidated, .expired])
        XCTAssertEqual(arguments.requestTypes, [.singleUse, .reusable])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)

        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - Tab Change")
        let tabName = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["Tab"] as? String)
        XCTAssertEqual(tabName, "Inactive")
    }

    func test_paidChipTapped() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        presenter.start(with: view)

        presenter.segmentedControlSelected(at: 1)

        XCTAssertEqual(view.showLoadingCallsCount, 2)
        XCTAssertEqual(view.hideLoadingCallsCount, 2)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 2)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .updatedAt,
            sortOrder: .descend
        )
        XCTAssertEqual(arguments.statuses, [.completed])
        XCTAssertEqual(arguments.requestTypes, [.singleUse])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)

        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - Tab Change")
        let tabName = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["Tab"] as? String)
        XCTAssertEqual(tabName, "Paid")
    }

    func test_pastChipTapped() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        presenter = makePresenter(
            supportedPaymentRequestType: .invoiceOnly,
            visibleState: .upcoming(.closestToExpiry)
        )
        presenter.start(with: view)

        presenter.segmentedControlSelected(at: 1)

        XCTAssertEqual(view.showLoadingCallsCount, 2)
        XCTAssertEqual(view.hideLoadingCallsCount, 2)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 2)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .updatedAt,
            sortOrder: .descend
        )
        XCTAssertEqual(arguments.statuses, [.completed, .invalidated, .expired])
        XCTAssertEqual(arguments.requestTypes, [.invoice])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)

        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Manage Requests - Tab Change")
        let tabName = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked?["Tab"] as? String)
        XCTAssertEqual(tabName, "Past")
    }

    func test_prefetch() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        paymentRequestsListViewModelFactory.makeSectionViewModelsReturnValue = []
        presenter.start(with: view)

        presenter.prefetch(id: paymentRequestId.value)

        XCTAssertEqual(view.showLoadingCallsCount, 1)
        XCTAssertEqual(view.hideLoadingCallsCount, 1)
        XCTAssertEqual(view.showNewSectionsCallsCount, 1)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 2)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .expirationAt,
            sortOrder: .ascend
        )
        XCTAssertEqual(arguments.statuses, [.published])
        XCTAssertEqual(arguments.requestTypes, [.singleUse])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)
        XCTAssertEqual(arguments.seekPosition, seekPosition)
    }

    func test_createNewRequest_givenSupportInvoice_thenShowCreateInvoice() {
        presenter = makePresenter(
            supportedPaymentRequestType: .invoiceOnly,
            visibleState: .upcoming(.closestToExpiry)
        )

        presenter.createNewRequest()

        XCTAssertEqual(router.showCreateInvoiceOnWebCallsCount, 1)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            PaymentRequestsListAnalyticsView.CreateTapped(target: .invoice).eventName
        )
    }

    func test_createNewRequest_givenNotSupportInvoice_thenStartRequestMoneyFlow() {
        presenter.createNewRequest()

        XCTAssertEqual(router.showNewRequestFlowCallsCount, 1)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            PaymentRequestsListAnalyticsView.CreateTapped(target: .paymentRequest).eventName
        )
    }

    func test_settingsButtonTapped_thenShowWebView() {
        presenter = makePresenter(
            supportedPaymentRequestType: .singleUseAndReusable,
            visibleState: .upcoming(.closestToExpiry)
        )

        presenter.openSettingsTapped()
        XCTAssertEqual(router.showMethodManagementOnWebCallsCount, 1)
    }

    func test_rowTapped() throws {
        presenter.rowTapped(id: paymentRequestId.value)

        let arguments = try XCTUnwrap(router.showRequestDetailReceivedArguments)
        XCTAssertEqual(arguments.paymentRequestId, paymentRequestId)
        XCTAssertEqual(router.showRequestDetailCallsCount, 1)
    }

    func test_dismiss() {
        presenter.dismiss()

        XCTAssertTrue(flowDismissed)
    }

    func test_requestStatusUpdated() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        paymentRequestsListViewModelFactory.makeSectionViewModelsReturnValue = []
        presenter.start(with: view)

        presenter.requestStatusUpdated()

        XCTAssertEqual(view.showLoadingCallsCount, 1)
        XCTAssertEqual(view.hideLoadingCallsCount, 1)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 2)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .expirationAt,
            sortOrder: .ascend
        )
        XCTAssertEqual(arguments.statuses, [.published])
        XCTAssertEqual(arguments.requestTypes, [.singleUse])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)
    }

    func test_invoiceRequestCreated() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        paymentRequestsListViewModelFactory.makeSectionViewModelsReturnValue = []
        presenter = makePresenter(
            supportedPaymentRequestType: .invoiceOnly,
            visibleState: .upcoming(.closestToExpiry)
        )
        presenter.start(with: view)

        presenter.invoiceRequestCreated()

        XCTAssertEqual(view.showLoadingCallsCount, 2)
        XCTAssertEqual(view.hideLoadingCallsCount, 2)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 2)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .expirationAt,
            sortOrder: .ascend
        )
        XCTAssertEqual(arguments.statuses, [.published])
        XCTAssertEqual(arguments.requestTypes, [.invoice])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)
    }

    func test_refresh() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        paymentRequestsListViewModelFactory.makeSectionViewModelsReturnValue = []
        presenter = makePresenter(
            supportedPaymentRequestType: .invoiceOnly,
            visibleState: .upcoming(.closestToExpiry)
        )
        presenter.start(with: view)

        presenter.invoiceRequestCreated()

        XCTAssertEqual(view.showLoadingCallsCount, 2)
        XCTAssertEqual(view.hideLoadingCallsCount, 2)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 2)
        let arguments = try XCTUnwrap(paymentRequestListUseCase.paymentRequestSummariesReceivedArguments)
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .expirationAt,
            sortOrder: .ascend
        )
        XCTAssertEqual(arguments.statuses, [.published])
        XCTAssertEqual(arguments.requestTypes, [.invoice])
        XCTAssertEqual(arguments.sortDescriptor, expectedSortDescriptor)
    }

    func test_sortTapped() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        let viewModel = makeRadioOptionsViewModel()
        paymentRequestsListViewModelFactory.makeRadioOptionsViewModelReturnValue = viewModel
        presenter.start(with: view)

        presenter.sortTapped()

        XCTAssertEqual(view.showRadioOptionsCallsCount, 1)
        let receivedViewModel = try XCTUnwrap(view.showRadioOptionsReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
    }

    func test_fetchAvatarModel_givenLoadImageSuccess_thenReturnCorrectAvatarModel() throws {
        let image = UIImage()
        imageLoader.loadReturnValue = .just(image)

        let result = try awaitPublisher(
            presenter.fetchAvatarModel(
                urlString: urlString,
                badge: nil,
                fallbackModel: .initials(
                    Initials(value: LoremIpsum.veryShort),
                    badge: nil
                )
            )
        )

        let expected = AvatarModel.image(image, badge: nil)
        expectNoDifference(result.value, expected)
    }

    func test_fetchAvatarModel_givenLoadImageFailure_thenReturnCorrectAvatarModel() throws {
        let model = AvatarModel.initials(
            Initials(value: LoremIpsum.veryShort),
            badge: nil
        )
        imageLoader.loadReturnValue = .fail(with: MockError.dummy)

        let result = try awaitPublisher(
            presenter.fetchAvatarModel(
                urlString: urlString,
                badge: nil,
                fallbackModel: model
            )
        )

        expectNoDifference(result.value, model)
    }

    func test_sortingOptionTapped_givenClosestToExpiryIsSelected_thenUpdateRadioOptions() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        let viewModel = makeRadioOptionsViewModel()
        paymentRequestsListViewModelFactory.makeRadioOptionsViewModelReturnValue = viewModel
        presenter.start(with: view)

        presenter.sortingOptionTapped(at: 0)

        XCTAssertEqual(view.updateRadioOptionsCallsCount, 1)
        let receivedViewModel = try XCTUnwrap(view.updateRadioOptionsReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
    }

    func test_sortingOptionTapped_givenMostRecentlyRequestedIsSelected_thenUpdateRadioOptions() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        let viewModel = makeRadioOptionsViewModelForClosestToExpiry()
        paymentRequestsListViewModelFactory.makeRadioOptionsViewModelReturnValue = viewModel
        presenter.start(with: view)

        presenter.sortingOptionTapped(at: 1)

        XCTAssertEqual(view.updateRadioOptionsCallsCount, 1)
        let receivedViewModel = try XCTUnwrap(view.updateRadioOptionsReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
    }

    func test_applySortingTapped_givenSelectClosestToExpiry_thenFetchCorrectData() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        presenter.start(with: view)

        presenter.applySortingAction()

        XCTAssertEqual(view.dismissRadioOptionsCallsCount, 1)
        XCTAssertEqual(view.showLoadingCallsCount, 1)
        XCTAssertEqual(view.hideLoadingCallsCount, 1)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 1)
        let arguments = paymentRequestListUseCase.paymentRequestSummariesReceivedArguments
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .expirationAt,
            sortOrder: .ascend
        )
        XCTAssertEqual(arguments?.statuses, [.published])
        XCTAssertEqual(arguments?.sortDescriptor, expectedSortDescriptor)
    }

    func test_applySortingTapped_givenSelectMostRecentlyRequested_thenFetchCorrectData() throws {
        paymentRequestListUseCase.paymentRequestSummariesReturnValue = .just(makeSummaries())
        paymentRequestsListViewModelFactory.makeReturnValue = makeViewModel()
        paymentRequestsListViewModelFactory.makeRadioOptionsViewModelReturnValue = makeRadioOptionsViewModelForClosestToExpiry()
        presenter.start(with: view)
        presenter.sortingOptionTapped(at: 1)

        presenter.applySortingAction()

        XCTAssertEqual(view.dismissRadioOptionsCallsCount, 1)
        XCTAssertEqual(view.showLoadingCallsCount, 2)
        XCTAssertEqual(view.hideLoadingCallsCount, 2)
        XCTAssertEqual(paymentRequestListUseCase.paymentRequestSummariesCallsCount, 2)
        let arguments = paymentRequestListUseCase.paymentRequestSummariesReceivedArguments
        let expectedSortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .publishedAt,
            sortOrder: .descend
        )
        XCTAssertEqual(arguments?.statuses, [.published])
        XCTAssertEqual(arguments?.sortDescriptor, expectedSortDescriptor)
    }

    func testStart_GivenNoPaymentRequests() {
        paymentRequestsListViewModelFactory.makeGlobalEmptyStateReturnValue = makeViewModel()
        paymentRequestListUseCase.paymentRequestStatusReturnValue = .just(.noPaymentRequests)
        presenter.start(with: view)

        XCTAssertEqual(paymentRequestsListViewModelFactory.makeGlobalEmptyStateCallsCount, 1)
    }
}

// MARK: - Domain model

private extension PaymentRequestsListPresenterTests {
    func makeSummaries() -> PaymentRequestSummaries {
        PaymentRequestSummaries.build(
            groups: [
                PaymentRequestSummaries.Group.build(
                    id: LoremIpsum.short,
                    label: LoremIpsum.short,
                    summaries: [
                        PaymentRequestSummaries.Group.Summary.build(
                            id: paymentRequestId.value,
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium,
                            icon: "urn:wise:icons:request-send",
                            badge: .warning
                        ),
                    ]
                ),
            ],
            nextPageState: .hasNextPage(seekPosition: seekPosition)
        )
    }
}

// MARK: - View model

private extension PaymentRequestsListPresenterTests {
    func makeViewModelForPaymentLinksWithMethodManagementDisabled() -> PaymentRequestsListViewModel {
        PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: [
                .init(title: "New", icon: Icons.plus.image, action: {}),
            ],
            header: PaymentRequestsListHeaderView.ViewModel(
                title: LargeTitleViewModel(title: "Payment links"),
                segmentedControl: SegmentedControlView.ViewModel(
                    segments: [
                        "Active",
                        "Inactive",
                    ],
                    selectedIndex: 0,
                    onChange: { _ in }
                )
            ),
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: "Active",
                        viewModel: SectionHeaderViewModel(
                            title: "Active",
                            action: nil,
                            accessibilityHint: "Active"
                        ),
                        isSectionHeaderHidden: true,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: AvatarPublisher.image(
                                    avatarPublisher: .just(
                                        AvatarModel.image(
                                            Icons.requestSend.image,
                                            badge: Icons.alert.image
                                        )
                                    )
                                )
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: true
        ))
    }

    func makeViewModelForPaymentRequests() -> PaymentRequestsListViewModel {
        PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: [.init(title: "New", icon: Icons.plus.image, action: {})],
            header: PaymentRequestsListHeaderView.ViewModel(
                title: LargeTitleViewModel(title: "Payment requests"),
                segmentedControl: SegmentedControlView.ViewModel(
                    segments: [
                        "Unpaid",
                        "Paid",
                    ],
                    selectedIndex: 0,
                    onChange: { _ in }
                )
            ),
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: "Closest to expiry",
                        viewModel: SectionHeaderViewModel(
                            title: "Closest to expiry",
                            action: Action(
                                title: "Sort",
                                handler: {}
                            ),
                            accessibilityHint: "Closest to expiry"
                        ),
                        isSectionHeaderHidden: true,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: AvatarPublisher.image(
                                    avatarPublisher: .just(
                                        AvatarModel.image(
                                            Icons.requestSend.image,
                                            badge: Icons.alert.image
                                        )
                                    )
                                )
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: true
        ))
    }

    func makeViewModel() -> PaymentRequestsListViewModel {
        PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: [.init(title: "New", icon: Icons.plus.image, action: {})],
            header: PaymentRequestsListHeaderView.ViewModel(
                title: LargeTitleViewModel(title: "Payment requests"),
                segmentedControl: SegmentedControlView.ViewModel(
                    segments: [
                        "Unpaid",
                        "Paid",
                    ],
                    selectedIndex: 0,
                    onChange: { _ in }
                )
            ),
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: LoremIpsum.veryShort,
                        viewModel: SectionHeaderViewModel(
                            title: LoremIpsum.veryShort,
                            action: Action(
                                title: "Sort",
                                handler: {}
                            ),
                            accessibilityHint: LoremIpsum.veryShort
                        ),
                        isSectionHeaderHidden: true,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: AvatarPublisher.image(
                                    avatarPublisher: .just(
                                        AvatarModel.image(
                                            Icons.requestSend.image,
                                            badge: Icons.alert.image
                                        )
                                    )
                                )
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: true
        ))
    }

    func makeRadioOptionsViewModel() -> PaymentRequestsListRadioOptionsViewModel {
        PaymentRequestsListRadioOptionsViewModel(
            title: "Sort by",
            options: [
                RadioOptionViewModel(
                    model: OptionViewModel(title: "Closest to expiry"),
                    isSelected: true
                ),
                RadioOptionViewModel(
                    model: OptionViewModel(title: "Most recently requested"),
                    isSelected: false
                ),
            ],
            dismissOnSelection: false,
            action: PaymentRequestsListRadioOptionsViewModel.Action(
                title: "Apply",
                style: .largePrimary,
                handler: {}
            ),
            handler: { _, _ in }
        )
    }

    func makeRadioOptionsViewModelForClosestToExpiry() -> PaymentRequestsListRadioOptionsViewModel {
        PaymentRequestsListRadioOptionsViewModel(
            title: "Sort by",
            options: [
                RadioOptionViewModel(
                    model: OptionViewModel(title: "Closest to expiry"),
                    isSelected: false
                ),
                RadioOptionViewModel(
                    model: OptionViewModel(title: "Most recently requested"),
                    isSelected: true
                ),
            ],
            dismissOnSelection: false,
            action: PaymentRequestsListRadioOptionsViewModel.Action(
                title: "Apply",
                style: .largePrimary,
                handler: {}
            ),
            handler: { _, _ in }
        )
    }
}

// MARK: - Helpers

private extension PaymentRequestsListPresenterTests {
    func makePresenter(
        supportedPaymentRequestType: SupportedPaymentRequestType,
        visibleState: PaymentRequestSummaryList.State
    ) -> PaymentRequestsListPresenterImpl {
        PaymentRequestsListPresenterImpl(
            supportedPaymentRequestType: supportedPaymentRequestType,
            visibleState: visibleState,
            profile: FakeBusinessProfileInfo().asProfile(),
            featureService: featureService,
            router: router,
            paymentRequestListUseCase: paymentRequestListUseCase,
            paymentRequestsListViewModelFactory: paymentRequestsListViewModelFactory,
            imageLoader: imageLoader,
            analyticsTracker: analyticsTracker,
            scheduler: .immediate,
            flowDismissed: { self.flowDismissed = true }
        )
    }
}
