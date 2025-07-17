import Combine
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol CreatePaymentRequestInteractor: AnyObject {
    func shouldShowNudge(profileId: ProfileId, nudgeType: CardNudgeType) -> Bool
    func setShouldShowNudge(_ shouldShow: Bool, profileId: ProfileId, nudgeType: CardNudgeType)
    func fetchEligibilityAndDefaultRequestType() -> AnyPublisher<(RequestMoneyProductEligibility, RequestType), Error>
    func fetchEligibleBalances() -> AnyPublisher<PaymentRequestEligibleBalances, Error>
    func createPaymentRequest(
        body: PaymentRequestBodyV2
    ) -> AnyPublisher<PaymentRequestV2, PaymentRequestUseCaseError>
    func fetchReceiverCurrencyAvailability(
        amount: Decimal,
        currencies: [CurrencyCode],
        paymentMethods: [PaymentRequestV2PaymentMethods],
        onlyPreferredPaymentMethods: Bool
    ) -> AnyPublisher<PaymentRequestV2ReceiverAvailability, Error>
}

enum CardNudgeType {
    case waitlist
    case onboarding
}

final class CreatePaymentRequestInteractorImpl {
    private let profile: Profile
    private let paymentRequestUseCase: PaymentRequestUseCaseV2
    private let paymentMethodsUseCase: PaymentMethodsUseCase
    private let paymentRequestProductEligibilityUseCase: PaymentRequestProductEligibilityUseCase
    private let paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCase
    private let paymentRequestListUseCase: PaymentRequestListUseCase
    private let paymentRequestDetailsUseCase: PaymentRequestDetailsUseCase
    private let codableStore: CodableKeyValueStore

    enum Constants {
        static let cardOnboardingNudgeKey = "CreatePaymentRequestFlow.shouldShowCardOnboardingNudge"
        static let cardWaitlistNudgeKey = "CreatePaymentRequestFlow.shouldShowCardWaitlistNudge"
    }

    private struct PersistedPreference: Codable {
        let profileId: Int64
        let preference: Bool
    }

    init(
        profile: Profile,
        paymentRequestUseCase: PaymentRequestUseCaseV2,
        paymentMethodsUseCase: PaymentMethodsUseCase,
        paymentRequestProductEligibilityUseCase: PaymentRequestProductEligibilityUseCase,
        paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCase,
        paymentRequestListUseCase: PaymentRequestListUseCase,
        paymentRequestDetailsUseCase: PaymentRequestDetailsUseCase,
        codableStore: CodableKeyValueStore = UserDefaults.standard
    ) {
        self.profile = profile
        self.paymentMethodsUseCase = paymentMethodsUseCase
        self.paymentRequestUseCase = paymentRequestUseCase
        self.paymentRequestEligibilityUseCase = paymentRequestEligibilityUseCase
        self.paymentRequestListUseCase = paymentRequestListUseCase
        self.paymentRequestDetailsUseCase = paymentRequestDetailsUseCase
        self.paymentRequestProductEligibilityUseCase = paymentRequestProductEligibilityUseCase
        self.codableStore = codableStore
    }
}

extension CreatePaymentRequestInteractorImpl: CreatePaymentRequestInteractor {
    func setShouldShowNudge(
        _ shouldShow: Bool,
        profileId: ProfileId,
        nudgeType: CardNudgeType
    ) {
        var key: String {
            switch nudgeType {
            case .onboarding:
                Constants.cardOnboardingNudgeKey
            case .waitlist:
                Constants.cardWaitlistNudgeKey
            }
        }
        let newPreference = PersistedPreference(
            profileId: profileId.value,
            preference: shouldShow
        )
        var preferenceToStore = [newPreference]
        if var persistedPreferences: [PersistedPreference] = codableStore.codableObjectSafe(forKey: key) {
            persistedPreferences.removeAll(where: { $0.profileId == profileId.value })
            preferenceToStore.append(contentsOf: persistedPreferences)
        }
        codableStore.setCodableObjectSafe(
            preferenceToStore,
            forKey: key
        )
    }

