import AnalyticsKitTestingSupport
import ContactsKit
import Neptune
import Prism
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

@MainActor
final class QuickpayPayerPresenterTests: TWTestCase {
    private let contact = Contact.build(
        id: Contact.Id.match("123", contactId: "100"),
        title: "Joe Doe Limited",
        subtitle: "subtitle",
        isVerified: true,
        isHighlighted: false,
        labels: [],
        hasAvatar: true,
        avatarPublisher: .canned,
        lastUsedDate: nil,
        nickname: "nickname"
    )

    private var view: QuickpayPayerViewMock!
    private var profile = FakeBusinessProfileInfo().asProfile()
    private var presenter: QuickpayPayerPresenterImpl!
    private var quickpayUseCase: QuickpayUseCaseMock!
    private var router: QuickpayPayerRouterMock!
    private var analyticsTracker: QuickpayTrackingMock!

    override func setUp() {
        super.setUp()
        view = QuickpayPayerViewMock()
        quickpayUseCase = QuickpayUseCaseMock()
        router = QuickpayPayerRouterMock()
        analyticsTracker = QuickpayTrackingMock()

        let businessInfo = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .business
        )

        presenter = QuickpayPayerPresenterImpl(
            profile: profile,
            businessInfo: businessInfo,
            quickpayName: "johnDoe",
            quickpayPayerInputs: nil,
            quickpayUseCase: quickpayUseCase,
            analyticsTracker: analyticsTracker,
            router: router,
            scheduler: .immediate
        )

