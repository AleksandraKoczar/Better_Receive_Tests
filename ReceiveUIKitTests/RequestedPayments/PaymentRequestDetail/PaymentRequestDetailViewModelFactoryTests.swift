import Neptune
import ReceiveKit
@testable import ReceiveUIKit
import TransferResources
import TWFoundation
import TWTestingSupportKit
import WiseCore

final class PaymentRequestDetailViewModelFactoryTests: TWTestCase {
    private let paymentRequestId = PaymentRequestId("ABC")
    private let link = LoremIpsum.medium
    private let avatarUrlString = "https://wise.com/xyz"

    private var factory: PaymentRequestDetailViewModelFactoryImpl!
    private var delegate: PaymentRequestDetailViewModelDelegateMock!

    override func setUp() {
        super.setUp()
        factory = PaymentRequestDetailViewModelFactoryImpl()
        delegate = PaymentRequestDetailViewModelDelegateMock()
    }

    override func tearDown() {
        factory = nil
        delegate = nil
        super.tearDown()
    }

    func test_make_givenNoAvatar_thenReturnCorrectViewModel() throws {
        let result = try awaitPublisher(
            factory.make(
                from: makePaymentRequestDetails(),
                delegate: delegate
            )
        )
        let expectedViewModel = makeViewModel()
        expectNoDifference(result.value, expectedViewModel)
    }

    func test_make_givenHasAvatarInitials_thenReturnCorrectViewModel() throws {
        let result = try awaitPublisher(
            factory.make(
                from: makePaymentRequestDetails(
                    avatar: .initials(value: LoremIpsum.veryShort)
                ),
                delegate: delegate
            )
        )
        let avatarViewModel = AvatarViewModel.initials(
            Initials(value: LoremIpsum.veryShort),
            badge: Icons.check.image
        )
        let expectedViewModel = makeViewModel(avatarViewModel: avatarViewModel)
        expectNoDifference(result.value, expectedViewModel)
    }

    func test_make_givenHasAvatarUrl_thenReturnCorrectViewModel() throws {
        let avatarViewModel = AvatarViewModel.image(
            UIImage(),
            badge: Icons.check.image
        )
        delegate.fetchAvatarViewModelReturnValue = .just(avatarViewModel)

        let result = try awaitPublisher(
            factory.make(
                from: makePaymentRequestDetails(
                    avatar: .avatar(url: avatarUrlString)
                ),
                delegate: delegate
            )
        )
        let expectedViewModel = makeViewModel(avatarViewModel: avatarViewModel)
        expectNoDifference(result.value, expectedViewModel)
    }

    // MARK: - makeCancelConfirmation

    func test_makeCancelConfirmation_givenInvoiceRequestType_thenReturnCorrectViewModel() {
        let viewModel = factory.makeCancelConfirmation(
            requestType: .invoice,
            delegate: delegate
        )

        let expectedViewModel = makeCancelConfirmationSheetViewModelForInvoice()
        expectNoDifference(viewModel, expectedViewModel)
    }

    func test_makeCancelConfirmation_givenNotInvoiceRequestType_thenReturnCorrectViewModel() {
        let viewModel = factory.makeCancelConfirmation(
            requestType: .reusable,
            delegate: delegate
        )

        let expectedViewModel = makeCancelConfirmationSheetViewModelForNotInvoice()
        expectNoDifference(viewModel, expectedViewModel)
    }

    // MARK: - makeMarkAsPaidConfirmation

    @MainActor
    func test_makeMarkAsPaidConfirmation_givenInvoiceRequestType_thenReturnCorrectViewModel() {
        let viewModel = factory.makeMarkAsPaidConfirmation(
            requestType: .invoice,
            delegate: delegate
        )

        let expectedViewModel = makeMarkAsPaidConfirmationSheetViewModelForInvoice()
        expectNoDifference(viewModel, expectedViewModel)

        viewModel.primaryAction?.handler()
        XCTAssertEqual(delegate.markAsPaidConfirmedCallsCount, 1)
    }

