import AnalyticsKitTestingSupport
import ContactsKit
import ContactsKitTestingSupport
import NeptuneTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport

final class WisetagScannedProfilePresenterTests: TWTestCase {
    private let profile = FakePersonalProfileInfo().asProfile()
    private var presenter: WisetagScannedProfilePresenterImpl!
    private var view: WisetagScannedProfileViewMock!
    private var wisetagContactInteractor: WisetagContactInteractorMock!
    private var router: WisetagScannedProfileRouterMock!
    private var viewModelMapper: WisetagScannedProfileViewModelMapperMock!
    private var state: WisetagScannedProfileLoadingState = .findingUser
    private var analyticsTracker: StubAnalyticsTracker!
    private var bottomSheet: BottomSheetMock!

    private let contact = Contact.build(
        id: Contact.Id.match("123", contactId: "100"),
        title: "title",
        subtitle: "subtitle",
        isVerified: true,
        isHighlighted: false,
        labels: [],
        hasAvatar: true,
        avatarPublisher: .canned,
        lastUsedDate: nil,
        nickname: ""
    )

    override func setUp() {
        super.setUp()
        view = WisetagScannedProfileViewMock()
        wisetagContactInteractor = WisetagContactInteractorMock()
        router = WisetagScannedProfileRouterMock()
        viewModelMapper = WisetagScannedProfileViewModelMapperMock()
        state = .findingUser
        analyticsTracker = StubAnalyticsTracker()
        bottomSheet = BottomSheetMock()
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .personal
        )
        presenter = WisetagScannedProfilePresenterImpl(
            profile: profile,
            scannedProfileNickname: "abcd",
            contactSearch: contactSearch,
            router: router,
            analyticsTracker: analyticsTracker,
            viewModelMapper: viewModelMapper,
            wisetagContactInteractor: wisetagContactInteractor,
            scheduler: .immediate
        )
        presenter.setBottomSheet(bottomSheet)
    }

    override func tearDown() {
        presenter = nil
        view = nil
        wisetagContactInteractor = nil
        viewModelMapper = nil
        router = nil
        analyticsTracker = nil
        bottomSheet = nil
        super.tearDown()
    }

    func test_start_given_RecipientAdded_thenConfigureView() throws {
        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        let viewController = MockViewController()
        view.bottomSheetContent = viewController

        presenter.start(with: view)

        XCTAssertTrue(analyticsTracker.hasMixpanelEventTracked("Contact Link Page - Started"))

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        let state = arguments.state

        switch state {
        case let .recipientAdded(scannedProfile: scannedProfile, contactId: contactId):
            XCTAssertNotNil(scannedProfile)
            XCTAssertNotNil(contactId)
        case let .inContacts(scannedProfile: scannedProfile, contactId: contactId):
            XCTAssertNotNil(scannedProfile)
            XCTAssertNotNil(contactId)
        default:
            XCTFail("Should not be this state")
        }

        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Contact Link Page - Loaded")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Match - Is Existing"] as? Bool, true)

        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
    }

    func test_start_given_UserFound_thenConfigureView() throws {
        makePresenterForContactIdIsNil()

        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        let viewController = MockViewController()
        view.bottomSheetContent = viewController

        presenter.start(with: view)

        XCTAssertTrue(analyticsTracker.hasMixpanelEventTracked("Contact Link Page - Started"))

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        let state = arguments.state

        switch state {
        case let .userFound(scannedProfile: scannedProfile):
            XCTAssertNotNil(scannedProfile)
        default:
            XCTFail("Should not be this state")
        }

        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
    }

    func test_start_addRecipientButtonTapped() throws {
        makePresenterForContactIdIsNil()

        wisetagContactInteractor.createContactReturnValue = .just(Contact.build(
            id: Contact.Id.match("123", contactId: "100"),
            title: "title",
            subtitle: "subtitle",
            isVerified: true,
            isHighlighted: false,
            labels: [],
            hasAvatar: true,
            avatarPublisher: .canned,
            lastUsedDate: nil,
            nickname: nil
        ))

        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        view.bottomSheetContent = MockViewController()

        // configure called 2 times
        presenter.start(with: view)

        // configure called 1 time
        presenter.addRecipientButtonTapped()

        XCTAssertEqual(analyticsTracker.lastMixpanelEventNameTracked, "Contact Link Page - Added")

        XCTAssertEqual(view.configureCallsCount, 2)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        let state = arguments.state
        switch state {
        case let .recipientAdded(scannedProfile: scannedProfile):
            XCTAssertNotNil(scannedProfile)
        default:
            XCTFail("Should not be this state")
        }
    }

    func test_start_sendButtonTapped_givenProfileInContacts() throws {
        let contact = Contact.build(
            id: Contact.Id.match("123", contactId: "100"),
            title: "title",
            subtitle: "subtitle",
            isVerified: true,
            isHighlighted: false,
            labels: [],
            hasAvatar: true,
            avatarPublisher: .canned,
            lastUsedDate: nil,
            nickname: nil
        )
        let isSelf = false

        wisetagContactInteractor.lookupContactReturnValue = .just(ContactSearch.build(contact: contact, isSelf: isSelf))

        wisetagContactInteractor.resolveRecipientReturnValue = .just(.canned)

        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        view.bottomSheetContent = MockViewController()
        presenter.start(with: view)
        presenter.sendButtonTapped()

        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Contact Link Page - Finished")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Reason"] as! String, "SEND")
        XCTAssertEqual(properties["Match - Is Existing"] as? Bool, true)

        XCTAssertEqual(view.configureErrorCallsCount, 0)
        XCTAssertEqual(wisetagContactInteractor.createContactCallsCount, 0)
        XCTAssertEqual(router.sendMoneyCallsCount, 1)
    }

    func test_start_sendButtonTapped_givenProfileNotInContacts() throws {
        makePresenterForContactIdIsNil()
        wisetagContactInteractor.createContactReturnValue = .just(Contact.build(
            id: Contact.Id.match("123", contactId: "100"),
            title: "title",
            subtitle: "subtitle",
            isVerified: true,
            isHighlighted: false,
            labels: [],
            hasAvatar: true,
            avatarPublisher: .canned,
            lastUsedDate: nil,
            nickname: nil
        ))
        wisetagContactInteractor.resolveRecipientReturnValue = .just(.canned)
        let recipient = RecipientResolved.canned

        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        view.bottomSheetContent = MockViewController()
        presenter.start(with: view)
        presenter.sendButtonTapped()

        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Contact Link Page - Finished")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Reason"] as! String, "SEND")

        XCTAssertEqual(wisetagContactInteractor.createContactCallsCount, 1)
        XCTAssertEqual(router.sendMoneyCallsCount, 1)
        XCTAssertEqual(router.sendMoneyReceivedArguments?.contact, recipient)
    }

    func test_start_requestButtonTapped_GivenProfileInContacts() throws {
        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        view.bottomSheetContent = MockViewController()
        presenter.start(with: view)
        presenter.requestButtonTapped()

        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Contact Link Page - Finished")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Reason"] as! String, "REQUEST")
        XCTAssertEqual(properties["Match - Is Existing"] as? Bool, true)

        XCTAssertEqual(wisetagContactInteractor.createContactCallsCount, 0)
        XCTAssertEqual(router.requestMoneyCallsCount, 1)
        XCTAssertEqual(router.requestMoneyReceivedContact, contact)
    }

    func test_start_requestButtonTapped_GivenProfileNotInContacts() throws {
        makePresenterForContactIdIsNil()

        wisetagContactInteractor.createContactReturnValue = .just(.canned)
        let contact = Contact.canned

        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        view.bottomSheetContent = MockViewController()
        presenter.start(with: view)
        presenter.requestButtonTapped()

        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Contact Link Page - Finished")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Reason"] as! String, "REQUEST")

        XCTAssertEqual(wisetagContactInteractor.createContactCallsCount, 1)
        XCTAssertEqual(router.requestMoneyCallsCount, 1)
        XCTAssertEqual(router.requestMoneyReceivedContact, contact)
    }

    func test_start_addRecipientButtonTapped_thenShowError() throws {
        makePresenterForContactIdIsNil()
        wisetagContactInteractor.createContactReturnValue = .fail(with: MockError.dummy)

        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        view.bottomSheetContent = MockViewController()

        // configure called 2 times
        presenter.start(with: view)

        // configure called 1 time
        presenter.addRecipientButtonTapped()

        XCTAssertEqual(analyticsTracker.lastMixpanelEventNameTracked, "Contact Link Page - Started")

        XCTAssertEqual(view.configureCallsCount, 1)

        XCTAssertEqual(view.configureErrorCallsCount, 1)

        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        let state = arguments.state
        switch state {
        case let .userFound(scannedProfile: scannedProfile):
            XCTAssertNotNil(scannedProfile)
        default:
            XCTFail("Should not be this state")
        }
    }

    func test_start_sendButtonTapped_GivenProfileInContactsAndResolveRecipientFailed_thenShowError() throws {
        makePresenterForContactIdIsNil()

        wisetagContactInteractor.createContactReturnValue = .just(.johnDoe)
        wisetagContactInteractor.resolveRecipientReturnValue = .fail(with: MockError.dummy)

        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        view.bottomSheetContent = MockViewController()
        presenter.start(with: view)
        presenter.sendButtonTapped()

        XCTAssertEqual(view.configureCallsCount, 1)
        XCTAssertEqual(view.configureErrorCallsCount, 1)

        XCTAssertEqual(wisetagContactInteractor.createContactCallsCount, 1)
        XCTAssertEqual(router.sendMoneyCallsCount, 0)

        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        let state = arguments.state
        switch state {
        case .userFound:
            break
        default:
            XCTFail("Should not be this state")
        }
    }

    func test_start_requestButtonTapped_GivenProfileNotInContactsAndCreateContactFailed_thenShowError() throws {
        makePresenterForContactIdIsNil()

        wisetagContactInteractor.createContactReturnValue = .fail(with: MockError.dummy)

        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        view.bottomSheetContent = MockViewController()
        presenter.start(with: view)
        presenter.requestButtonTapped()

        XCTAssertEqual(view.configureCallsCount, 1)
        XCTAssertEqual(view.configureErrorCallsCount, 1)

        XCTAssertEqual(wisetagContactInteractor.createContactCallsCount, 1)
        XCTAssertEqual(router.requestMoneyCallsCount, 0)

        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        let state = arguments.state
        switch state {
        case .userFound:
            break
        default:
            XCTFail("Should not be this state")
        }
    }

    func test_start_contactIsSelf_then_ConfigureView() throws {
        let contact = Contact.build(
            id: Contact.Id.match("123", contactId: nil),
            title: "title",
            subtitle: "subtitle",
            isVerified: true,
            isHighlighted: false,
            labels: [],
            hasAvatar: true,
            avatarPublisher: .canned,
            lastUsedDate: nil,
            nickname: nil
        )

        let contactSearch = ContactSearch.build(contact: contact, isSelf: true)
        presenter = WisetagScannedProfilePresenterImpl(
            profile: profile,
            scannedProfileNickname: "abcd",
            contactSearch: contactSearch,
            router: router,
            analyticsTracker: analyticsTracker,
            viewModelMapper: viewModelMapper,
            wisetagContactInteractor: wisetagContactInteractor,
            scheduler: .immediate
        )
        presenter.setBottomSheet(bottomSheet)

        let viewModel = WisetagScannedProfileViewModel.build()
        viewModelMapper.makeReturnValue = viewModel
        view.bottomSheetContent = MockViewController()

        presenter.start(with: view)

        XCTAssertTrue(analyticsTracker.hasMixpanelEventTracked("Contact Link Page - Started"))

        XCTAssertEqual(viewModelMapper.makeCallsCount, 1)
        let arguments = try XCTUnwrap(viewModelMapper.makeReceivedArguments)
        let state = arguments.state

        switch state {
        case let .isSelf(scannedProfile: scannedProfile):
            XCTAssertNotNil(scannedProfile)
        default:
            XCTFail("Should not be this state")
        }

        let event = try XCTUnwrap(analyticsTracker.trackedMixpanelEvents("Contact Link Page - Loaded")?.last)
        let properties = event.eventProperties()
        XCTAssertEqual(properties["Match - Is Self"] as? Bool, true)

        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)
    }
}

private extension WisetagScannedProfilePresenterTests {
    func makePresenterForContactIdIsNil() {
        let contact = Contact.build(
            id: Contact.Id.match("123", contactId: nil),
            title: "title",
            subtitle: "subtitle",
            isVerified: true,
            isHighlighted: false,
            labels: [],
            hasAvatar: true,
            avatarPublisher: .canned,
            lastUsedDate: nil,
            nickname: ""
        )
        let contactSearch = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .personal
        )
        presenter = WisetagScannedProfilePresenterImpl(
            profile: profile,
            scannedProfileNickname: "abcd",
            contactSearch: contactSearch,
            router: router,
            analyticsTracker: analyticsTracker,
            viewModelMapper: viewModelMapper,
            wisetagContactInteractor: wisetagContactInteractor,
            scheduler: .immediate
        )
        presenter.setBottomSheet(bottomSheet)
    }
}
