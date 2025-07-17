import BalanceKit
import Combine
import Foundation
import HttpClientKit
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PayWithWiseInteractor: AnyObject {
    func gatherPaymentKey(
        profileId: ProfileId
    ) -> AnyPublisher<String, PayWithWiseV2Error>

    func paymentRequestLookup(
        paymentKey: String
    ) -> AnyPublisher<PaymentRequestLookup, PayWithWiseV2Error>

    func balances(
        amount: Money,
        profileId: ProfileId,
        needsRefresh: Bool
    ) -> AnyPublisher<PayWithWiseInteractorImpl.BalanceFetchingResult, PayWithWiseV2Error>

    func createPayment(
        paymentKey: String,
        paymentRequestId: PaymentRequestId,
        balanceId: BalanceId,
        profileId: ProfileId
    ) -> AnyPublisher<(PaymentRequestSession, PayWithWiseQuote), PayWithWiseV2Error>

    func acquiringPaymentLookup(
        paymentSession: QuickpayAcquiringPaymentSession,
        acquiringPaymentId: AcquiringPaymentId
    ) -> AnyPublisher<QuickpayAcquiringPayment, PayWithWiseV2Error>

    func createQuickpayQuote(
        session: PaymentRequestSession,
        balanceId: BalanceId,
        profileId: ProfileId
    ) -> AnyPublisher<PayWithWiseQuote, PayWithWiseV2Error>

    func loadAttachment(
        paymentKey: String,
        attachmentFile: PayerAttachmentFile,
        paymentRequestId: PaymentRequestId
    ) -> AnyPublisher<URL, PayWithWiseV2Error>

    func rejectRequest(
        paymentRequestId: PaymentRequestId,
        profileId: ProfileId
    ) -> AnyPublisher<OwedPaymentRequestStatusUpdate, PayWithWiseV2Error>

    func pay(
        session: PaymentRequestSession,
        profileId: ProfileId,
        balanceId: BalanceId
    ) -> AnyPublisher<PayWithWisePayment, PayWithWiseV2Error>

    func loadImage(url: URL) -> AnyPublisher<UIImage?, Never>
}

final class PayWithWiseInteractorImpl {
    // sourcery: AutoEquatableForTest, Buildable
    struct BalanceFetchingResult {
        // sourcery: AutoEquatableForTest, Buildable
        struct AutoSelectionResult {
            let balance: Balance
            let hasSameCurrencyBalance: Bool
            let hasFunds: Bool
        }

        let autoSelectionResult: AutoSelectionResult
        let fundableBalances: [Balance]
        let balances: [Balance]
    }

    private enum Constants {
        static let defaultPaymentType = "BALANCE"
    }

    private let payWithWiseUseCase: PayWithWiseUseCase
    private let balancesUseCase: BalancesUseCase
    private let owedPaymentRequestUseCase: OwedPaymentRequestUseCase
    private let attachmentFileService: AttachmentFileService
    private let imageLoader: ImageLoader

    private let source: PayWithWiseFlow.PaymentInitializationSource

    init(
        source: PayWithWiseFlow.PaymentInitializationSource,
        payWithWiseUseCase: PayWithWiseUseCase,
        balancesUseCase: BalancesUseCase,
        owedPaymentRequestUseCase: OwedPaymentRequestUseCase,
        attachmentFileService: AttachmentFileService,
        imageLoader: ImageLoader = ImageLoaderFactory.shared
    ) {
        self.source = source
        self.payWithWiseUseCase = payWithWiseUseCase
        self.balancesUseCase = balancesUseCase
        self.owedPaymentRequestUseCase = owedPaymentRequestUseCase
        self.attachmentFileService = attachmentFileService
        self.imageLoader = imageLoader
    }
}

// MARK: - PayWithWiseInteractor

extension PayWithWiseInteractorImpl: PayWithWiseInteractor {
    // MARK: - Information fetching & session creation

