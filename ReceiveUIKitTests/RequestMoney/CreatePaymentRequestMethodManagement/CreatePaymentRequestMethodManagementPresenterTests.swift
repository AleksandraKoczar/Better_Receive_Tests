import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport

@MainActor
final class CreatePaymentRequestMethodManagementPresenterTests: TWTestCase {
    private let profile = Profile.business(FakeBusinessProfileInfo())
    private var view: CreatePaymentRequestPaymentMethodManagementViewMock!
    private var routingDelegate: CreatePaymentRequestRoutingDelegateMock!
    private var delegate: PaymentMethodsDelegateMock!
    private var presenter: CreatePaymentRequestPaymentMethodManagementPresenterImpl!

    private let localPreferences: [PaymentRequestV2PaymentMethods] = [
        .payWithWise,
    ]

    private var newPreferences: [PaymentRequestV2PaymentMethods]?

    private let paymentMethodsAvailability = PaymentRequestV2ReceiverAvailability.build(
        currencies: [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.build(
                currency: .GBP,
                available: true,
                paymentMethods: [
                    .build(
                        type: .payWithWise,
                        urn: "urn:wise:icons:fastFlag",
                        name: "Pay With Wise",
                        summary: "PWW summary",
                        available: true,
                        preferred: true,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                    .build(
                        type: .bankTransfer,
                        urn: "urn:wise:icons:bankTransfer",
                        name: "Bank Transfer",
                        summary: "Bank transfer summary",
                        available: true,
                        preferred: false,
                        unavailabilityReason: nil,
                        informationCollectionDynamicForms: []
                    ),
                    .build(
                        type: .card,
                        urn: "urn:wise:icons:card",
                        name: "Card",
                        summary: "Card summary",
                        available: false,
                        preferred: false,
                        unavailabilityReason: .requiresUserAction(dynamicForms: [
                            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm.build(
                                flowId: LoremIpsum.short,
                                url: LoremIpsum.medium
                            ),
                        ]),
                        informationCollectionDynamicForms: []
                    ),
                ],
                availableBalances: []
            ),
        ])

    override func setUp() {
        super.setUp()

        view = CreatePaymentRequestPaymentMethodManagementViewMock()
        routingDelegate = CreatePaymentRequestRoutingDelegateMock()
        delegate = PaymentMethodsDelegateMock()

        presenter = CreatePaymentRequestPaymentMethodManagementPresenterImpl(
            delegate: delegate,
            routingDelegate: routingDelegate,
            localPreferences: localPreferences,
            paymentMethodsAvailability: paymentMethodsAvailability.currencies[0],
            onSave: { newPreferences in
                self.newPreferences = newPreferences
            }
        )

        trackForMemoryLeak(instance: presenter) { [weak self] in
            self?.presenter = nil
        }
    }

    override func tearDown() {
        presenter = nil
        view = nil
        routingDelegate = nil
        super.tearDown()
    }

    func testStart_thenConfigureView() {
        let viewModel = makeExpectedViewModel()
        presenter.start(with: view)
        expectNoDifference(view.configureReceivedViewModel, viewModel)
    }

    func testStart_thenSecondaryButtonTapped_AndOpenWebView() {
        presenter.start(with: view)
        presenter.secondaryFooterButtonTapped()

        XCTAssertEqual(routingDelegate.showPaymentMethodManagementOnWebCallsCount, 1)
    }

    func testStart_thenBankTranferOptionToggled_AndSave() throws {
        presenter.start(with: view)

        let optionViewModel = try XCTUnwrap(view.configureReceivedViewModel?.options[1])
        guard case let .switchOptionViewModel(switchOptionViewModel) = optionViewModel else {
            XCTFail("Expect a switch option view model, but contain \(optionViewModel.self)")
            return
        }
        switchOptionViewModel.onToggle(true)

        presenter.footerButtonTapped()

        XCTAssertEqual(newPreferences?.count, 2)
    }

    func test_requiresUserActionOptionTapped() throws {
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        guard case let .actionOptionViewModel(actionViewModel) = viewModel.options[2] else {
            XCTFail("Option view model mismatch.")
            return
        }
        actionViewModel.action.handler()

        let expectedDynamicForms = [
            PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm.build(
                flowId: LoremIpsum.short,
                url: LoremIpsum.medium
            ),
        ]

        XCTAssertEqual(routingDelegate.showDynamicFormsMethodManagementCallsCount, 1)
        let arguments = try XCTUnwrap(routingDelegate.showDynamicFormsMethodManagementReceivedArguments)
        XCTAssertEqual(arguments.dynamicForms, expectedDynamicForms)
    }
}

private extension CreatePaymentRequestMethodManagementPresenterTests {
    func makePWWOption() -> CreatePaymentRequestMethodManagementViewModel.OptionViewModel {
        let pwwOption = OptionViewModel(
            title: "Pay With Wise",
            subtitle: "PWW summary",
            leadingView: LeadingViewModel.avatar(.icon(Icons.fastFlag.image)),
            isEnabled: true
        )
        return CreatePaymentRequestMethodManagementViewModel.OptionViewModel.payWithWiseOptionViewModel(pwwOption)
    }

    func makeBankTransferOption() -> CreatePaymentRequestMethodManagementViewModel.OptionViewModel {
        let bankTransferOption = CreatePaymentRequestMethodManagementViewModel.SwitchOptionViewModel(
            title: "Bank Transfer",
            subtitle: "Bank transfer summary",
            leadingViewModel: LeadingViewModel.avatar(.icon(Icons.fastFlag.image)),
            isOn: false,
            isEnabled: true,
            onToggle: { _ in }
        )
        return CreatePaymentRequestMethodManagementViewModel.OptionViewModel.switchOptionViewModel(bankTransferOption)
    }

    func makeCardOption() -> CreatePaymentRequestMethodManagementViewModel.OptionViewModel {
        let cardOption = CreatePaymentRequestMethodManagementViewModel.ActionOptionViewModel(
            title: "Card",
            subtitle: "Card summary",
            leadingViewModel: LeadingViewModel.avatar(.icon(Icons.card.image)),
            action: Action(
                title: "Set up",
                handler: {}
            )
        )

        return CreatePaymentRequestMethodManagementViewModel.OptionViewModel.actionOptionViewModel(cardOption)
    }

    func makeExpectedViewModel() -> CreatePaymentRequestMethodManagementViewModel {
        CreatePaymentRequestMethodManagementViewModel(
            title: "Payment methods",
            subtitle: "Changes only affect this payment link.",
            options: [
                makePWWOption(),
                makeBankTransferOption(),
                makeCardOption(),
            ],
            footerAction: Action(
                title: "Save",
                handler: {}
            ),
            secondaryFooterAction: Action(
                title: "Change defaults",
                handler: {}
            )
        )
    }
}
