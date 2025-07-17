import BalanceKit
import Combine
import Foundation
import HttpClientKit
import HttpClientKitTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import WiseCore

final class PayWithWiseInteractorTests: TWTestCase {
    private struct _Constants {
        let profileId = ProfileId(123)
        let paymentKey = "Pkey"
        let paymentRequestId = PaymentRequestId("PID")
        let balanceGBP = Balance.build(
            id: BalanceId(16),
            balanceType: .standard,
            availableAmount: 30,
            currency: .GBP,
            isVisible: true,
            isPrimary: true
        )
        let balanceEUR = Balance.build(
            id: BalanceId(32),
            balanceType: .standard,
            availableAmount: 25,
            currency: .EUR,
            isVisible: true,
            isPrimary: true
        )
        let balanceTRY = Balance.build(
            id: BalanceId(64),
            balanceType: .standard,
            availableAmount: 10000,
            currency: .TRY,
            isVisible: true,
            isPrimary: true
        )
        let balanceMXN = Balance.build(
            id: BalanceId(64),
            balanceType: .standard,
            availableAmount: 10000,
            currency: .MXN,
            isVisible: true,
            isPrimary: false
        )
        let smallerGBPAmount = Money.build(currency: .GBP, value: 1)
    }

    private var interactor: PayWithWiseInteractorImpl!
    private var payWithWiseUseCase: PayWithWiseUseCaseMock!
    private var balancesUseCase: BalancesUseCaseMock!
    private var owedPaymentRequestUseCase: OwedPaymentRequestUseCaseMock!
    private var attachmentFileService: AttachmentFileServiceMock!
    private var imageLoader: ImageLoaderMock!

    private var Constants = _Constants()

    override func setUp() {
        super.setUp()

        payWithWiseUseCase = PayWithWiseUseCaseMock()
        balancesUseCase = BalancesUseCaseMock()
        owedPaymentRequestUseCase = OwedPaymentRequestUseCaseMock()
        attachmentFileService = AttachmentFileServiceMock()
        imageLoader = ImageLoaderMock()

        makeInteractor()
    }

    override func tearDown() {
        interactor = nil
        payWithWiseUseCase = nil
        balancesUseCase = nil
        owedPaymentRequestUseCase = nil
        attachmentFileService = nil
        imageLoader = nil

        super.tearDown()
    }
}

// MARK: - Payment key gathering

extension PayWithWiseInteractorTests {
    func testPaymentKeyGathering_GivenPaymentKey_ThenNoRequestSent() throws {
        makeInteractor(
            source: .paymentKey(
                .request(
                    paymentKey: Constants.paymentKey
                )
            )
        )

        let result = try awaitPublisher(
            interactor.gatherPaymentKey(profileId: Constants.profileId)
        )

        XCTAssertFalse(owedPaymentRequestUseCase.owedPaymentRequestCalled)
        XCTAssertEqual(result.value, Constants.paymentKey)

        let expectedKey2 = "Abc"
        makeInteractor(
            source: .paymentKey(
                .contact(
                    paymentKey: expectedKey2
                )
            )
        )

        let result2 = try awaitPublisher(
            interactor.gatherPaymentKey(profileId: Constants.profileId)
        )

        XCTAssertFalse(owedPaymentRequestUseCase.owedPaymentRequestCalled)
        XCTAssertEqual(result2.value, expectedKey2)
    }

    func testPaymentKeyGathering_GivenPaymentRequestId_ThenPaymentKeyFetched() throws {
        makeInteractor(
            source: .paymentRequestId(
                Constants.paymentRequestId
            )
        )
        owedPaymentRequestUseCase.owedPaymentRequestReturnValue = .just(
            OwedPaymentRequestDetail.build(
                linkKey: Constants.paymentKey
            )
        )

        let result = try awaitPublisher(
            interactor.gatherPaymentKey(profileId: Constants.profileId)
        )

        XCTAssertEqual(
            owedPaymentRequestUseCase.owedPaymentRequestReceivedArguments?.profileId,
            Constants.profileId
        )
        XCTAssertEqual(result.value, Constants.paymentKey)
    }

