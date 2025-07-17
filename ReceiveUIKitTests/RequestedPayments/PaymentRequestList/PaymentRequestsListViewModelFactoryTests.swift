import Combine
import ContactsKit
import Neptune
import ReceiveKit
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit
import TWUI
import UIKit
import UserKit
import UserKitTestingSupport
import WiseCore

final class PaymentRequestsListViewModelFactoryTests: TWTestCase {
    private let paymentRequestId = PaymentRequestId("XYZ")
    private let seekPosition = "2023-08-03T12:26:48.395873Z"
    private let avatarModel = AvatarModel.icon(Icons.requestSend.image, badge: nil)
    private let personalProfileInfo = FakePersonalProfileInfo()
    private let businessProfileInfo = FakeBusinessProfileInfo()

    private var delegate: PaymentRequestsListViewModelDelegateMock!
    private var factory: PaymentRequestsListViewModelFactoryImpl!

    override func setUp() {
        super.setUp()
        delegate = PaymentRequestsListViewModelDelegateMock()
        factory = PaymentRequestsListViewModelFactoryImpl()
    }

    override func tearDown() {
        factory = nil
        delegate = nil
        super.tearDown()
    }

    func test_makeViewModel_givenPersonalProfile_andClosestToExpiryUnpaid_thenReturnCorrectViewModel() {
        personalProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .unpaid(.closestToExpiry))
        let summaries = makePaymentRequestSummaries()
        summariesList.unpaid.closestToExpiry = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseOnly,
            profile: personalProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Payment requests",
            selectedChipIndex: 0,
            chips: makeChipsForPersonalProfile()
        )
        let expected = makeExpectedViewModelForSummariesWithSorting(
            isPersonalProfile: true,
            sectionTitle: "Closest to expiry",
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenPersonalProfile_andClosestToExpiryUnpaid_andOneGroupAndOneSummary_thenReturnCorrectViewModel() {
        personalProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .unpaid(.closestToExpiry))
        let summaries = makePaymentRequestSummariesWithOneGroupAndOneSummary()
        summariesList.unpaid.closestToExpiry = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseOnly,
            profile: personalProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Payment requests",
            selectedChipIndex: 0,
            chips: makeChipsForPersonalProfile()
        )
        let expected = makeExpectedViewModelForUnpaidSummariesWithOneGroupAndOneSummary(
            sectionTitle: "Closest to expiry",
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenPersonalProfile_andEmptySummaries_thenReturnCorrectViewModel() {
        personalProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        let summariesList = PaymentRequestSummaryList.makeInitial(state: .unpaid(.closestToExpiry))

        let result = factory.make(
            supportedPaymentRequestType: .singleUseOnly,
            profile: personalProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Payment requests",
            selectedChipIndex: 0,
            chips: makeChipsForPersonalProfile()
        )
        let expected = PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: [PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(
                title: "New",
                icon: Icons.plus.image,
                action: {}
            )],
            header: expectedHeader,
            content: .empty(
                EmptyViewModel(
                    illustrationConfiguration: .init(asset: .image(Neptune.Illustrations.sandTimer.image)),
                    message: .text("You’re not waiting on any payments right now.")
                )
            ),
            isCreatePaymentRequestHidden: false
        ))
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenPersonalProfile_andMostRecentlyRequestedUnpaid_thenReturnCorrectViewModel() {
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .unpaid(.mostRecentlyRequested))
        let summaries = makePaymentRequestSummaries()
        summariesList.unpaid.mostRecentlyRequested = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseOnly,
            profile: personalProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Payment requests",
            selectedChipIndex: 0,
            chips: makeChipsForPersonalProfile()
        )
        let expected = makeExpectedViewModelForSummariesWithSorting(
            isPersonalProfile: true,
            sectionTitle: "Most recently requested",
            isCreatePaymentRequestHidden: true,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenPersonalProfile_andPaid_thenReturnCorrectViewModel() {
        personalProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .paid)
        let summaries = makePaymentRequestSummaries()
        summariesList.paid = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseOnly,
            profile: personalProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Payment requests",
            selectedChipIndex: 1,
            chips: makeChipsForPersonalProfile()
        )
        let expected = makeExpectedViewModel(
            isPersonalProfile: true,
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenBusinessProfile_andClosestToExpiryUnpaid_thenReturnCorrectViewModel() {
        businessProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .unpaid(.closestToExpiry))
        let summaries = makePaymentRequestSummaries()
        summariesList.unpaid.closestToExpiry = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseOnly,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Payment requests",
            selectedChipIndex: 0,
            chips: makeChipsForBusinessProfile()
        )
        let expected = makeExpectedViewModelForSummariesWithSorting(
            isPersonalProfile: false,
            sectionTitle: "Closest to expiry",
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenBusinessProfile_andMostRecentlyRequestedUnpaid_thenReturnCorrectViewModel() {
        businessProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .unpaid(.mostRecentlyRequested))
        let summaries = makePaymentRequestSummaries()
        summariesList.unpaid.mostRecentlyRequested = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseOnly,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Payment requests",
            selectedChipIndex: 0,
            chips: makeChipsForBusinessProfile()
        )
        let expected = makeExpectedViewModelForSummariesWithSorting(
            isPersonalProfile: false,
            sectionTitle: "Most recently requested",
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenBusinessProfile_andPaid_thenReturnCorrectViewModel() {
        businessProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .paid)
        let summaries = makePaymentRequestSummaries()
        summariesList.paid = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseOnly,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Payment requests",
            selectedChipIndex: 1,
            chips: makeChipsForBusinessProfile()
        )
        let expected = makeExpectedViewModel(
            isPersonalProfile: false,
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenBusinessProfile_andReusablePaymentLinksEnabled_andActive_thenReturnCorrectViewModel() {
        businessProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .active)
        let summaries = makePaymentRequestSummariesForActive()
        summariesList.active = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseAndReusable,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModelForPaymentLinks(
            selectedChipIndex: 0,
            chips: makeChipsForBusinessProfileReusable()
        )
        let expected = makeExpectedViewModelForPaymentLinksActive(
            isPersonalProfile: false,
            isSectionHeaderHidden: true,
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )

        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenBusinessProfile_andReusablePaymentLinksEnabled_AndMethodsEnabled_andActive_thenReturnCorrectViewModel() {
        businessProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .active)
        let summaries = makePaymentRequestSummariesForActive()
        summariesList.active = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseAndReusable,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModelForPaymentLinks(
            selectedChipIndex: 0,
            chips: makeChipsForBusinessProfileReusable()
        )
        let expected = makeExpectedViewModelForPaymentLinksActiveWithSettingsButton(
            isSectionHeaderHidden: true,
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenPersonalProfile__AndMethodsEnabled_andActive_thenReturnCorrectViewModel() {
        personalProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .unpaid(.closestToExpiry))
        let summaries = makePaymentRequestSummaries()
        summariesList.unpaid.closestToExpiry = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseOnly,
            profile: personalProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Payment requests",
            selectedChipIndex: 0,
            chips: makeChipsForPersonalProfile()
        )
        let expected = makeExpectedViewModelForSummariesWithSorting(
            isPersonalProfile: true,
            sectionTitle: "Closest to expiry",
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenBusinessProfile_andReusablePaymentLinksEnabled_andInactive_thenReturnCorrectViewModel() {
        businessProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .inactive)
        let summaries = makePaymentRequestSummariesForInactive()
        summariesList.inactive = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseAndReusable,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModelForPaymentLinks(
            selectedChipIndex: 1,
            chips: makeChipsForBusinessProfileReusable()
        )
        let expected = makeExpectedViewModelForPaymentLinksInactive(
            isSectionHeaderHidden: true,
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )

        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenBusinessProfile_andReusablePaymentLinksEnabled_andInactiveWithMultipleSections_thenReturnCorrectViewModel() {
        businessProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .inactive)
        let summaries = makePaymentRequestSummariesForInactiveWithMultipleSections()
        summariesList.inactive = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseAndReusable,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModelForPaymentLinks(
            selectedChipIndex: 1,
            chips: makeChipsForBusinessProfileReusable()
        )
        let expected = makeExpectedViewModelForPaymentLinksInactiveMultipleSections(
            isSectionHeaderHidden: false,
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenBusinessProfile_andReusablePaymentLinksEnabled_andActiveWithMultipleSections_thenReturnCorrectViewModel() {
        businessProfileInfo.addPrivilege(PaymentRequestPrivilege.create)
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .inactive)
        let summaries = makePaymentRequestSummariesForActiveWithMultipleSections()
        summariesList.inactive = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .singleUseAndReusable,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModelForPaymentLinks(
            selectedChipIndex: 1,
            chips: makeChipsForBusinessProfileReusable()
        )
        let expected = makeExpectedViewModelForPaymentLinksActiveMultipleSections(
            isPersonalProfile: false,
            isSectionHeaderHidden: false,
            isCreatePaymentRequestHidden: false,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenSupportInvoices_andClosestToExpiryUpcoming_thenReturnCorrectViewModel() {
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .upcoming(.closestToExpiry))
        let summaries = makePaymentRequestSummaries()
        summariesList.upcoming.closestToExpiry = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .invoiceOnly,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Invoices",
            selectedChipIndex: 0,
            chips: makeChipsForInvoices()
        )
        let expected = makeExpectedViewModelForSummariesWithSorting(
            isPersonalProfile: false,
            sectionTitle: "Closest to expiry",
            isCreatePaymentRequestHidden: true,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenSupportInvoices_andMostRecentlyRequestedUpcoming_thenReturnCorrectViewModel() {
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .upcoming(.mostRecentlyRequested))
        let summaries = makePaymentRequestSummaries()
        summariesList.upcoming.mostRecentlyRequested = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .invoiceOnly,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Invoices",
            selectedChipIndex: 0,
            chips: makeChipsForInvoices()
        )
        let expected = makeExpectedViewModelForSummariesWithSorting(
            isPersonalProfile: false,
            sectionTitle: "Most recently requested",
            isCreatePaymentRequestHidden: true,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeViewModel_givenSupportInvoices_andPast_thenReturnCorrectViewModel() {
        var summariesList = PaymentRequestSummaryList.makeInitial(state: .past)
        let summaries = makePaymentRequestSummaries()
        summariesList.past = summaries
        delegate.fetchAvatarModelReturnValue = .just(avatarModel)

        let result = factory.make(
            supportedPaymentRequestType: .invoiceOnly,
            profile: businessProfileInfo.asProfile(),
            paymentRequestSummaryList: summariesList,
            delegate: delegate
        )

        let expectedHeader = makeExpectedHeaderViewModel(
            title: "Invoices",
            selectedChipIndex: 1,
            chips: makeChipsForInvoices()
        )
        let expected = makeExpectedViewModel(
            isPersonalProfile: false,
            isCreatePaymentRequestHidden: true,
            headerViewModel: expectedHeader,
            avatarModel: .just(avatarModel)
        )
        expectNoDifference(result, expected)
    }

    func test_makeRadioOptionsViewModel_givenClosestToExpiryIsVisible_thenReturnCorrectViewModel() {
        let result = factory.makeRadioOptionsViewModel(
            sortingState: .closestToExpiry,
            delegate: PaymentRequestsListViewModelDelegateMock()
        )

        let expected = makeExpectedRadioOptionsViewModel(isClosestToExpirySelected: true)
        expectNoDifference(result, expected)
    }

    func test_makeRadioOptionsViewModel_givenMostRecentlyRequestedIsVisible_thenReturnCorrectViewModel() {
        let result = factory.makeRadioOptionsViewModel(
            sortingState: .mostRecentlyRequested,
            delegate: PaymentRequestsListViewModelDelegateMock()
        )

        let expected = makeExpectedRadioOptionsViewModel(isClosestToExpirySelected: false)
        expectNoDifference(result, expected)
    }

    func testMakeGlobalEmptyState_GivenSingleUseAndReuseable() {
        let result = factory.makeGlobalEmptyState(
            supportedPaymentRequestType: .singleUseAndReusable,
            delegate: delegate
        )

        let expected = PaymentRequestsListViewModel.emptyState(.init(
            illustration: .image(Illustrations.multiCurrency.image),
            title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.title,
            summaries: [
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.CreateSend.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentLink.CreateSend.description,
                    icon: Icons.link.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.ReuseRepeat.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentLink.ReuseRepeat.description,
                    icon: Icons.reload.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.Fast.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentLink.Fast.description,
                    icon: Icons.lightningBolt.image,
                ),
            ],
            primaryButton: .init(title: L10n.PaymentRequest.List.Empty.Global.PaymentLink.createPaymentLink) {},
            secondaryButton: .init(title: NeptuneLocalization.Button.Title.learnMore) {}
        ))

        XCTAssertEqual(result, expected)
    }

    func testMakeGlobalEmptyState_GivenSingleUseOnly() {
        let result = factory.makeGlobalEmptyState(
            supportedPaymentRequestType: .singleUseOnly,
            delegate: delegate
        )

        let expected = PaymentRequestsListViewModel.emptyState(.init(
            illustration: .image(Illustrations.multiCurrency.image),
            title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.title,
            summaries: [
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Easy.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Easy.description,
                    icon: Icons.requestReceive.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Customize.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Customize.description,
                    icon: Icons.list.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Fast.title,
                    description: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.Fast.description,
                    icon: Icons.lightningBolt.image,
                ),
            ],
            primaryButton: .init(title: L10n.PaymentRequest.List.Empty.Global.PaymentRequest.requestPayment) {},
            secondaryButton: .init(title: NeptuneLocalization.Button.Title.learnMore) {}
        ))

        XCTAssertEqual(result, expected)
    }

    func testMakeGlobalEmptyState_GivenInvoiceOnly() {
        let result = factory.makeGlobalEmptyState(
            supportedPaymentRequestType: .invoiceOnly,
            delegate: delegate
        )

        let expected = PaymentRequestsListViewModel.emptyState(.init(
            illustration: .image(Illustrations.documents.image),
            title: L10n.PaymentRequest.List.Empty.Global.Invoice.title,
            summaries: [
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.Invoice.Fast.title,
                    description: L10n.PaymentRequest.List.Empty.Global.Invoice.Fast.description,
                    icon: Icons.documents.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.Invoice.GlobalLocal.title,
                    description: L10n.PaymentRequest.List.Empty.Global.Invoice.GlobalLocal.description,
                    icon: Icons.globe.image,
                ),
                SummaryViewModel(
                    title: L10n.PaymentRequest.List.Empty.Global.Invoice.Track.title,
                    description: L10n.PaymentRequest.List.Empty.Global.Invoice.Track.description,
                    icon: Icons.payments.image,
                ),
            ],
            primaryButton: .init(title: L10n.PaymentRequest.List.Empty.Global.Invoice.createInvoice) {},
            secondaryButton: .init(title: NeptuneLocalization.Button.Title.learnMore) {}
        ))

        XCTAssertEqual(result, expected)
    }
}