    @MainActor
    func test_makeMarkAsPaidConfirmation_givenNotInvoiceRequestType_thenReturnCorrectViewModel() {
        let viewModel = factory.makeMarkAsPaidConfirmation(
            requestType: .reusable,
            delegate: delegate
        )

        let expectedViewModel = makeMarkAsPaidConfirmationSheetViewModelForNotInvoice()
        expectNoDifference(viewModel, expectedViewModel)

        viewModel.primaryAction?.handler()
        XCTAssertEqual(delegate.markAsPaidConfirmedCallsCount, 1)
    }

    // MARK: - Actions

    func test_make_givenMarkAsPaidAction_thenReturnCorrectViewModel() throws {
        let result = try awaitPublisher(
            factory.make(
                from: makePaymentRequestDetails(actions: [.markAsPaid]),
                delegate: delegate
            )
        )
        let expectedViewModel = makeViewModel(
            footerViewModel: .init(
                primaryAction: .init(title: L10n.PaymentRequest.Detail.Footer.markAsPaid, handler: {}),
                secondaryAction: nil,
                configuration: .positiveOnly
            )
        )
        expectNoDifference(result.value, expectedViewModel)
    }

    @MainActor
    func test_make_givenMarkAsPaidAction_callsDelegateWhenTapped() throws {
        let result = try awaitPublisher(
            factory.make(
                from: makePaymentRequestDetails(actions: [.markAsPaid]),
                delegate: delegate
            )
        )
        let viewModel = try XCTUnwrap(result.value)
        viewModel.footer?.primaryAction.trigger()

        XCTAssertEqual(delegate.markAsPaidTappedCallsCount, 1)
        XCTAssertEqual(delegate.markAsPaidTappedReceivedRequestType, PaymentRequestDetails.RequestType.canned)
    }

    func test_make_givenMarkAsPaidAndCancelActions_thenReturnCorrectViewModel() throws {
        let result = try awaitPublisher(
            factory.make(
                from: makePaymentRequestDetails(actions: [.markAsPaid, .cancel]),
                delegate: delegate
            )
        )
        let expectedViewModel = makeViewModel(
            footerViewModel: .init(
                primaryAction: .init(title: L10n.PaymentRequest.Detail.Footer.markAsPaid, handler: {}),
                secondaryAction: .init(title: L10n.PaymentRequest.Detail.Footer.cancel, handler: {}),
                configuration: .positiveAndNegative
            )
        )

        expectNoDifference(result.value, expectedViewModel)
    }

    func test_make_givenUnsortedActions_thenReturnCorrectViewModel() throws {
        let result = try awaitPublisher(
            factory.make(
                from: makePaymentRequestDetails(actions: [.cancel, .markAsPaid]),
                delegate: delegate
            )
        )
        let expectedViewModel = makeViewModel(
            footerViewModel: .init(
                primaryAction: .init(title: L10n.PaymentRequest.Detail.Footer.markAsPaid, handler: {}),
                secondaryAction: .init(title: L10n.PaymentRequest.Detail.Footer.cancel, handler: {}),
                configuration: .positiveAndNegative
            )
        )

        expectNoDifference(result.value, expectedViewModel)
    }

    func test_make_givenRequestAgainAndCancelActions_thenRequestAgainIsIgnored() throws {
        let result = try awaitPublisher(
            factory.make(
                from: makePaymentRequestDetails(actions: [.requestAgain, .cancel]),
                delegate: delegate
            )
        )
        let expectedViewModel = makeViewModel(
            footerViewModel: .init(
                primaryAction: .init(title: L10n.PaymentRequest.Detail.Footer.cancel, handler: {}),
                secondaryAction: nil,
                configuration: .negativeOnly
            )
        )

        expectNoDifference(result.value, expectedViewModel)
    }

    func test_make_givenRequestAgainActionOnly_thenThereIsNoFooter() throws {
        let result = try awaitPublisher(
            factory.make(
                from: makePaymentRequestDetails(actions: [.requestAgain]),
                delegate: delegate
            )
        )
        let viewModel = try XCTUnwrap(result.value)
        XCTAssertNil(viewModel.footer)
    }
}

// MARK: - Domain model