    func testPaymentKeyGathering_GivenFailure_ThenCorrectErrorReturned() throws {
        let expectedError = MockError.dummy
        makeInteractor(
            source: .paymentRequestId(
                Constants.paymentRequestId
            )
        )
        owedPaymentRequestUseCase.owedPaymentRequestReturnValue = .fail(
            with: MockError.dummy
        )

        let result = try awaitPublisher(
            interactor.gatherPaymentKey(profileId: Constants.profileId)
        )

        XCTAssertTrue(owedPaymentRequestUseCase.owedPaymentRequestCalled)
        XCTAssertEqual(
            PayWithWiseV2Error.fetchingPaymentKeyFailed(error: expectedError).localizedDescription,
            result.error?.localizedDescription
        )
    }
}

// MARK: - Quickpay (Acquiring Payment)

extension PayWithWiseInteractorTests {
    func test_acquiringPaymentLookup_GivenSuccess_ThenReturnCorrectResponse() throws {
        let acquiringPaymentId = AcquiringPaymentId.build(value: "123")
        let session = QuickpayAcquiringPaymentSession.build(id: "456")
        let amount = Money.build(currency: .GBP, value: 1)

        payWithWiseUseCase.getAcquiringPaymentReturnValue = .just(QuickpayAcquiringPayment.build(
            id: acquiringPaymentId,
            paymentSessionId: session,
            amount: amount,
            description: nil,
            paymentMethods: [.build(type: .payWithWise, urn: "", name: "PWW", summary: "", available: true)]
        ))

        let result = try awaitPublisher(
            interactor.acquiringPaymentLookup(paymentSession: session, acquiringPaymentId: acquiringPaymentId)
        )

        XCTAssertEqual(payWithWiseUseCase.getAcquiringPaymentReceivedArguments?.acquiringPaymentId, acquiringPaymentId)
        XCTAssertEqual(result.value?.amount, amount)
    }

    func test_acquiringPaymentLookup_GivenFailure_ThenCorrectErrorReturned() throws {
        let expectedError = PayWithWiseV2Error.fetchingAcquiringPaymentFailed

        let acquiringPaymentId = AcquiringPaymentId.build(value: "123")
        let session = QuickpayAcquiringPaymentSession.build(id: "456")

        payWithWiseUseCase.getAcquiringPaymentReturnValue = .fail(
            with: expectedError
        )

        let result = try awaitPublisher(
            interactor.acquiringPaymentLookup(paymentSession: session, acquiringPaymentId: acquiringPaymentId)
        )

        XCTAssertEqual(
            PayWithWiseV2Error.fetchingAcquiringPaymentFailed.localizedDescription,
            result.error?.localizedDescription
        )
    }

    func test_createQuickpayQuote_GivenSuccess_ThenReturnCorrectResponse() throws {
        let session = PaymentRequestSession.build(id: "456")

        payWithWiseUseCase.quoteReturnValue = .just(PayWithWiseQuote.canned)

        _ = try awaitPublisher(
            interactor.createQuickpayQuote(session: session, balanceId: Constants.balanceGBP.id, profileId: Constants.profileId)
        )

        XCTAssertEqual(payWithWiseUseCase.quoteReceivedArguments?.session, session)

        XCTAssertEqual(
            payWithWiseUseCase.quoteReceivedArguments?.request,
            PayWithWisePaymentRequest(
                source: PayWithWisePaymentRequest.Source(
                    id: String(Constants.balanceGBP.id.value),
                    type: "BALANCE"
                )
            )
        )

        XCTAssertEqual(
            payWithWiseUseCase.quoteReceivedArguments?.profileId,
            Constants.profileId
        )
    }
}

