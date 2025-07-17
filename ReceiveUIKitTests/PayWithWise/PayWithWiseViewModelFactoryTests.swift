import BalanceKit
import BalanceKitTestingSupport
import ContactsKit
import ContactsKitTestingSupport
import Foundation
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport
import WiseCore

final class PayWithWiseViewModelFactoryTests: TWTestCase {
    private var factory: PayWithWiseViewModelFactoryImpl!
    private var balanceFormatter: MockBalanceFormatter!

    override func setUp() {
        super.setUp()

        balanceFormatter = MockBalanceFormatter()
        factory = PayWithWiseViewModelFactoryImpl(
            balanceFormatter: balanceFormatter
        )
    }

    override func tearDown() {
        balanceFormatter = nil
        factory = nil

        super.tearDown()
    }
}

// MARK: - Make view model

extension PayWithWiseViewModelFactoryTests {
    func testCreation_GivenDefaults_ThenValuesMatch() throws {
        let viewModel = try makeViewModel(source: .paymentKey(.request(paymentKey: ""))).loaded

        expectNoDifference(
            viewModel.footer?.firstButton.title,
            "Pay 10\u{00A0}PLN"
        )
        XCTAssertEqual(
            viewModel.footer?.secondButton?.title,
            "Pay another way"
        )
    }

    func testTitleCreation_GivenRequesterName_ThenTheTitleHasTheCorrectValeu() throws {
        let viewModel = try makeViewModel(
            paymentRequestLookup: PaymentRequestLookup.build(
                amount: .build(currency: .PLN, value: 10.0)
            )
        ).loaded

        expectNoDifference(
            viewModel.header.title.title.text,
            "10\u{00A0}PLN"
        )
    }

    func testProfileSectionCreation_GivenProfileInfo_ThenSectionHasTheCorrectInfo() throws {
        let profile = {
            let info = FakePersonalProfileInfo()
            info.firstName = "Jane"
            info.lastName = "Doe"
            return info.asProfile()
        }()

        let viewModel = try makeViewModel(
            supportsProfileChange: true,
            profile: profile
        ).loaded

        XCTAssertEqual(
            viewModel.paymentSection?.sectionOptions[0].option.title,
            "Jane Doe"
        )

        XCTAssertEqual(
            viewModel.paymentSection?.sectionOptions[0].option.subtitle?.text,
            "Personal account"
        )
    }

    func testBalanceSectionCreation_GivenBalance_ThenSectionHasTheCorrectInfo() throws {
        let viewModel = try makeViewModel(
            selectedBalance: Balance.build(
                availableAmount: 100,
                currency: .GBP
            )
        ).loaded

        XCTAssertEqual(
            viewModel.paymentSection?.sectionOptions[0].option.title,
            "100 GBP available"
        )

        XCTAssertEqual(
            viewModel.paymentSection?.sectionOptions[0].option.subtitle?.text,
            "British Pound"
        )
    }

    func testFooterCreation_GivenContactRequest_ThenButtonHasTheCorrectTitle() throws {
        let viewModel = try makeViewModel(
            source: .paymentKey(
                .contact(
                    paymentKey: ""
                )
            )
        ).loaded

        XCTAssertEqual(
            viewModel.footer?.secondButton?.title,
            "Decline request"
        )
    }

    func testFooterCreation_GivenAlertIsNil_thenPaymentButtonsEnabled() throws {
        let viewModel = try makeViewModelForQuickpay(
            inlineAlert: nil,
            supportsProfileChange: false,
            supportedPaymentMethods: [.canned]
        ).loaded

        XCTAssertEqual(
            viewModel.footer?.firstButton.isEnabled,
            true
        )

        XCTAssertEqual(
            viewModel.footer?.secondButton?.isEnabled,
            true
        )
    }

    func testFooterCreation_GivenAlertIsNotNil_thenPaymentButtonsDisabled() throws {
        let viewModel = try makeViewModelForQuickpay(
            inlineAlert: .build(viewModel: .canned, style: .negative),
            supportsProfileChange: false,
            supportedPaymentMethods: [.canned]
        ).loaded

        XCTAssertEqual(
            viewModel.footer?.firstButton.isEnabled,
            false
        )

        XCTAssertEqual(
            viewModel.footer?.secondButton?.isEnabled,
            true
        )
    }