private extension PaymentRequestDetailViewModelFactoryTests {
    func makePaymentRequestDetails(
        avatar: PaymentRequestDetails.Avatar? = nil,
        actions: [PaymentRequestDetails.Action] = [.cancel]
    ) -> PaymentRequestDetails {
        PaymentRequestDetails.build(
            id: paymentRequestId,
            amount: Money.canned,
            title: LoremIpsum.short,
            subtitle: LoremIpsum.medium,
            icon: "urn:wise:icons:request-send",
            badge: .positive,
            avatar: avatar,
            actions: actions,
            sections: makePaymentRequestDetailsSections()
        )
    }

    func makePaymentRequestDetailsSections() -> [PaymentRequestDetailsSection] {
        [
            PaymentRequestDetailsSection.build(
                title: LoremIpsum.short,
                items: [
                    .optionItem(
                        label: LoremIpsum.short,
                        value: LoremIpsum.medium,
                        icon: "urn:wise:icons:arrow-down",
                        action: .navigateToAcquiringTransaction(
                            AcquiringTransactionId(LoremIpsum.short)
                        )
                    ),
                    .optionItem(
                        label: LoremIpsum.short,
                        value: LoremIpsum.medium,
                        icon: "urn:wise:icons:arrow-down",
                        action: .navigateToAcquiringPayment(
                            AcquiringPaymentId(LoremIpsum.short)
                        )
                    ),
                ]
            ),
            .build(
                title: LoremIpsum.short,
                items: [
                    .listItem(
                        label: LoremIpsum.short,
                        value: LoremIpsum.medium,
                        action: nil
                    ),
                    .listItem(
                        label: LoremIpsum.short,
                        value: LoremIpsum.medium,
                        action: .summaryList(
                            label: LoremIpsum.short,
                            title: LoremIpsum.short,
                            summaries: [
                                .build(
                                    icon: "urn:wise:icons:bank",
                                    title: LoremIpsum.short,
                                    description: LoremIpsum.medium
                                ),
                                .build(
                                    icon: "urn:wise:icons:card",
                                    title: LoremIpsum.short,
                                    description: LoremIpsum.medium
                                ),
                            ]
                        )
                    ),
                    .listItem(
                        label: LoremIpsum.short,
                        value: LoremIpsum.medium,
                        action: .copy(label: LoremIpsum.short)
                    ),
                    .listItem(
                        label: LoremIpsum.short,
                        value: LoremIpsum.medium,
                        action: .download(
                            label: LoremIpsum.short,
                            value: LoremIpsum.medium
                        )
                    ),
                    .listItem(
                        label: LoremIpsum.short,
                        value: LoremIpsum.medium,
                        action: .paymentLink(
                            label: LoremIpsum.short,
                            paymentLink: link
                        )
                    ),
                ]
            ),
        ]
    }
}

// MARK: - View model

private extension PaymentRequestDetailViewModelFactoryTests {
    func makeViewModel(
        avatarViewModel: AvatarViewModel = .icon(
            Icons.requestSend.image,
            badge: Icons.check.image
        ),
        footerViewModel: PaymentRequestDetailViewModel.FooterViewModel? = nil
    ) -> PaymentRequestDetailViewModel {
        let headerViewModel = PaymentRequestDetailViewModel.HeaderViewModel(
            icon: avatarViewModel,
            iconStyle: .size56.with { $0.badge = .positive() },
            title: LoremIpsum.short,
            subtitle: LoremIpsum.medium
        )
        let defaultFooterViewModel = PaymentRequestDetailViewModel.FooterViewModel(
            primaryAction: Action(
                title: L10n.PaymentRequest.Detail.Footer.cancel,
                handler: {}
            ),
            secondaryAction: nil,
            configuration: .negativeOnly
        )
        return PaymentRequestDetailViewModel(
            header: headerViewModel,
            sections: makeSectionViewModels(),
            footer: footerViewModel ?? defaultFooterViewModel
        )
    }