    func gatherPaymentKey(
        profileId: ProfileId
    ) -> AnyPublisher<String, PayWithWiseV2Error> {
        switch source {
        case let .quickpay(key, _):
            .just(key.businessQuickpay)
        case let .paymentKey(source):
            .just(source.paymentKey)
        case let .paymentRequestId(paymentRequestId):
            owedPaymentRequestUseCase.owedPaymentRequest(
                paymentRequestId: paymentRequestId,
                profileId: profileId
            )
            .map { $0.linkKey }
            .mapError { PayWithWiseV2Error.fetchingPaymentKeyFailed(error: $0) }
            .eraseToAnyPublisher()
        }
    }

    func paymentRequestLookup(
        paymentKey: String
    ) -> AnyPublisher<PaymentRequestLookup, PayWithWiseV2Error> {
        payWithWiseUseCase.paymentRequestInfo(key: paymentKey)
            .mapError {
                PayWithWiseV2Error.fetchingPaymentRequestInfoFailed(error: $0)
            }
            .eraseToAnyPublisher()
    }

    func balances(
        amount: Money,
        profileId: ProfileId,
        needsRefresh: Bool
    ) -> AnyPublisher<BalanceFetchingResult, PayWithWiseV2Error> {
        Publishers.CombineLatest(
            balancesUseCase.balancesCanFund(amount: amount, profileId: profileId)
                .mapError { PayWithWiseV2Error.fetchingFundableBalancesFailed(error: $0) }
                .eraseToAnyPublisher(),
            balancesPublisher(
                profileId: profileId,
                needsRefresh: needsRefresh
            )
            .mapError { PayWithWiseV2Error.fetchingBalancesFailed(error: $0) }
            .eraseToAnyPublisher()
        )
        .flatMap { fundableBalances, balances -> AnyPublisher<BalanceFetchingResult, PayWithWiseV2Error> in
            let balanceSelectionResult = Self.findConvenientBalance(
                amount: amount,
                fundableBalances: fundableBalances,
                balances: balances
            )
            switch balanceSelectionResult {
            case let .success(autoSelectionResult):
                let balanceFetchingResult = BalanceFetchingResult(
                    autoSelectionResult: autoSelectionResult,
                    fundableBalances: fundableBalances,
                    balances: balances
                )
                return .just(balanceFetchingResult)
            case let .failure(error):
                return .fail(with: error)
            }
        }
        .eraseToAnyPublisher()
    }

    func acquiringPaymentLookup(
        paymentSession: QuickpayAcquiringPaymentSession,
        acquiringPaymentId: AcquiringPaymentId
    ) -> AnyPublisher<QuickpayAcquiringPayment, PayWithWiseV2Error> {
        payWithWiseUseCase.getAcquiringPayment(
            paymentSession: paymentSession,
            acquiringPaymentId: acquiringPaymentId
        )
        .mapError { _ in
            PayWithWiseV2Error.fetchingAcquiringPaymentFailed
        }
        .eraseToAnyPublisher()
    }

    func createQuickpayQuote(
        session: PaymentRequestSession,
        balanceId: BalanceId,
        profileId: ProfileId
    ) -> AnyPublisher<PayWithWiseQuote, PayWithWiseV2Error> {
        payWithWiseUseCase.quote(
            session: session,
            profileId: profileId,
            request: PayWithWisePaymentRequest(
                source: PayWithWisePaymentRequest.Source(
                    id: String(balanceId.value),
                    type: Constants.defaultPaymentType
                )
            )
        )
        .mapError {
            PayWithWiseV2Error.fetchingQuoteFailed(error: $0)
        }
        .eraseToAnyPublisher()
    }