    func testFooterCreation_GivenQuoteAndLookupAmounts_ThenQuoteAmountIsUsed() throws {
        let viewModel = try makeViewModel(
            paymentRequestLookup: PaymentRequestLookup.build(
                amount: Money.build(
                    currency: .GBP,
                    value: 1
                )
            ),
            quote: PayWithWiseQuote.build(
                sourceAmount: Money.build(
                    currency: .EUR,
                    value: 5
                )
            )
        ).loaded

        expectNoDifference(
            viewModel.footer?.firstButton.title,
            "Pay 5\u{00A0}EUR"
        )
    }
}

// MARK: - Make balance options container

extension PayWithWiseViewModelFactoryTests {
    func testBalanceOptionsContainerCreation_GivenBalances_ThenCorrectIdsFiltered() {
        let container = factory.makeBalanceOptionsContainer(
            fundableBalances: [
                Balance.build(id: BalanceId(1), currency: .GBP),
                .build(id: BalanceId(2), currency: .EUR),
            ],
            balances: [
                Balance.build(id: BalanceId(4), currency: .TRY),
                .build(id: BalanceId(2), currency: .EUR),
                .build(id: BalanceId(5), currency: .AUD),
                .build(id: BalanceId(1), currency: .GBP),
                .build(id: BalanceId(7), currency: .NZD),
            ]
        )
        let fundableIds = container.fundables.map { $0.id.value }
        let nonFundableIds = container.nonFundables.map { $0.id.value }

        XCTAssertEqual(fundableIds, [1, 2])
        XCTAssertEqual(nonFundableIds, [4, 5, 7])
    }
}

// MARK: - Make balance sections

extension PayWithWiseViewModelFactoryTests {
    func testBalanceSectionsCreation_GivenDifferentBalanceOptions_ThenSectionCreatedCorrectly() {
        let expectedTitle = "Balance"
        let container = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build(
            fundables: [],
            nonFundables: [
                PayWithWiseViewModelFactoryImpl.BalanceOption.build(
                    viewModel: OptionViewModel(
                        title: expectedTitle
                    )
                ),
            ]
        )

        let sections = factory.makeBalanceSections(
            container: container
        )

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(
            sections.first?.options.first?.title,
            expectedTitle
        )

        let container2 = PayWithWiseViewModelFactoryImpl.BalanceOptionsContainer.build(
            fundables: [
                PayWithWiseViewModelFactoryImpl.BalanceOption.build(
                    viewModel: OptionViewModel(
                        title: expectedTitle
                    )
                ),
            ],
            nonFundables: [
                .canned,
            ]
        )

        let sections2 = factory.makeBalanceSections(
            container: container2
        )

        XCTAssertEqual(sections2.count, 2)
        XCTAssertEqual(
            sections.first?.options.first?.title,
            expectedTitle
        )
        XCTAssertEqual(
            sections2.first?.options.first?.title,
            expectedTitle
        )
    }
}

// MARK: - Make empty state

extension PayWithWiseViewModelFactoryTests {
    func testEmptyStateCreation_GivenEmptyStateWithTitleAndMessage_ThenGivenValuesShown() throws {
        let expectedTitle = "Title"
        let expectedMessage = "Message"
        let viewModel = try factory.makeEmptyStateViewModel(
            image: UIImage.actions,
            title: expectedTitle,
            message: expectedMessage,
            buttonAction: Action(title: "", handler: {})
        ).empty

        XCTAssertEqual(
            viewModel.title,
            expectedTitle
        )
        XCTAssertEqual(
            viewModel.message,
            expectedMessage
        )
    }
}

// MARK: - Make alert

extension PayWithWiseViewModelFactoryTests {
    func testInlineAlertCreation_GivenFieldInfo_ThenFieldInfoMatches() {
        let expectedMessage = "Msg"
        let expectedStyle = InlineAlertStyle.neutral
        let inlineAlert = factory.makeAlertViewModel(
            message: expectedMessage,
            style: expectedStyle,
            action: nil
        )

        XCTAssertEqual(inlineAlert.viewModel.message.text, expectedMessage)
        XCTAssertEqual(inlineAlert.style, expectedStyle)
    }
}

// MARK: - Make breakdown