    func makeSectionViewModels() -> [PaymentRequestDetailViewModel.SectionViewModel] {
        [
            PaymentRequestDetailViewModel.SectionViewModel(
                header: SectionHeaderViewModel(title: LoremIpsum.short),
                items: [
                    .optionItem(
                        PaymentRequestDetailViewModel.SectionViewModel.OptionViewModel(
                            option: OptionViewModel(
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatar: .icon(Icons.arrowDown.image)
                            ),
                            onTap: {}
                        )
                    ),
                    .optionItem(
                        PaymentRequestDetailViewModel.SectionViewModel.OptionViewModel(
                            option: OptionViewModel(
                                title: LoremIpsum.short,
                                subtitle: LoremIpsum.medium,
                                avatar: .icon(Icons.arrowDown.image)
                            ),
                            onTap: {}
                        )
                    ),
                ]
            ),
            PaymentRequestDetailViewModel.SectionViewModel(
                header: SectionHeaderViewModel(title: LoremIpsum.short),
                items: [
                    .listItem(
                        LegacyListItemViewModel(
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium
                        )
                    ),
                    .listItem(
                        LegacyListItemViewModel(
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium,
                            action: Action(
                                title: LoremIpsum.short,
                                handler: {}
                            )
                        )
                    ),
                    .listItem(
                        LegacyListItemViewModel(
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium,
                            action: Action(
                                title: LoremIpsum.short,
                                handler: {}
                            )
                        )
                    ),
                    .listItem(
                        LegacyListItemViewModel(
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium,
                            action: Action(
                                title: LoremIpsum.short,
                                handler: {}
                            )
                        )
                    ),
                    .listItem(
                        LegacyListItemViewModel(
                            title: LoremIpsum.short,
                            subtitle: LoremIpsum.medium,
                            action: Action(
                                title: "Share",
                                handler: {}
                            )
                        )
                    ),
                ]
            ),
        ]
    }

    func makeCancelConfirmationSheetViewModelForInvoice() -> InfoSheetViewModel {
        InfoSheetViewModel(
            title: L10n.PaymentRequest.Detail.Cancel.Invoice.title,
            message: L10n.PaymentRequest.Detail.Cancel.Invoice.description,
            confirmAction: .init(
                title: L10n.PaymentRequest.Detail.Cancel.Invoice.cancel,
                handler: {}
            ),
            cancelAction: .init(
                title: L10n.PaymentRequest.Detail.Cancel.Invoice.back,
                handler: {}
            )
        )
    }

    func makeCancelConfirmationSheetViewModelForNotInvoice() -> InfoSheetViewModel {
        InfoSheetViewModel(
            title: L10n.PaymentRequest.Detail.Cancel.title,
            message: L10n.PaymentRequest.Detail.Cancel.description,
            confirmAction: .init(
                title: L10n.PaymentRequest.Detail.Cancel.cancel,
                handler: {}
            ),
            cancelAction: .init(
                title: L10n.PaymentRequest.Detail.Cancel.back,
                handler: {}
            )
        )
    }

    func makeMarkAsPaidConfirmationSheetViewModelForInvoice() -> InfoSheetViewModel {
        InfoSheetViewModel(
            title: L10n.PaymentRequest.Detail.MarkAsPaid.Invoice.title,
            message: L10n.PaymentRequest.Detail.MarkAsPaid.Invoice.description,
            confirmAction: .init(
                title: L10n.PaymentRequest.Detail.MarkAsPaid.confirm,
                handler: {}
            ),
            cancelAction: .init(
                title: L10n.PaymentRequest.Detail.MarkAsPaid.Invoice.back,
                handler: {}
            ),
            footer: .extended()
        )
    }

    func makeMarkAsPaidConfirmationSheetViewModelForNotInvoice() -> InfoSheetViewModel {
        InfoSheetViewModel(
            title: L10n.PaymentRequest.Detail.MarkAsPaid.title,
            message: L10n.PaymentRequest.Detail.MarkAsPaid.description,
            confirmAction: .init(
                title: L10n.PaymentRequest.Detail.MarkAsPaid.confirm,
                handler: {}
            ),
            cancelAction: .init(
                title: L10n.PaymentRequest.Detail.MarkAsPaid.back,
                handler: {}
            ),
            footer: .extended()
        )
    }
}