    func createPayment(
        paymentKey: String,
        paymentRequestId: PaymentRequestId,
        balanceId: BalanceId,
        profileId: ProfileId
    ) -> AnyPublisher<(PaymentRequestSession, PayWithWiseQuote), PayWithWiseV2Error> {
        payWithWiseUseCase.createPayment(
            key: paymentKey,
            requestId: paymentRequestId
        )
        .mapError { PayWithWiseV2Error.fetchingSessionFailed(error: $0) }
        .eraseToAnyPublisher()
        .flatMap { [unowned self] session -> AnyPublisher<(PaymentRequestSession, PayWithWiseQuote), PayWithWiseV2Error> in
            let quotePublisher = payWithWiseUseCase.quote(
                session: session,
                profileId: profileId,
                request: PayWithWisePaymentRequest(
                    source: PayWithWisePaymentRequest.Source(
                        id: String(balanceId.value),
                        type: Constants.defaultPaymentType
                    )
                )
            )
            .mapError { PayWithWiseV2Error.fetchingQuoteFailed(error: $0) }
            .eraseToAnyPublisher()
            return AnyPublisher<PaymentRequestSession, PayWithWiseV2Error>
                .just(session)
                .combineLatest(quotePublisher)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Attachment

    func loadAttachment(
        paymentKey: String,
        attachmentFile: PayerAttachmentFile,
        paymentRequestId: PaymentRequestId
    ) -> AnyPublisher<URL, PayWithWiseV2Error> {
        attachmentFileService.downloadPayerFile(
            key: paymentKey,
            requestId: paymentRequestId,
            file: attachmentFile
        )
        .mapError {
            switch $0 {
            case .downloadError:
                .downloadingAttachmentFailed
            case .saveError:
                .savingAttachmentFailed
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Rejection

    func rejectRequest(
        paymentRequestId: PaymentRequestId,
        profileId: ProfileId
    ) -> AnyPublisher<OwedPaymentRequestStatusUpdate, PayWithWiseV2Error> {
        owedPaymentRequestUseCase.invalidateRequest(
            paymentRequestId: paymentRequestId,
            profileId: profileId
        )
        .mapError { PayWithWiseV2Error.rejectingPaymentFailed(error: $0) }
        .eraseToAnyPublisher()
    }

    // MARK: - Payment

    func pay(
        session: PaymentRequestSession,
        profileId: ProfileId,
        balanceId: BalanceId
    ) -> AnyPublisher<PayWithWisePayment, PayWithWiseV2Error> {
        payWithWiseUseCase.pay(
            session: session,
            profileId: profileId,
            request: PayWithWisePaymentRequest(
                source: PayWithWisePaymentRequest.Source(
                    id: String(balanceId.value),
                    type: Constants.defaultPaymentType
                )
            )
        )
        .mapError { error in
            PayWithWiseV2Error.paymentFailed(error: error)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Image loading

    func loadImage(url: URL) -> AnyPublisher<UIImage?, Never> {
        imageLoader.fetchUrl(url)
            .map {
                UIImage(cgImage: $0)
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}

// MARK: - Filtering & Selection

private extension PayWithWiseInteractorImpl {
    func balancesPublisher(
        profileId: ProfileId,
        needsRefresh: Bool
    ) -> AnyPublisher<[Balance], Error> {
        balancesUseCase.listenToBalances(
            for: profileId,
            strategy: needsRefresh
                ? .loadElseUseCache
                : .expirableCacheAfter(60 * 5)
        ).map {
            $0.filter {
                $0.balanceType == .standard
                    && $0.isVisible
                    && $0.isPrimary // we can send money only from primary balances
            }
        }
        .eraseToAnyPublisher()
    }

    static func findConvenientBalance(
        amount: Money,
        fundableBalances: [Balance],
        balances: [Balance]
    ) -> Result<BalanceFetchingResult.AutoSelectionResult, PayWithWiseV2Error> {
        guard let firstBalance = balances.first else {
            return .failure(.noBalancesAvailable)
        }

        if let fundableSameCurrencyBalance = fundableBalances.first(where: {
            $0.currency == amount.currency
        }) {
            return .success(
                .init(
                    balance: fundableSameCurrencyBalance,
                    hasSameCurrencyBalance: true,
                    hasFunds: true
                )
            )
        }

        let sameCurrencyBalances = balances.filter {
            $0.currency == amount.currency
        }
        let hasSameCurrencyBalance = sameCurrencyBalances.isNonEmpty

        guard let biggestBalance = fundableBalances.first else {
            let balance = sameCurrencyBalances.first ?? firstBalance
            return .success(
                .init(
                    balance: balance,
                    hasSameCurrencyBalance: hasSameCurrencyBalance,
                    hasFunds: false
                )
            )
        }

        return .success(
            .init(
                balance: biggestBalance,
                hasSameCurrencyBalance: hasSameCurrencyBalance,
                hasFunds: true
            )
        )
    }
}