extension PayWithWiseInteractorTests {
    func testPaymentRequestLookup_GivenSuccess_WhenValuePublished_ThenCorrectLookupResponseReturned() throws {
        let expectedReference = "Ref"
        payWithWiseUseCase.paymentRequestInfoReturnValue = .just(
            PaymentRequestLookup.build(
                reference: expectedReference
            )
        )

        let result = try awaitPublisher(
            interactor.paymentRequestLookup(
                paymentKey: Constants.paymentKey
            )
        )

        XCTAssertEqual(payWithWiseUseCase.paymentRequestInfoReceivedKey, Constants.paymentKey)
        XCTAssertEqual(result.value?.reference, expectedReference)
    }

    func testPaymentRequestLookup_GivenFailure_ThenCorrectErrorReturned() throws {
        let expectedError = PayWithWisePaymentRequestInfoError.alreadyPaid(
            message: "Msg"
        )
        payWithWiseUseCase.paymentRequestInfoReturnValue = .fail(
            with: expectedError
        )

        let result = try awaitPublisher(
            interactor.paymentRequestLookup(
                paymentKey: Constants.paymentKey
            )
        )

        XCTAssertEqual(
            PayWithWiseV2Error.fetchingPaymentRequestInfoFailed(error: expectedError).localizedDescription,
            result.error?.localizedDescription
        )
    }
}

// MARK: - Balances

extension PayWithWiseInteractorTests {
    func testBalances_GivenParameters_ThenCorrectParamsPassed() throws {
        balancesUseCase.listenToBalancesReturnValue = .just([])
        balancesUseCase.balancesCanFundReturnValue = .just([])

        _ = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        XCTAssertEqual(
            balancesUseCase.listenToBalancesReceivedArguments?.profileId,
            Constants.profileId
        )
        XCTAssertEqual(
            balancesUseCase.listenToBalancesReceivedArguments?.strategy,
            .expirableCacheAfter(300)
        )
        XCTAssertEqual(
            balancesUseCase.balancesCanFundReceivedArguments?.profileId,
            Constants.profileId
        )
        XCTAssertEqual(
            balancesUseCase.balancesCanFundReceivedArguments?.amount,
            Constants.smallerGBPAmount
        )
    }