// MARK: - Domain model

private extension PaymentRequestsListViewModelFactoryTests {
    func makePaymentRequestSummaries() -> PaymentRequestSummaries {
        PaymentRequestSummaries.build(
            groups: [
                PaymentRequestSummaries.Group.build(
                    id: LoremIpsum.veryShort,
                    label: LoremIpsum.short,
                    summaries: [
                        PaymentRequestSummaries.Group.Summary.build(
                            id: LoremIpsum.veryShort,
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium,
                            icon: "urn:wise:icons:request-send",
                            avatar: .avatar(urlString: LoremIpsum.medium),
                            badge: .warning
                        ),
                        PaymentRequestSummaries.Group.Summary.build(
                            id: LoremIpsum.veryShort,
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium,
                            icon: "urn:wise:icons:request-send",
                            badge: .positive
                        ),
                    ]
                ),
                PaymentRequestSummaries.Group.build(
                    id: LoremIpsum.short,
                    label: LoremIpsum.short,
                    summaries: [
                        PaymentRequestSummaries.Group.Summary.build(
                            id: paymentRequestId.value,
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium,
                            icon: "urn:wise:icons:request-send",
                            avatar: .initials(value: LoremIpsum.veryShort),
                            badge: nil
                        ),
                    ]
                ),
            ],
            nextPageState: .hasNextPage(seekPosition: seekPosition)
        )
    }

