import BalanceKit
import BalanceKitTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport
import WiseCore

final class WisetagInteractorTests: TWTestCase {
    private var interactor: WisetagInteractorImpl!
    private var accountDetailsUseCase: AccountDetailsUseCaseMock!
    private var paymentMethodsUseCase: PaymentMethodsUseCaseMock!
    private var paymentRequestUseCase: PaymentRequestUseCaseV2Mock!
    private var wisetagUseCase: WisetagUseCaseMock!

    override func setUp() {
        super.setUp()

        paymentRequestUseCase = PaymentRequestUseCaseV2Mock()
        wisetagUseCase = WisetagUseCaseMock()
        accountDetailsUseCase = AccountDetailsUseCaseMock()
        paymentMethodsUseCase = PaymentMethodsUseCaseMock()
        makeInteractor()
    }

    override func tearDown() {
        interactor = nil
        wisetagUseCase = nil
        accountDetailsUseCase = nil
        paymentMethodsUseCase = nil
        paymentRequestUseCase = nil
        super.tearDown()
    }

    func test_fetchNextStep_GivenDiscoverable_ThenReturnShowWisetagActive() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        let image = UIImage.canned

        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.available)
        wisetagUseCase.shareableLinkStatusReturnValue = .just(status)
        wisetagUseCase.qrCodeReturnValue = .just(image)

        let currencyCode = CurrencyCode.GBP
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(.build(
                        currency: currencyCode
                    )),
                ]
            )
        )

        let result = try awaitPublisher(interactor.fetchNextStep())

        XCTAssertEqual(result.value, .showWisetag(image: image, status: status, isCardsEnabled: true))
    }

    func test_fetchNextStep_GivenNotDiscoverable_ThenReturnShowWisetagInactive() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        let image = UIImage.canned

        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.available)
        wisetagUseCase.shareableLinkStatusReturnValue = .just(status)
        wisetagUseCase.qrCodeReturnValue = .just(image)
        wisetagUseCase.shouldShowStoryReturnValue = false

        let currencyCode = CurrencyCode.GBP
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(.build(
                        currency: currencyCode
                    )),
                ]
            )
        )

        let result = try awaitPublisher(interactor.fetchNextStep())

        XCTAssertEqual(result.value, .showWisetag(image: image, status: status, isCardsEnabled: true))
    }

    func test_fetchNextStep_GivenCardsNotAvailable_ThenReturnShowWisetagWithCardsDisabled() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        let image = UIImage.canned

        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.ineligible)
        wisetagUseCase.shareableLinkStatusReturnValue = .just(status)
        wisetagUseCase.qrCodeReturnValue = .just(image)
        wisetagUseCase.shouldShowStoryReturnValue = false

        let currencyCode = CurrencyCode.GBP
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(.build(
                        currency: currencyCode
                    )),
                ]
            )
        )

        let result = try awaitPublisher(interactor.fetchNextStep())

        XCTAssertEqual(result.value, .showWisetag(image: image, status: status, isCardsEnabled: false))
    }

    func test_fetchNextStep_GivenNoAccountDetails_ThenReturnShowAccountDetails() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        let image = UIImage.canned

        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.available)
        wisetagUseCase.shareableLinkStatusReturnValue = .just(status)
        wisetagUseCase.qrCodeReturnValue = .just(image)
        wisetagUseCase.shouldShowStoryReturnValue = false

        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                []
            )
        )

        let result = try awaitPublisher(interactor.fetchNextStep())

        XCTAssertEqual(result.value, .showADFlow)
    }

    func test_fetchNextStep_GivenShouldShowStory_thenReturnShowStory() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        let image = UIImage.canned

        paymentMethodsUseCase.cardAvailabilityReturnValue = .just(.available)
        wisetagUseCase.shareableLinkStatusReturnValue = .just(status)
        wisetagUseCase.qrCodeReturnValue = .just(image)
        wisetagUseCase.shouldShowStoryReturnValue = true

        let currencyCode = CurrencyCode.GBP
        accountDetailsUseCase.accountDetails = .just(
            .loaded(
                [
                    AccountDetails.active(.build(
                        currency: currencyCode
                    )),
                ]
            )
        )

        let result = try awaitPublisher(interactor.fetchNextStep())

        XCTAssertEqual(result.value, .showStory)
    }

    func test_updateStatusToInactive_thenReturnCorrecStatus() throws {
        let status = ShareableLinkStatus.eligible(
            .notDiscoverable
        )

        wisetagUseCase.updateShareableLinkStatusReturnValue = .just(status)

        let image = UIImage.canned
        wisetagUseCase.qrCodeReturnValue = .just(image)

        let result = try awaitPublisher(interactor.updateShareableLinkStatus(profileId: ProfileId.canned, isDiscoverable: false))

        XCTAssertEqual(result.value?.0, status)
    }

    func test_updateStatusToActive_thenReturnCorrecStatus() throws {
        let status = ShareableLinkStatus.eligible(
            .discoverable(
                urlString: LoremIpsum.short,
                nickname: LoremIpsum.veryShort
            )
        )

        wisetagUseCase.updateShareableLinkStatusReturnValue = .just(status)

        let image = UIImage.canned
        wisetagUseCase.qrCodeReturnValue = .just(image)

        let result = try awaitPublisher(interactor.updateShareableLinkStatus(profileId: ProfileId.canned, isDiscoverable: true))

        XCTAssertEqual(result.value?.0, status)
    }

    func test_fetchDynamicForms_givenCardUnavailable() throws {
        let forms = [PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm.build(
            flowId: "flowid",
            url: "url"
        )]

        let paymentMethod = PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.build(
            type: .card,
            urn: "",
            name: "",
            summary: "",
            available: false,
            preferred: false,
            unavailabilityReason: .requiresUserAction(dynamicForms: forms),
            informationCollectionDynamicForms: [],
            ctaText: nil
        )

        paymentRequestUseCase.fetchReceiverCurrencyAvailabilityReturnValue = .just(
            PaymentRequestV2ReceiverAvailability.build(
                currencies: [.build(currency: .PLN, available: false, paymentMethods: [paymentMethod], availableBalances: [])]))

        let result = try awaitPublisher(interactor.fetchCardDynamicForms())

        XCTAssertEqual(result.value, forms)
    }

    func test_fetchDynamicForms_givenCardAvailable() throws {
        let paymentMethod = PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.build(
            type: .card,
            urn: "",
            name: "",
            summary: "",
            available: true,
            preferred: true,
            unavailabilityReason: nil,
            informationCollectionDynamicForms: [],
            ctaText: nil
        )

        paymentRequestUseCase.fetchReceiverCurrencyAvailabilityReturnValue = .just(
            PaymentRequestV2ReceiverAvailability.build(
                currencies: [.build(currency: .PLN, available: false, paymentMethods: [paymentMethod], availableBalances: [])]))

        let result = try awaitPublisher(interactor.fetchCardDynamicForms())

        XCTAssertEqual(result.value, [])
    }
}

private extension WisetagInteractorTests {
    func makeInteractor() {
        interactor = WisetagInteractorImpl(
            profile: FakePersonalProfileInfo().asProfile(),
            wisetagUseCase: wisetagUseCase,
            accountDetailsUseCase: accountDetailsUseCase,
            paymentMethodsUseCase: paymentMethodsUseCase,
            paymentRequestUseCase: paymentRequestUseCase
        )
    }
}