extension PayWithWiseViewModelFactoryTests {
    func testBreakdownCreation_GivenSameCurrencyPayment_ThenBreakdownItemsIsNotEmpty() throws {
        let expectedBreakdownItems = [
            BreakdownRowModel.build(
                accessoryType: .circle,
                primaryText: "15\u{00A0}GBP",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.requestedAmount,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .divide,
                primaryText: "1",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.rate,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .plus,
                primaryText: "0\u{00A0}GBP",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.fees,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .equals,
                primaryText: "15\u{00A0}GBP",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.youPay,
                secondaryMarkupTag: .secondary
            ),
        ]

        let viewModel = makeViewModel(
            paymentRequestLookup: PaymentRequestLookup.build(
                amount: Money.build(
                    currency: .GBP,
                    value: 15
                )
            ),
            quote: PayWithWiseQuote.build(
                sourceAmount: Money.build(
                    currency: .GBP,
                    value: 15
                ),
                rate: 1,
                fee: PayWithWiseQuote.Fee.build(
                    total: 0
                )
            )
        )

        XCTAssertEqual(try viewModel.loaded.breakdownItems, expectedBreakdownItems)
    }

    func testBreakdownCreation_GivenCrossCurrencyPaymentZeroDiscount_ThenBreakdownItemsExist() throws {
        let expectedBreakdownItems = [
            BreakdownRowModel.build(
                accessoryType: .circle,
                primaryText: "15\u{00A0}EUR",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.requestedAmount,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .divide,
                primaryText: "1.2",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.rate,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .plus,
                primaryText: "0.80\u{00A0}GBP",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.fees,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .equals,
                primaryText: "20\u{00A0}GBP",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.youPay,
                secondaryMarkupTag: .secondary
            ),
        ]
        let viewModel = makeViewModel(
            paymentRequestLookup: PaymentRequestLookup.build(
                amount: Money.build(
                    currency: .EUR,
                    value: 15
                )
            ),
            quote: PayWithWiseQuote.build(
                sourceAmount: Money.build(
                    currency: .GBP,
                    value: 20
                ),
                rate: 1.2,
                fee: PayWithWiseQuote.Fee.build(
                    total: 0.8
                )
            )
        )

        expectNoDifference(
            try viewModel.loaded.breakdownItems,
            expectedBreakdownItems
        )
    }

    func testBreakdownCreation_GivenCrossCurrencyPaymentDiscount_ThenBreakdownItemsExist() throws {
        let expectedBreakdownItems = [
            BreakdownRowModel.build(
                accessoryType: .circle,
                primaryText: "15\u{00A0}EUR",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.requestedAmount,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .divide,
                primaryText: "1.2",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.rate,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .plus,
                primaryText: "1\u{00A0}GBP",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.conversionFee,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .minus,
                primaryText: "0.20\u{00A0}GBP",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.discount,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .circle,
                primaryText: "0.80\u{00A0}GBP",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.totalFee,
                secondaryMarkupTag: .secondary
            ),
            .init(
                accessoryType: .equals,
                primaryText: "20\u{00A0}GBP",
                secondaryText: L10n.PayWithWise.Payment.Payment.Breakdown.Section.youPay,
                secondaryMarkupTag: .secondary
            ),
        ]
        let viewModel = makeViewModel(
            paymentRequestLookup: PaymentRequestLookup.build(
                amount: Money.build(
                    currency: .EUR,
                    value: 15
                )
            ),
            quote: PayWithWiseQuote.build(
                sourceAmount: Money.build(
                    currency: .GBP,
                    value: 20
                ),
                rate: 1.2,
                fee: PayWithWiseQuote.Fee.build(
                    conversion: 1.0,
                    discount: 0.2,
                    total: 0.8
                )
            )
        )

        expectNoDifference(
            try viewModel.loaded.breakdownItems,
            expectedBreakdownItems
        )
    }
}

// MARK: - Items