    func shouldShowNudge(
        profileId: ProfileId,
        nudgeType: CardNudgeType
    ) -> Bool {
        var key: String {
            switch nudgeType {
            case .onboarding:
                Constants.cardOnboardingNudgeKey
            case .waitlist:
                Constants.cardWaitlistNudgeKey
            }
        }
        guard let persistedPreferences: [PersistedPreference] = codableStore.codableObjectSafe(forKey: key),
              let persistedPreference = persistedPreferences.first(where: { $0.profileId == profileId.value }) else {
            return true
        }
        return persistedPreference.preference
    }

    func fetchEligibilityAndDefaultRequestType() -> AnyPublisher<(RequestMoneyProductEligibility, RequestType), Error> {
        paymentRequestProductEligibilityUseCase
            .productEligibility(profileId: profile.id)
            .combineLatest(
                lastPublishedPaymentRequestType(profileId: profile.id)
                    .setFailureType(to: Error.self)
            )
            .flatMap { eligibility, defaultRequestType -> AnyPublisher<(RequestMoneyProductEligibility, RequestType), Error> in
                let productEligibility = RequestMoneyProductEligibilityMapper.make(from: eligibility)
                switch productEligibility {
                case .singleUseAndReusable:
                    return .just((productEligibility, defaultRequestType))
                case .singleUse:
                    return .just((productEligibility, .singleUse))
                case .reusable:
                    return .just((productEligibility, .reusable))
                case .ineligible:
                    return .fail(with: GenericError("[REC] Profile is ineligible to use request money"))
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchEligibleBalances() -> AnyPublisher<PaymentRequestEligibleBalances, Error> {
        paymentRequestEligibilityUseCase.eligibleBalances(
            profile: profile
        ).eraseToAnyPublisher()
    }

    func createPaymentRequest(
        body: PaymentRequestBodyV2
    ) -> AnyPublisher<PaymentRequestV2, PaymentRequestUseCaseError> {
        paymentRequestUseCase.createPaymentRequest(
            profileId: profile.id,
            body: body
        )
        .eraseToAnyPublisher()
    }

    func fetchReceiverCurrencyAvailability(
        amount: Decimal,
        currencies: [CurrencyCode],
        paymentMethods: [PaymentRequestV2PaymentMethods],
        onlyPreferredPaymentMethods: Bool
    ) -> AnyPublisher<PaymentRequestV2ReceiverAvailability, Error> {
        paymentRequestUseCase.fetchReceiverCurrencyAvailability(
            profileId: profile.id,
            amount: amount,
            currencies: currencies,
            paymentMethods: paymentMethods,
            onlyPreferredPaymentMethods: onlyPreferredPaymentMethods
        ).eraseToAnyPublisher()
    }

    private func lastPublishedPaymentRequestType(
        profileId: ProfileId
    ) -> AnyPublisher<RequestType, Never> {
        let sortDescriptor = PaymentRequestSummariesApiSortDescriptor(
            sortBy: .publishedAt,
            sortOrder: .descend
        )
        return paymentRequestListUseCase.paymentRequestSummaries(
            profileId: profileId,
            statuses: [.published],
            requestTypes: [.reusable, .singleUse],
            sortDescriptor: sortDescriptor,
            pageSize: nil,
            seekPosition: nil
        ).flatMap { summaries -> AnyPublisher<PaymentRequestId, Error> in
            guard let id = summaries.groups.first?.summaries.first?.id else {
                return .fail(with: GenericError("[REC] No payment requests created yet"))
            }
            return .just(PaymentRequestId(id))
        }
        .flatMap { id -> AnyPublisher<PaymentRequestDetails, Error> in
            return self.paymentRequestDetailsUseCase.paymentRequestDetails(profileId: profileId, paymentRequestId: id)
                .eraseToAnyPublisher()
        }
        .map { details in
            guard let requestType = self.mapRequestType(details.type) else {
                return RequestType.reusable
            }
            return requestType
        }
        .replaceError(with: RequestType.reusable)
        .eraseToAnyPublisher()
    }

    private func mapRequestType(_ type: PaymentRequestDetails.RequestType) -> RequestType? {
        switch type {
        case .singleUse:
            .singleUse
        case .reusable:
            .reusable
        case .invoice:
            nil
        case .unknown:
            nil
        }
    }
}