    func testBalances_GivenParametersAndNeedsRefresh_ThenCorrectParamsPassed() throws {
        balancesUseCase.listenToBalancesReturnValue = .just([])
        balancesUseCase.balancesCanFundReturnValue = .just([])

        _ = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: true
            )
        )

        XCTAssertEqual(
            balancesUseCase.listenToBalancesReceivedArguments?.profileId,
            Constants.profileId
        )
        XCTAssertEqual(
            balancesUseCase.listenToBalancesReceivedArguments?.strategy,
            .loadElseUseCache
        )
        XCTAssertEqual(
            balancesUseCase.balancesCanFundReceivedArguments?.profileId,
            Constants.profileId
        )
        XCTAssertEqual(
            balancesUseCase.balancesCanFundReceivedArguments?.amount,
            Constants.smallerGBPAmount
        )
    }

    func testBalances_GivenNoBalance_ThenCorrectResultReturned() throws {
        balancesUseCase.listenToBalancesReturnValue = .just([])
        balancesUseCase.balancesCanFundReturnValue = .just([])

        let result = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        XCTAssertEqual(
            result.error?.localizedDescription,
            PayWithWiseV2Error.noBalancesAvailable.localizedDescription
        )
    }

    func testBalanceFiltering_GivenExtraBalances_ThenIrrelevantOnesFiltered() throws {
        balancesUseCase.listenToBalancesReturnValue = .just([
            Constants.balanceEUR,
            Balance.build(currency: .AED, isVisible: false),
            Balance.build(balanceType: .savings, currency: .JPY),
            Constants.balanceTRY,
            Constants.balanceGBP,
            Constants.balanceMXN,
        ])
        balancesUseCase.balancesCanFundReturnValue = .just([])

        let result = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        XCTAssertEqual(
            result.value,
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .init(
                    balance: Constants.balanceGBP,
                    hasSameCurrencyBalance: true,
                    hasFunds: false
                ),
                fundableBalances: [],
                balances: [
                    Constants.balanceEUR,
                    Constants.balanceTRY,
                    Constants.balanceGBP,
                ]
            )
        )
    }

    func testBalances_GivenNonFundableButSameCurrencyBalances_ThenCorrectResultReturned() throws {
        let balances = [
            Constants.balanceEUR,
            Constants.balanceTRY,
            Constants.balanceGBP,
        ]
        balancesUseCase.listenToBalancesReturnValue = .just(balances)
        balancesUseCase.balancesCanFundReturnValue = .just([])

        let result = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        expectNoDifference(
            result.value,
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .init(
                    balance: Constants.balanceGBP,
                    hasSameCurrencyBalance: true,
                    hasFunds: false
                ),
                fundableBalances: [],
                balances: balances
            )
        )
    }

    func testBalances_GivenFundableSameCurrencyBalances_ThenCorrectResultReturned() throws {
        let balances = [
            Constants.balanceEUR,
            Constants.balanceTRY,
            Constants.balanceGBP,
        ]
        balancesUseCase.listenToBalancesReturnValue = .just(balances)
        balancesUseCase.balancesCanFundReturnValue = .just([
            Constants.balanceGBP,
        ])

        let result = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        expectNoDifference(
            result.value,
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .init(
                    balance: Constants.balanceGBP,
                    hasSameCurrencyBalance: true,
                    hasFunds: true
                ),
                fundableBalances: [
                    Constants.balanceGBP,
                ],
                balances: balances
            )
        )
    }

    func testBalances_GivenFundableDifferentCurrencyBalances_ThenCorrectResultReturned() throws {
        let balances = [
            Constants.balanceEUR,
            Constants.balanceTRY,
        ]
        balancesUseCase.listenToBalancesReturnValue = .just(balances)
        balancesUseCase.balancesCanFundReturnValue = .just([
            Constants.balanceTRY,
        ])

        let result = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        expectNoDifference(
            result.value,
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .init(
                    balance: Constants.balanceTRY,
                    hasSameCurrencyBalance: false,
                    hasFunds: true
                ),
                fundableBalances: [
                    Constants.balanceTRY,
                ],
                balances: balances
            )
        )
    }

    func testBalances_GivenMultipleFundableBalances_ThenSameCurrencyBalanceReturned() throws {
        let balances = [
            Constants.balanceEUR,
            Constants.balanceTRY,
            Constants.balanceGBP,
        ]
        balancesUseCase.listenToBalancesReturnValue = .just(balances)
        balancesUseCase.balancesCanFundReturnValue = .just([
            Constants.balanceTRY,
            Constants.balanceGBP,
        ])

        let result = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        expectNoDifference(
            result.value,
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .init(
                    balance: Constants.balanceGBP,
                    hasSameCurrencyBalance: true,
                    hasFunds: true
                ),
                fundableBalances: [
                    Constants.balanceTRY,
                    Constants.balanceGBP,
                ],
                balances: balances
            )
        )
    }

    func testBalances_GivenNoFundableBalance_ThenCorrectResultReturned() throws {
        let balances = [
            Constants.balanceEUR,
            Constants.balanceGBP,
            Constants.balanceTRY,
        ]
        balancesUseCase.listenToBalancesReturnValue = .just(balances)
        balancesUseCase.balancesCanFundReturnValue = .just([])

        let result = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        expectNoDifference(
            result.value,
            PayWithWiseInteractorImpl.BalanceFetchingResult.build(
                autoSelectionResult: .init(
                    balance: Constants.balanceGBP,
                    hasSameCurrencyBalance: true,
                    hasFunds: false
                ),
                fundableBalances: [],
                balances: balances
            )
        )
    }

    func testBalances_GivenFailureOnFetchingBalances_ThenCorrectErrorReturned() throws {
        let expectedError = MockError.dummy
        balancesUseCase.listenToBalancesReturnValue = .fail(with: expectedError)
        balancesUseCase.balancesCanFundReturnValue = .just([])

        let result = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        expectNoDifference(
            result.error?.localizedDescription,
            PayWithWiseV2Error.fetchingBalancesFailed(error: expectedError).localizedDescription
        )
    }

    func testBalances_GivenFailureOnFetchingFundableBalances_ThenCorrectErrorReturned() throws {
        let expectedError = MockError.dummy
        balancesUseCase.listenToBalancesReturnValue = .just([])
        balancesUseCase.balancesCanFundReturnValue = .fail(with: expectedError)

        let result = try awaitPublisher(
            interactor.balances(
                amount: Constants.smallerGBPAmount,
                profileId: Constants.profileId,
                needsRefresh: false
            )
        )

        expectNoDifference(
            result.error?.localizedDescription,
            PayWithWiseV2Error.fetchingFundableBalancesFailed(error: expectedError).localizedDescription
        )
    }
}