extension PayWithWiseViewModelFactoryTests {
    func testMakeItems_GivenAllFields_ThenAllValuesReturned() {
        let expectedMessage = "Msg"
        let expectedDescription = "Desc"
        let dueAt = Date.canned
        let expiryAt = Date.canned.addingTimeInterval(25 * 60 * 60)

        let paymentRequestLookup = PaymentRequestLookup.build(
            amount: Money.build(currency: .GBP, value: 10),
            message: expectedMessage,
            description: expectedDescription,
            dueAt: dueAt,
            expiryAt: expiryAt
        )

        let items = factory.type().makeItems(paymentRequestLookup: paymentRequestLookup)

        XCTAssertEqual(items.count, 5)
        XCTAssertEqual(
            items.first?.subtitle.text,
            "10 GBP"
        )
        XCTAssertEqual(
            items[safe: 1]?.subtitle.text,
            expectedDescription
        )
        XCTAssertEqual(
            items[safe: 2]?.subtitle.text,
            "Jan 1, 1970"
        )
        XCTAssertEqual(
            items[safe: 3]?.subtitle.text,
            "Jan 2, 1970"
        )
        XCTAssertEqual(
            items[safe: 4]?.subtitle.text,
            expectedMessage
        )
    }

    func testMakeItems_GivenSeveralNullValues_ThenCorrectItemsCreated() {
        let expectedMessage = "Msg"
        let expectedDescription = "Desc"

        let paymentRequestLookup = PaymentRequestLookup.build(
            amount: Money.build(currency: .GBP, value: 10),
            message: expectedMessage,
            description: expectedDescription
        )
        let items = factory.type().makeItems(paymentRequestLookup: paymentRequestLookup)

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(
            items.first?.subtitle.text,
            "10 GBP"
        )
        XCTAssertEqual(
            items[safe: 1]?.subtitle.text,
            expectedDescription
        )

        XCTAssertEqual(
            items[safe: 2]?.subtitle.text,
            expectedMessage
        )
    }
}

// MARK: - Helpers

private extension PayWithWiseViewModelFactoryTests {
    func makeViewModelForQuickpay(
        inlineAlert: PayWithWiseViewModel.Alert?,
        supportsProfileChange: Bool,
        supportedPaymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        profile: Profile = FakePersonalProfileInfo().asProfile(),
        businessInfo: ContactSearch = .canned,
        quickpayLookup: QuickpayAcquiringPayment = .canned,
        quote: PayWithWiseQuote? = nil,
        selectedBalance: Balance? = nil,
        selectProfileAction: @escaping (() -> Void) = {},
        selectBalanceAction: @escaping (() -> Void) = {},
        firstButtonAction: @escaping (() -> Void) = {},
        secondButtonAction: @escaping (() -> Void) = {}
    ) -> PayWithWiseViewModel {
        factory
            .makeQuickpay(
                inlineAlert: inlineAlert,
                supportsProfileChange: supportsProfileChange,
                supportedPaymentMethods: supportedPaymentMethods,
                profile: profile,
                businessInfo: businessInfo,
                quickpayLookup: quickpayLookup,
                quote: quote,
                selectedBalance: selectedBalance,
                selectProfileAction: selectProfileAction,
                selectBalanceAction: selectBalanceAction,
                firstButtonAction: firstButtonAction,
                secondButtonAction: secondButtonAction
            )
    }

    func makeViewModel(
        source: PayWithWiseFlow.PaymentInitializationSource = .canned,
        inlineAlert: PayWithWiseViewModel.Alert? = nil,
        supportsProfileChange: Bool = false,
        supportedPaymentMethods: [AcquiringPaymentMethodType] = [.payWithWise],
        profile: Profile = FakePersonalProfileInfo().asProfile(),
        paymentRequestLookup: PaymentRequestLookup = PaymentRequestLookup.build(
            amount: Money.build(currency: .PLN, value: 10.0)
        ),
        quote: PayWithWiseQuote? = nil,
        selectedBalance: Balance? = nil,
        selectProfileAction: @escaping (() -> Void) = {},
        selectBalanceAction: @escaping (() -> Void) = {},
        firstButtonAction: @escaping (() -> Void) = {},
        secondButtonAction: @escaping (() -> Void) = {}
    ) -> PayWithWiseViewModel {
        factory.make(
            source: source,
            inlineAlert: inlineAlert,
            supportsProfileChange: supportsProfileChange,
            supportedPaymentMethods: supportedPaymentMethods,
            profile: profile,
            paymentRequestLookup: paymentRequestLookup,
            avatar: .canned,
            quote: quote,
            selectedBalance: selectedBalance,
            selectProfileAction: selectProfileAction,
            selectBalanceAction: selectBalanceAction,
            firstButtonAction: firstButtonAction,
            secondButtonAction: secondButtonAction
        )
    }
}