    func makePaymentRequestSummariesForActive() -> PaymentRequestSummaries {
        PaymentRequestSummaries.build(
            groups: [
                PaymentRequestSummaries.Group.build(
                    id: "Active",
                    label: "Active",
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

    func makePaymentRequestSummariesForInactive() -> PaymentRequestSummaries {
        PaymentRequestSummaries.build(
            groups: [
                PaymentRequestSummaries.Group.build(
                    id: "Inactive",
                    label: "Inactive",
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

    func makePaymentRequestSummariesForInactiveWithMultipleSections() -> PaymentRequestSummaries {
        PaymentRequestSummaries.build(
            groups: [
                PaymentRequestSummaries.Group.build(
                    id: "Inactive",
                    label: "Inactive",
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
                PaymentRequestSummaries.Group.build(
                    id: "Inactive",
                    label: "Inactive",
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

    func makePaymentRequestSummariesForActiveWithMultipleSections() -> PaymentRequestSummaries {
        PaymentRequestSummaries.build(
            groups: [
                PaymentRequestSummaries.Group.build(
                    id: "Active",
                    label: "Active",
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
                PaymentRequestSummaries.Group.build(
                    id: "Active",
                    label: "Active",
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

    func makePaymentRequestSummariesWithOneGroupAndOneSummary() -> PaymentRequestSummaries {
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

// MARK: - Expected view model

private extension PaymentRequestsListViewModelFactoryTests {
    func makeChipsForPersonalProfile() -> [String] {
        [
            "Unpaid",
            "Paid",
        ]
    }

    func makeChipsForBusinessProfile() -> [String] {
        [
            "Active",
            "Inactive",
        ]
    }

    func makeChipsForBusinessProfileReusable() -> [String] {
        [
            "Active",
            "Inactive",
        ]
    }

    func makeChipsForInvoices() -> [String] {
        [
            "Upcoming",
            "Past",
        ]
    }

    func makeExpectedHeaderViewModel(
        title: String,
        selectedChipIndex: Int,
        chips: [String]
    ) -> PaymentRequestsListHeaderView.ViewModel {
        PaymentRequestsListHeaderView.ViewModel(
            title: LargeTitleViewModel(title: title),
            segmentedControl: SegmentedControlView.ViewModel(
                segments: chips,
                selectedIndex: selectedChipIndex,
                onChange: { _ in }
            )
        )
    }

    func makeExpectedHeaderViewModelForPaymentLinks(
        selectedChipIndex: Int,
        chips: [String]
    ) -> PaymentRequestsListHeaderView.ViewModel {
        PaymentRequestsListHeaderView.ViewModel(
            title: LargeTitleViewModel(title: "Payment links"),
            segmentedControl: SegmentedControlView.ViewModel(
                segments: chips,
                selectedIndex: selectedChipIndex,
                onChange: { _ in }
            )
        )
    }

    func makeAvatarPublisherForAvatar(
        avatarModel: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> AvatarPublisher {
        AvatarPublisher.image(
            avatarPublisher: avatarModel
        )
    }

    func makeAvatarPublisherForNoAvatar(
        icon: UIImage,
        badge: UIImage?
    ) -> AvatarPublisher {
        AvatarPublisher.image(
            avatarPublisher: .just(
                AvatarModel.icon(icon, badge: badge)
            )
        )
    }

    func makeAvatarPublisherForInitials(
        badge: UIImage?
    ) -> AvatarPublisher {
        AvatarPublisher.initials(
            avatarPublisher: .just(
                AvatarModel.initials(
                    Initials(value: LoremIpsum.veryShort),
                    badge: badge
                )
            ),
            gradientPublisher: .just(.none)
        )
    }

    func makeExpectedViewModelForSummariesWithSorting(
        isPersonalProfile: Bool,
        sectionTitle: String,
        isCreatePaymentRequestHidden: Bool,
        headerViewModel: PaymentRequestsListHeaderView.ViewModel,
        avatarModel: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> PaymentRequestsListViewModel {
        var buttons: [PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel] = []
        if isPersonalProfile {
            buttons = [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
            ]
        } else {
            buttons = [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: nil, icon: Icons.slider.image, action: {}),
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
            ]
        }

        return PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: buttons,
            header: headerViewModel,
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: sectionTitle,
                        viewModel: SectionHeaderViewModel(
                            title: sectionTitle,
                            action: Action(
                                title: "Sort",
                                handler: {}
                            ),
                            accessibilityHint: sectionTitle
                        ),
                        isSectionHeaderHidden: false,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: LoremIpsum.veryShort,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForAvatar(avatarModel: avatarModel)
                            ),
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: LoremIpsum.veryShort,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .positive() },
                                avatarPublisher: makeAvatarPublisherForNoAvatar(
                                    icon: Icons.requestSend.image,
                                    badge: Icons.alert.image
                                )
                            ),
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48,
                                avatarPublisher: makeAvatarPublisherForInitials(
                                    badge: Icons.alert.image
                                )
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: isCreatePaymentRequestHidden
        ))
    }

    func makeExpectedViewModelForUnpaidSummariesWithOneGroupAndOneSummary(
        sectionTitle: String,
        isCreatePaymentRequestHidden: Bool,
        headerViewModel: PaymentRequestsListHeaderView.ViewModel
    ) -> PaymentRequestsListViewModel {
        PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: [PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(
                title: "New",
                icon: Icons.plus.image,
                action: {}
            )],
            header: headerViewModel,
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: sectionTitle,
                        viewModel: SectionHeaderViewModel(
                            title: sectionTitle,
                            action: Action(
                                title: "Sort",
                                handler: {}
                            ),
                            accessibilityHint: sectionTitle
                        ),
                        isSectionHeaderHidden: true,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForNoAvatar(
                                    icon: Icons.requestSend.image,
                                    badge: Icons.alert.image
                                )
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: isCreatePaymentRequestHidden
        ))
    }

    func makeExpectedViewModelForPaymentLinksActive(
        isPersonalProfile: Bool,
        isSectionHeaderHidden: Bool,
        isCreatePaymentRequestHidden: Bool,
        headerViewModel: PaymentRequestsListHeaderView.ViewModel,
        avatarModel: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> PaymentRequestsListViewModel {
        var buttons: [PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel] = []
        if isPersonalProfile {
            buttons = [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
            ]
        } else {
            buttons = [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: nil, icon: Icons.slider.image, action: {}),
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
            ]
        }

        return PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: buttons,
            header: headerViewModel,
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: "Active",
                        viewModel: SectionHeaderViewModel(
                            title: "Active",
                            accessibilityHint: "Active"
                        ),
                        isSectionHeaderHidden: isSectionHeaderHidden,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForAvatar(avatarModel: avatarModel)
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: false
        ))
    }

    func makeExpectedViewModelForPaymentLinksActiveWithSettingsButton(
        isSectionHeaderHidden: Bool,
        isCreatePaymentRequestHidden: Bool,
        headerViewModel: PaymentRequestsListHeaderView.ViewModel,
        avatarModel: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> PaymentRequestsListViewModel {
        PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: nil, icon: Icons.slider.image, action: {}),
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
            ],
            header: headerViewModel,
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: "Active",
                        viewModel: SectionHeaderViewModel(
                            title: "Active",
                            accessibilityHint: "Active"
                        ),
                        isSectionHeaderHidden: isSectionHeaderHidden,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForAvatar(avatarModel: avatarModel)
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: false
        ))
    }

    func makeExpectedViewModelForPaymentLinksInactive(
        isSectionHeaderHidden: Bool,
        isCreatePaymentRequestHidden: Bool,
        headerViewModel: PaymentRequestsListHeaderView.ViewModel,
        avatarModel: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> PaymentRequestsListViewModel {
        let buttons = [
            PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: nil, icon: Icons.slider.image, action: {}),
            PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
        ]
        return PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: buttons,
            header: headerViewModel,
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: "Inactive",
                        viewModel: SectionHeaderViewModel(
                            title: "Inactive",
                            accessibilityHint: "Inactive"
                        ),
                        isSectionHeaderHidden: isSectionHeaderHidden,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForAvatar(avatarModel: avatarModel)
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: false
        ))
    }

    func makeExpectedViewModelForPaymentLinksActiveMultipleSections(
        isPersonalProfile: Bool,
        isSectionHeaderHidden: Bool,
        isCreatePaymentRequestHidden: Bool,
        headerViewModel: PaymentRequestsListHeaderView.ViewModel,
        avatarModel: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> PaymentRequestsListViewModel {
        var buttons: [PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel] = []
        if isPersonalProfile {
            buttons = [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
            ]
        } else {
            buttons = [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: nil, icon: Icons.slider.image, action: {}),
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
            ]
        }
        return PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: buttons,
            header: headerViewModel,
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: "Active",
                        viewModel: SectionHeaderViewModel(
                            title: "Active",
                            accessibilityHint: "Active"
                        ),
                        isSectionHeaderHidden: isSectionHeaderHidden,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForAvatar(avatarModel: avatarModel)
                            ),
                        ]
                    ),
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: "Active",
                        viewModel: SectionHeaderViewModel(
                            title: "Active",
                            accessibilityHint: "Active"
                        ),
                        isSectionHeaderHidden: isSectionHeaderHidden,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForAvatar(avatarModel: avatarModel)
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: false
        ))
    }

    func makeExpectedViewModelForPaymentLinksInactiveMultipleSections(
        isSectionHeaderHidden: Bool,
        isCreatePaymentRequestHidden: Bool,
        headerViewModel: PaymentRequestsListHeaderView.ViewModel,
        avatarModel: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> PaymentRequestsListViewModel {
        let buttons = [
            PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: nil, icon: Icons.slider.image, action: {}),
            PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
        ]
        return PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: buttons,
            header: headerViewModel,
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: "Inactive",
                        viewModel: SectionHeaderViewModel(
                            title: "Inactive",
                            accessibilityHint: "Inactive"
                        ),
                        isSectionHeaderHidden: isSectionHeaderHidden,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForAvatar(avatarModel: avatarModel)
                            ),
                        ]
                    ),
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: "Inactive",
                        viewModel: SectionHeaderViewModel(
                            title: "Inactive",
                            accessibilityHint: "Inactive"
                        ),
                        isSectionHeaderHidden: isSectionHeaderHidden,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForAvatar(avatarModel: avatarModel)
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: false
        ))
    }

    func makeExpectedViewModel(
        isPersonalProfile: Bool,
        isCreatePaymentRequestHidden: Bool,
        headerViewModel: PaymentRequestsListHeaderView.ViewModel,
        avatarModel: AnyPublisher<ContactsKit.AvatarModel, Never>
    ) -> PaymentRequestsListViewModel {
        var buttons: [PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel] = []
        if isPersonalProfile {
            buttons = [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
            ]
        } else {
            buttons = [
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: nil, icon: Icons.slider.image, action: {}),
                PaymentRequestsListViewModel.PaymentRequests.ButtonViewModel(title: "New", icon: Icons.plus.image, action: {}),
            ]
        }

        return PaymentRequestsListViewModel.paymentRequests(.init(
            navigationBarButtons: buttons,
            header: headerViewModel,
            content: .sections(
                [
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: LoremIpsum.veryShort,
                        viewModel: SectionHeaderViewModel(
                            title: LoremIpsum.short,
                            accessibilityHint: LoremIpsum.short
                        ),
                        isSectionHeaderHidden: false,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: LoremIpsum.veryShort,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .warning() },
                                avatarPublisher: makeAvatarPublisherForAvatar(avatarModel: avatarModel)
                            ),
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: LoremIpsum.veryShort,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48.with { $0.badge = .positive() },
                                avatarPublisher: makeAvatarPublisherForNoAvatar(
                                    icon: Icons.requestSend.image,
                                    badge: Icons.alert.image
                                )
                            ),
                        ]
                    ),
                    PaymentRequestsListViewModel.PaymentRequests.Section(
                        id: LoremIpsum.short,
                        viewModel: SectionHeaderViewModel(
                            title: LoremIpsum.short,
                            accessibilityHint: LoremIpsum.short
                        ),
                        isSectionHeaderHidden: false,
                        rows: [
                            PaymentRequestsListViewModel.PaymentRequests.Section.Row(
                                id: paymentRequestId.value,
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatarStyle: .size48,
                                avatarPublisher: makeAvatarPublisherForInitials(
                                    badge: Icons.alert.image
                                )
                            ),
                        ]
                    ),
                ]
            ),
            isCreatePaymentRequestHidden: isCreatePaymentRequestHidden
        ))
    }
}

// MARK: - Radio options

private extension PaymentRequestsListViewModelFactoryTests {
    func makeExpectedRadioOptionsViewModel(
        isClosestToExpirySelected: Bool
    ) -> PaymentRequestsListRadioOptionsViewModel {
        PaymentRequestsListRadioOptionsViewModel(
            title: "Sort by",
            options: [
                RadioOptionViewModel(
                    model: OptionViewModel(title: "Closest to expiry"),
                    isSelected: isClosestToExpirySelected
                ),
                RadioOptionViewModel(
                    model: OptionViewModel(title: "Most recently requested"),
                    isSelected: !isClosestToExpirySelected
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