// MARK: - Create payment

extension PayWithWiseInteractorTests {
    func testCreatePayment_GivenParameters_ThenCorrectParamsPassed() throws {
        let expectedSession = PaymentRequestSession.build(id: "Id")
        payWithWiseUseCase.createPaymentReturnValue = .just(expectedSession)
        payWithWiseUseCase.quoteReturnValue = .just(PayWithWiseQuote.canned)

        _ = try awaitPublisher(
            interactor.createPayment(
                paymentKey: Constants.paymentKey,
                paymentRequestId: Constants.paymentRequestId,
                balanceId: Constants.balanceGBP.id,
                profileId: Constants.profileId
            )
        )

        XCTAssertEqual(
            payWithWiseUseCase.createPaymentReceivedArguments?.key,
            Constants.paymentKey
        )
        XCTAssertEqual(
            payWithWiseUseCase.createPaymentReceivedArguments?.requestId,
            Constants.paymentRequestId
        )

        XCTAssertEqual(
            payWithWiseUseCase.quoteReceivedArguments?.session,
            expectedSession
        )
        XCTAssertEqual(
            payWithWiseUseCase.quoteReceivedArguments?.profileId,
            Constants.profileId
        )

        XCTAssertEqual(
            payWithWiseUseCase.quoteReceivedArguments?.request,
            PayWithWisePaymentRequest(
                source: PayWithWisePaymentRequest.Source(
                    id: String(Constants.balanceGBP.id.value),
                    type: "BALANCE"
                )
            )
        )
    }

    func testCreatePayment_GivenExceptedValues_WhenPaymentCreated_ThenValuesMatch() throws {
        let expectedSession = PaymentRequestSession.build(id: "Id")
        let expectedQuote = PayWithWiseQuote.build(id: "idd")

        payWithWiseUseCase.createPaymentReturnValue = .just(expectedSession)
        payWithWiseUseCase.quoteReturnValue = .just(expectedQuote)

        let result = try awaitPublisher(
            interactor.createPayment(
                paymentKey: Constants.paymentKey,
                paymentRequestId: Constants.paymentRequestId,
                balanceId: Constants.balanceGBP.id,
                profileId: Constants.profileId
            )
        )

        XCTAssertEqual(
            result.value?.0,
            expectedSession
        )
        XCTAssertEqual(
            result.value?.1,
            expectedQuote
        )
    }

    func testCreatePayment_GivenSessionCreationFailure__ThenErrorsMatch() throws {
        let expectedError = MockError.dummy
        payWithWiseUseCase.createPaymentReturnValue = .fail(with: expectedError)
        payWithWiseUseCase.quoteReturnValue = .just(PayWithWiseQuote.canned)

        let result = try awaitPublisher(
            interactor.createPayment(
                paymentKey: Constants.paymentKey,
                paymentRequestId: Constants.paymentRequestId,
                balanceId: Constants.balanceGBP.id,
                profileId: Constants.profileId
            )
        )

        XCTAssertEqual(
            result.error?.localizedDescription,
            PayWithWiseV2Error.fetchingSessionFailed(error: expectedError).localizedDescription
        )
    }

