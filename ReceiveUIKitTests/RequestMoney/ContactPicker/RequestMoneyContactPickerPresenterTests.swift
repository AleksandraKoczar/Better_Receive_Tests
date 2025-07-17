import AnalyticsKit
import AnalyticsKitTestingSupport
import Combine
import CombineSchedulers
import ContactsKit
import ContactsKitTestingSupport
import Neptune
import ReceiveKit
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport
import WiseCore

final class RequestMoneyContactPickerPresenterTests: TWTestCase {
    private var presenter: RequestMoneyContactPickerPresenterImpl!
    private var contactListPagePublisherFactory: ContactListPagePublisherFactoryMock!
    private var router: RequestMoneyContactPickerRouterMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var view: RequestMoneyContactPickerViewMock!
    private var notificationCenter: MockNotificationCenter!
    private var nudgeProvider: ContactPickerNudgeProviderMock!
    private var mapper: RequestMoneyContactPickerMapperMock!
    private let scheduler: AnySchedulerOf<DispatchQueue> = .immediate

    override func setUp() {
        super.setUp()
        contactListPagePublisherFactory = ContactListPagePublisherFactoryMock()
        router = RequestMoneyContactPickerRouterMock()
        view = RequestMoneyContactPickerViewMock()
        analyticsTracker = StubAnalyticsTracker()
        notificationCenter = MockNotificationCenter()
        nudgeProvider = ContactPickerNudgeProviderMock()
        mapper = RequestMoneyContactPickerMapperMock()

        presenter = RequestMoneyContactPickerPresenterImpl(
            profile: FakePersonalProfileInfo().asProfile(),
            contactListPagePublisherFactory: contactListPagePublisherFactory,
            nudgeProvider: nudgeProvider,
            mapper: mapper,
            router: router,
            analyticsTracker: analyticsTracker,
            scheduler: scheduler,
            notificationCenter: notificationCenter
        )
    }

    override func tearDown() {
        presenter = nil
        router = nil
        contactListPagePublisherFactory = nil
        view = nil
        analyticsTracker = nil
        notificationCenter = nil

        super.tearDown()
    }
}

// MARK: - Tests

extension RequestMoneyContactPickerPresenterTests {
    func testViewInvocation_WhenPresenterStarted_ThenLoadingIsShownAndHidden() {
        contactListPagePublisherFactory.makeNextPageReturnValue = .just(ContactList.canned)
        contactListPagePublisherFactory.makeReturnValue = .just(ContactListPage.canned)

        nudgeProvider.nudge = .just(.findFriends)
        nudgeProvider.getContentForNudgeReturnValue = .just(ContactPickerNudgeModel(
            type: .findFriends,
            title: LoremIpsum.short,
            icon: .plane,
            ctaTitle: LoremIpsum.short
        ))

        mapper.makeModelReturnValue = RequestMoneyContactPickerViewModel(title: LoremIpsum.short, sections: [])

        XCTAssertFalse(view.showLoadingCalled)
        XCTAssertFalse(view.hideLoadingCalled)
        presenter.start(with: view)

        XCTAssertTrue(view.showLoadingCalled)
        XCTAssertTrue(view.hideLoadingCalled)
    }