        trackForMemoryLeak(instance: presenter) { [weak self] in
            self?.presenter = nil
        }
    }

    override func tearDown() {
        presenter = nil
        view = nil
        quickpayUseCase = nil
        router = nil
        super.tearDown()
    }

    func test_start_givenBusinessProfile_thenConfigureView() throws {
        let currencies = QuickpayCurrencyAvailability.build(preferredCurrency: .PLN, availableCurrencies: [.PLN, .USD])

        quickpayUseCase.getCurrencyAvailabilityReturnValue = .just(.content(currencies))

        presenter.start(with: view)

        let viewModel = makeViewModel()
        let receivedViewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(receivedViewModel, viewModel)

        XCTAssertEqual(quickpayUseCase.getCurrencyAvailabilityCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onAmountSelectionStartedCallsCount, 1)
    }

    func test_start_givenNoPaymentMethods_thenShowError() throws {
        quickpayUseCase.getCurrencyAvailabilityReturnValue = .just(.error(QuickpayError(
            code: .other,
            message: "message",
            clientError: nil
        )))

        presenter.start(with: view)

        XCTAssertEqual(quickpayUseCase.getCurrencyAvailabilityCallsCount, 1)
        XCTAssertEqual(view.configureErrorCallsCount, 1)
    }

    func test_moneyInputCurrencyTapped() throws {
        let currencies = QuickpayCurrencyAvailability.build(preferredCurrency: .PLN, availableCurrencies: [.PLN, .USD])

        quickpayUseCase.getCurrencyAvailabilityReturnValue = .just(.content(currencies))

        presenter.start(with: view)
        presenter.moneyInputCurrencyTapped()
        let receivedCurrencies = [CurrencyCode("PLN"), CurrencyCode("USD")]
        let selectedCurrency = CurrencyCode("PLN")
        XCTAssertEqual(router.showCurrencySelectorCallsCount, 1)
        XCTAssertEqual(
            router.showCurrencySelectorReceivedArguments?.activeCurrencies,
            receivedCurrencies
        )

        let onCurrencySelected = try XCTUnwrap(
            router.showCurrencySelectorReceivedArguments?.onCurrencySelected
        )
        onCurrencySelected(selectedCurrency)
        XCTAssertEqual(view.updateSelectedCurrencyCallsCount, 1)
        XCTAssertEqual(
            view.updateSelectedCurrencyReceivedCurrency,
            selectedCurrency
        )
    }

    func test_moneyValueUpdated() throws {
        let currencies = QuickpayCurrencyAvailability.build(preferredCurrency: .PLN, availableCurrencies: [.PLN, .USD])

        quickpayUseCase.getCurrencyAvailabilityReturnValue = .just(.content(currencies))

        presenter.start(with: view)
        presenter.moneyValueUpdated("10")

        XCTAssertEqual(view.footerButtonStateCallsCount, 2)
        XCTAssertEqual(view.footerButtonStateReceivedEnabled, true)
    }

    func test_moneyValueUpdated_GivenWrongValue() {
        let currencies = QuickpayCurrencyAvailability.build(preferredCurrency: .PLN, availableCurrencies: [.PLN, .USD])

        quickpayUseCase.getCurrencyAvailabilityReturnValue = .just(.content(currencies))

        presenter.start(with: view)
        presenter.moneyValueUpdated("abc")

        XCTAssertEqual(view.footerButtonStateCallsCount, 2)
        XCTAssertEqual(view.footerButtonStateReceivedEnabled, false)
    }

    func test_continueToPayTapped() {
        let currencies = QuickpayCurrencyAvailability.build(preferredCurrency: .PLN, availableCurrencies: [.PLN, .USD])

        quickpayUseCase.getCurrencyAvailabilityReturnValue = .just(.content(currencies))

        quickpayUseCase.createAcquiringPaymentReturnValue = .just(.canned)

        let receivedPayerData = QuickpayPayerData(
            value: 10, currency: .PLN, description: nil, businessQuickpay: "johnDoe"
        )

        let inputs = QuickpayPayerInputs.build(amount: 10, currency: "PLN", description: nil)

        presenter.start(with: view)
        presenter.continueTapped(inputs: inputs)

        XCTAssertEqual(router.navigateToPayWithWiseCallsCount, 1)
        XCTAssertEqual(router.navigateToPayWithWiseReceivedPayerData, receivedPayerData)

        XCTAssertEqual(analyticsTracker.onAmountSelectionContinuePressedCallsCount, 1)
    }

    func test_continueToPayGivenPayerInputs() {
        let businessInfo = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .business
        )

        let currencies = QuickpayCurrencyAvailability.build(preferredCurrency: .PLN, availableCurrencies: [.PLN, .USD])

        quickpayUseCase.getCurrencyAvailabilityReturnValue = .just(.content(currencies))

        quickpayUseCase.createAcquiringPaymentReturnValue = .just(.canned)

        presenter = QuickpayPayerPresenterImpl(
            profile: profile,
            businessInfo: businessInfo,
            quickpayName: "johnDoe",
            quickpayPayerInputs: QuickpayPayerInputs.build(amount: 10, currency: "PLN", description: "description"),
            quickpayUseCase: quickpayUseCase,
            analyticsTracker: analyticsTracker,
            router: router,
            scheduler: .immediate
        )

        let receivedPayerData = QuickpayPayerData(
            value: 10, currency: .PLN, description: "description", businessQuickpay: "johnDoe"
        )

        presenter.start(with: view)

        XCTAssertEqual(router.navigateToPayWithWiseCallsCount, 1)
        XCTAssertEqual(router.navigateToPayWithWiseReceivedPayerData, receivedPayerData)
    }

    func test_continueToPayGivenInvalidPayerInputsThenConfigureView() {
        let businessInfo = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .business
        )

        let currencies = QuickpayCurrencyAvailability.build(preferredCurrency: .PLN, availableCurrencies: [.PLN, .USD])
        quickpayUseCase.getCurrencyAvailabilityReturnValue = .just(.content(currencies))
        quickpayUseCase.createAcquiringPaymentReturnValue = .just(.canned)

        presenter = QuickpayPayerPresenterImpl(
            profile: profile,
            businessInfo: businessInfo,
            quickpayName: "johnDoe",
            quickpayPayerInputs: QuickpayPayerInputs.build(amount: 10, currency: "", description: "description"),
            quickpayUseCase: quickpayUseCase,
            analyticsTracker: analyticsTracker,
            router: router,
            scheduler: .immediate
        )

        presenter.start(with: view)

        XCTAssertEqual(view.configureCallsCount, 1)
        XCTAssertEqual(view.footerButtonStateReceivedEnabled, false)
    }

    func test_continueToPayGivenOnlyDescriptionThenConfigureViewWithThatDescription() {
        let businessInfo = ContactSearch.build(
            contact: contact,
            isSelf: false,
            pageType: .business
        )

        let currencies = QuickpayCurrencyAvailability.build(preferredCurrency: .PLN, availableCurrencies: [.PLN, .USD])
        quickpayUseCase.getCurrencyAvailabilityReturnValue = .just(.content(currencies))
        quickpayUseCase.createAcquiringPaymentReturnValue = .just(.canned)

        presenter = QuickpayPayerPresenterImpl(
            profile: profile,
            businessInfo: businessInfo,
            quickpayName: "johnDoe",
            quickpayPayerInputs: QuickpayPayerInputs.build(amount: nil, currency: "", description: "description"),
            quickpayUseCase: quickpayUseCase,
            analyticsTracker: analyticsTracker,
            router: router,
            scheduler: .immediate
        )

        let viewModel = makeViewModelWithDescription()

        presenter.start(with: view)

        XCTAssertEqual(view.configureCallsCount, 1)
        XCTAssertEqual(view.configureReceivedViewModel, viewModel)
        XCTAssertEqual(view.footerButtonStateReceivedEnabled, false)
    }
}

private extension QuickpayPayerPresenterTests {
    func makeViewModel() -> QuickpayPayerViewModel {
        QuickpayPayerViewModel(
            avatar: .canned,
            businessName: "Joe Doe Limited",
            subtitle: "subtitle",
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "You pay",
                amount: nil,
                currencyName: "PLN",
                currencyAccessibilityName: "Polish Złoty",
                flagImage: CurrencyCode.PLN.icon
            ),
            description: nil
        )
    }

    func makeViewModelWithDescription() -> QuickpayPayerViewModel {
        QuickpayPayerViewModel(
            avatar: .canned,
            businessName: "Joe Doe Limited",
            subtitle: "subtitle",
            moneyInputViewModel: MoneyInputViewModel(
                titleText: "You pay",
                amount: nil,
                currencyName: "PLN",
                currencyAccessibilityName: "Polish Złoty",
                flagImage: CurrencyCode.PLN.icon
            ),
            description: "description"
        )
    }
}