    func testCreatePayment_GivenQuoteCreationFailure_ThenErrorsMatch() throws {
        let expectedError = PayWithWisePaymentError.cancelledByUser
        payWithWiseUseCase.createPaymentReturnValue = .just(PaymentRequestSession.canned)
        payWithWiseUseCase.quoteReturnValue = .fail(with: expectedError)

        let result = try awaitPublisher(
            interactor.createPayment(
                paymentKey: Constants.paymentKey,
                paymentRequestId: Constants.paymentRequestId,
                balanceId: Constants.balanceGBP.id,
                profileId: Constants.profileId
            )
        )

        XCTAssertEqual(
            result.error?.localizedDescription,
            PayWithWiseV2Error.fetchingQuoteFailed(error: expectedError).localizedDescription
        )
    }
}

// MARK: - Attachment loading

extension PayWithWiseInteractorTests {
    func testAttachmentLoading_GivenSuccess_ThenCorrectValuesReturned() throws {
        let expectedURL = URL.canned
        let attachmentFile = PayerAttachmentFile.build(id: "id")
        attachmentFileService.downloadPayerFileReturnValue = .just(expectedURL)

        let result = try awaitPublisher(
            interactor.loadAttachment(
                paymentKey: Constants.paymentKey,
                attachmentFile: attachmentFile,
                paymentRequestId: Constants.paymentRequestId
            )
        )

        XCTAssertEqual(
            attachmentFileService.downloadPayerFileReceivedArguments?.key,
            Constants.paymentKey
        )
        XCTAssertEqual(
            attachmentFileService.downloadPayerFileReceivedArguments?.file,
            attachmentFile
        )
        XCTAssertEqual(
            attachmentFileService.downloadPayerFileReceivedArguments?.requestId,
            Constants.paymentRequestId
        )

        XCTAssertEqual(
            result.value,
            expectedURL
        )
    }

    func testAttachmentLoading_GivenFailure_ThenCorrectErrorsReturned() throws {
        let expectedError = AttachmentFileDownloadError.saveError
        attachmentFileService.downloadPayerFileReturnValue = .fail(with: expectedError)

        let result = try awaitPublisher(
            interactor.loadAttachment(
                paymentKey: Constants.paymentKey,
                attachmentFile: PayerAttachmentFile.canned,
                paymentRequestId: Constants.paymentRequestId
            )
        )

        XCTAssertEqual(
            result.error?.localizedDescription,
            PayWithWiseV2Error.savingAttachmentFailed.localizedDescription
        )
    }
}

// MARK: - Request rejection

extension PayWithWiseInteractorTests {
    func testRequestRejection_GivenSuccess_ThenCorrectValuesReturned() throws {
        let expectedStatus = OwedPaymentRequestStatusUpdate.build(
            id: PaymentRequestId("3")
        )
        owedPaymentRequestUseCase.invalidateRequestReturnValue = .just(expectedStatus)

        let result = try awaitPublisher(
            interactor.rejectRequest(
                paymentRequestId: Constants.paymentRequestId,
                profileId: Constants.profileId
            )
        )

        XCTAssertEqual(
            owedPaymentRequestUseCase.invalidateRequestReceivedArguments?.profileId,
            Constants.profileId
        )
        XCTAssertEqual(
            owedPaymentRequestUseCase.invalidateRequestReceivedArguments?.paymentRequestId,
            Constants.paymentRequestId
        )
        XCTAssertEqual(result.value, expectedStatus)
    }

    func testRequestRejection_GivenFailure_ThenCorrectErrorsReturned() throws {
        let expectedError = MockError.dummy
        owedPaymentRequestUseCase.invalidateRequestReturnValue = .fail(
            with: expectedError
        )

        let result = try awaitPublisher(
            interactor.rejectRequest(
                paymentRequestId: Constants.paymentRequestId,
                profileId: Constants.profileId
            )
        )

        XCTAssertEqual(
            owedPaymentRequestUseCase.invalidateRequestReceivedArguments?.profileId,
            Constants.profileId
        )
        XCTAssertEqual(
            owedPaymentRequestUseCase.invalidateRequestReceivedArguments?.paymentRequestId,
            Constants.paymentRequestId
        )
        XCTAssertEqual(
            result.error?.localizedDescription,
            PayWithWiseV2Error.rejectingPaymentFailed(error: expectedError).localizedDescription
        )
    }
}