    func testViewInvocation_GivenFailure_WhenPresenterStarted_ThenErrorAlertShown() {
        contactListPagePublisherFactory.makeNextPageReturnValue = .fail(
            with: ContactListError.invalidContext
        )
        contactListPagePublisherFactory.makeReturnValue = .just(ContactListPage.canned)

        nudgeProvider.nudge = .just(.findFriends)
        nudgeProvider.getContentForNudgeReturnValue = .just(ContactPickerNudgeModel(
            type: .findFriends,
            title: LoremIpsum.short,
            icon: .plane,
            ctaTitle: LoremIpsum.short
        ))

        mapper.makeModelReturnValue = RequestMoneyContactPickerViewModel(title: LoremIpsum.short, sections: [])

        presenter.start(with: view)

        XCTAssertTrue(
            analyticsTracker.trackedMixpanelEventNames.contains(
                "Request Flow - Contact Picker - Started"
            )
        )
        XCTAssertTrue(view.showErrorAlertCalled)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked, "Request Flow - Contact Picker - Loading Failed"
        )
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked?["Has Contacts"] as? String,
            "No"
        )
    }

    func testSelection_GivenSingleContact_WhenRequestFromAnyoneSelected_ThenRouterReceivedNoContact() {
        contactListPagePublisherFactory.makeNextPageReturnValue = .just(
            ContactList.build(
                contacts: [Contact.canned],
                nextPage: nil
            )
        )
        contactListPagePublisherFactory.makeReturnValue = .just(ContactListPage.canned)

        nudgeProvider.nudge = .just(.findFriends)
        nudgeProvider.getContentForNudgeReturnValue = .just(ContactPickerNudgeModel(
            type: .findFriends,
            title: LoremIpsum.short,
            icon: .plane,
            ctaTitle: LoremIpsum.short
        ))

        mapper.makeModelReturnValue = RequestMoneyContactPickerViewModel(title: LoremIpsum.short, sections: [])

        presenter.start(with: view)

        presenter.select(contact: nil)
        XCTAssertTrue(router.createPaymentRequestCalled)
        XCTAssertNil(router.createPaymentRequestReceivedContact)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked, "Request Flow - Contact Picker - Create Link Selected"
        )

        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked?["Has Contacts"] as? String,
            "Yes"
        )
    }

    func testSelection_GivenSingleContact_WhenTheContactIsSelected_ThenRouterReceivedTheContact() {
        let givenContact = Contact.canned
        let subject = CurrentValueSubject<ContactList, ContactListError>(
            ContactList.build(
                contacts: [givenContact],
                nextPage: nil
            )
        )
        contactListPagePublisherFactory.makeNextPageReturnValue = subject.eraseToAnyPublisher()
        contactListPagePublisherFactory.makeReturnValue = .just(ContactListPage.canned)

        nudgeProvider.nudge = .just(.findFriends)
        nudgeProvider.getContentForNudgeReturnValue = .just(ContactPickerNudgeModel(
            type: .findFriends,
            title: LoremIpsum.short,
            icon: .plane,
            ctaTitle: LoremIpsum.short
        ))

        mapper.makeModelReturnValue = RequestMoneyContactPickerViewModel(title: LoremIpsum.short, sections: [])

        presenter.start(with: view)

        presenter.select(contact: givenContact)
        XCTAssertTrue(router.createPaymentRequestCalled)
        XCTAssertEqual(
            router.createPaymentRequestReceivedContact?.title,
            givenContact.title
        )
        XCTAssertEqual(
            router.createPaymentRequestReceivedContact?.subtitle,
            givenContact.subtitle
        )
        XCTAssertEqual(
            router.createPaymentRequestReceivedContact?.id.contactId,
            givenContact.id.contactId
        )
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked, "Request Flow - Contact Picker - Contact Selected"
        )
    }

    func testDismiss() {
        presenter.dismiss()
        XCTAssertEqual(router.dismissCallsCount, 1)
    }
}

// MARK: - Notification tests

extension RequestMoneyContactPickerPresenterTests {
    func testContactsRefresh_WhenContactAdded_ThenContactsRefreshed() {
        contactListPagePublisherFactory.makeNextPageReturnValue = .just(
            ContactList.build(
                contacts: [Contact.canned],
                nextPage: nil
            )
        )

        contactListPagePublisherFactory.makeReturnValue = .just(ContactListPage.canned)

        nudgeProvider.nudge = .just(.findFriends)
        nudgeProvider.getContentForNudgeReturnValue = .just(ContactPickerNudgeModel(
            type: .findFriends,
            title: LoremIpsum.short,
            icon: .plane,
            ctaTitle: LoremIpsum.short
        ))

        mapper.makeModelReturnValue = RequestMoneyContactPickerViewModel(title: LoremIpsum.short, sections: [])

        presenter.start(with: view)
        XCTAssertFalse(view.resetCalled)
        XCTAssertFalse(view.showLoadingCalled)
        notificationCenter.post(
            Notification(name: .contactAdded)
        )
        XCTAssertTrue(view.resetCalled)
        XCTAssertTrue(view.showLoadingCalled)
    }