// MARK: - Payment

extension PayWithWiseInteractorTests {
    func testPayment_GivenSuccess_ThenCorrectValuesReturned() throws {
        let expectedSession = PaymentRequestSession.build(id: "asd")
        let expectedRequest = PayWithWisePaymentRequest.build(
            source: PayWithWisePaymentRequest.Source.build(
                id: String(Constants.balanceGBP.id.value),
                type: "BALANCE"
            )
        )

        payWithWiseUseCase.payReturnValue = .just(PayWithWisePayment.canned)
        let result = try awaitPublisher(
            interactor.pay(
                session: expectedSession,
                profileId: Constants.profileId,
                balanceId: Constants.balanceGBP.id
            )
        )
        XCTAssertEqual(
            payWithWiseUseCase.payReceivedArguments?.session,
            expectedSession
        )
        XCTAssertEqual(
            payWithWiseUseCase.payReceivedArguments?.profileId,
            Constants.profileId
        )
        XCTAssertEqual(
            payWithWiseUseCase.payReceivedArguments?.request,
            expectedRequest
        )
        XCTAssertNotNil(result.value)
    }

    func testPayment_GivenFailure_ThenErrorsValuesReturned() throws {
        var expectedError = PayWithWisePaymentError.cancelledByUser
        payWithWiseUseCase.payReturnValue = .fail(with: expectedError)
        var result = try awaitPublisher(
            interactor.pay(
                session: PaymentRequestSession.canned,
                profileId: Constants.profileId,
                balanceId: Constants.balanceGBP.id
            )
        )

        XCTAssertEqual(
            result.error?.localizedDescription,
            PayWithWiseV2Error.paymentFailed(
                error: PayWithWisePaymentError.cancelledByUser
            ).localizedDescription
        )

        expectedError = PayWithWisePaymentError.sourceUnavailable(message: "A")
        payWithWiseUseCase.payReturnValue = .fail(with: expectedError)
        result = try awaitPublisher(
            interactor.pay(
                session: PaymentRequestSession.canned,
                profileId: Constants.profileId,
                balanceId: Constants.balanceGBP.id
            )
        )

        XCTAssertEqual(
            result.error?.localizedDescription,
            PayWithWiseV2Error.paymentFailed(error: expectedError).localizedDescription
        )
    }
}

// MARK: - Image loading

extension PayWithWiseInteractorTests {
    func testImageLoading_GivenSuccess_ThenCorrectResultsReturned() throws {
        let expectedURL = URL.canned
        let expectedImage = CGImage.canned
        imageLoader.fetchUrlReturnValue = .just(expectedImage)
        let result = try awaitPublisher(
            interactor.loadImage(url: expectedURL)
        )
        XCTAssertEqual(imageLoader.fetchUrlReceivedUrl, expectedURL)
        XCTAssertEqual(result.value, UIImage(cgImage: expectedImage))
    }

    func testImageLoading_GivenFailure_ThenErrorErased() throws {
        imageLoader.fetchUrlReturnValue = .fail(with: MockError.dummy)
        let result = try awaitPublisher(
            interactor.loadImage(url: URL.canned)
        )
        XCTAssertNil(result.error)
        XCTAssertEqual(result.value, UIImage?.none)
    }
}

// MARK: - Helpers

private extension PayWithWiseInteractorTests {
    func makeInteractor(
        source: PayWithWiseFlow.PaymentInitializationSource = .canned
    ) {
        interactor = PayWithWiseInteractorImpl(
            source: source,
            payWithWiseUseCase: payWithWiseUseCase,
            balancesUseCase: balancesUseCase,
            owedPaymentRequestUseCase: owedPaymentRequestUseCase,
            attachmentFileService: attachmentFileService,
            imageLoader: imageLoader
        )
    }
}