    func testContactsRefresh_WhenContactUpdated_ThenContactsRefreshed() {
        contactListPagePublisherFactory.makeNextPageReturnValue = .just(
            ContactList.build(
                contacts: [Contact.canned],
                nextPage: nil
            )
        )

        contactListPagePublisherFactory.makeReturnValue = .just(ContactListPage.canned)

        nudgeProvider.nudge = .just(.findFriends)
        nudgeProvider.getContentForNudgeReturnValue = .just(ContactPickerNudgeModel(
            type: .findFriends,
            title: LoremIpsum.short,
            icon: .plane,
            ctaTitle: LoremIpsum.short
        ))

        mapper.makeModelReturnValue = RequestMoneyContactPickerViewModel(title: LoremIpsum.short, sections: [])

        presenter.start(with: view)
        XCTAssertFalse(view.resetCalled)
        XCTAssertFalse(view.showLoadingCalled)
        notificationCenter.post(
            Notification(name: .contactUpdated)
        )
        XCTAssertTrue(view.resetCalled)
        XCTAssertTrue(view.showLoadingCalled)
    }

    func testContactsRefresh_WhenContactDeleted_ThenContactsRefreshed() {
        contactListPagePublisherFactory.makeNextPageReturnValue = .just(
            ContactList.build(
                contacts: [Contact.canned],
                nextPage: nil
            )
        )

        contactListPagePublisherFactory.makeReturnValue = .just(ContactListPage.canned)

        nudgeProvider.nudge = .just(.findFriends)
        nudgeProvider.getContentForNudgeReturnValue = .just(ContactPickerNudgeModel(
            type: .findFriends,
            title: LoremIpsum.short,
            icon: .plane,
            ctaTitle: LoremIpsum.short
        ))

        mapper.makeModelReturnValue = RequestMoneyContactPickerViewModel(title: LoremIpsum.short, sections: [])

        presenter.start(with: view)
        XCTAssertFalse(view.resetCalled)
        XCTAssertFalse(view.showLoadingCalled)
        notificationCenter.post(
            Notification(name: .contactDeleted)
        )
        XCTAssertTrue(view.resetCalled)
        XCTAssertTrue(view.showLoadingCalled)
    }

    func test_NudgeDismissed() {
        nudgeProvider.nudge = .just(.findFriends)
        nudgeProvider.getContentForNudgeReturnValue = .just(ContactPickerNudgeModel(
            type: .findFriends,
            title: LoremIpsum.short,
            icon: .plane,
            ctaTitle: LoremIpsum.short
        ))

        mapper.makeModelReturnValue = RequestMoneyContactPickerViewModel(title: LoremIpsum.short, sections: [])

        presenter.nudgeDismissed(nudgeType: .findFriends)

        XCTAssertEqual(
            nudgeProvider.nudgeDismissedReceivedNudge,
            .findFriends
        )
    }

    func test_inviteFriendsNudgeSelected() {
        nudgeProvider.nudge = .just(.inviteFriends)
        nudgeProvider.getContentForNudgeReturnValue = .just(ContactPickerNudgeModel(
            type: .inviteFriends,
            title: LoremIpsum.short,
            icon: .plane,
            ctaTitle: LoremIpsum.short
        ))

        presenter.inviteFriendsTapped()
        XCTAssertEqual(
            router.inviteFriendsNudgeTappedCallsCount, 1
        )
    }
}

// MARK: - Helpers

private extension RequestMoneyContactPickerPresenterTests {
    func makeListInput(page: String? = nil) -> ContactListInput {
        ContactListInput.build(
            filter: ContactListInput.Filter.notOwnedByCustomer,
            page: ContactListInput.Page.build(
                page: page,
                pageSize: 20
            ),
            context: ContactContext.parameters(
                ContactContext.Parameters(
                    action: .request,
                    sourceCurrency: nil,
                    targetCurrency: nil,
                    sourceAmount: nil,
                    targetAmount: nil,
                    amountType: nil,
                    payInMethod: nil,
                    emailRecipientEnabled: false,
                    includeExternalIdentifiers: false,
                    includeExistingContacts: true,
                    legalEntityType: nil
                )
            )
        )
    }
}
