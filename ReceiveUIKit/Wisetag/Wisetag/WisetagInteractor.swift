import BalanceKit
import Combine
import ReceiveKit
import TWFoundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoEquatableForTest
enum WisetagNextStep {
    case showStory
    case showADFlow
    case showWisetag(
        image: UIImage?,
        status: ShareableLinkStatus,
        isCardsEnabled: Bool
    )
}

// sourcery: AutoMockable
protocol WisetagInteractor: AnyObject {
    func fetchNextStep() -> AnyPublisher<WisetagNextStep, Error>
    func fetchQRCode(status: ShareableLinkStatus, link: String?) -> AnyPublisher<
        (ShareableLinkStatus, UIImage?),
        Error
    >
    func updateShareableLinkStatus(
        profileId: ProfileId,
        isDiscoverable: Bool
    ) -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error>
    func shouldShowNudge(profileId: ProfileId, nudgeType: CardNudgeType) -> Bool
    func setShouldShowNudge(_ shouldShow: Bool, profileId: ProfileId, nudgeType: CardNudgeType)
    func fetchCardDynamicForms() -> AnyPublisher<
        [PaymentMethodDynamicForm],
        Error
    >
}

final class WisetagInteractorImpl {
    private let profile: Profile
    private let wisetagUseCase: WisetagUseCase
    private let accountDetailsUseCase: AccountDetailsUseCase
    private let paymentMethodsUseCase: PaymentMethodsUseCase
    private let codableStore: CodableKeyValueStore
    private let paymentRequestUseCase: PaymentRequestUseCaseV2

    enum Constants {
        static let cardOnboardingNudgeKey = "Quickpay.shouldShowCardOnboardingNudge"
        static let cardWaitlistNudgeKey = "Quickpay.shouldShowCardWaitlistNudge"
        static let defaultAmount: Decimal = 1.0
        static let defaultCurrency: CurrencyCode = .GBP
    }

    private struct PersistedPreference: Codable {
        let profileId: Int64
        let preference: Bool
    }

    init(
        profile: Profile,
        wisetagUseCase: WisetagUseCase,
        accountDetailsUseCase: AccountDetailsUseCase,
        paymentMethodsUseCase: PaymentMethodsUseCase,
        paymentRequestUseCase: PaymentRequestUseCaseV2,
        codableStore: CodableKeyValueStore = UserDefaults.standard
    ) {
        self.profile = profile
        self.wisetagUseCase = wisetagUseCase
        self.accountDetailsUseCase = accountDetailsUseCase
        self.paymentMethodsUseCase = paymentMethodsUseCase
        self.paymentRequestUseCase = paymentRequestUseCase
        self.codableStore = codableStore
    }
}

extension WisetagInteractorImpl: WisetagInteractor {
    typealias DynamicForm = PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability.ReceiverCurrencyAvailabilityPaymentMethod.DynamicForm

    func fetchCardDynamicForms() -> AnyPublisher<[DynamicForm], Error> {
        paymentRequestUseCase.fetchReceiverCurrencyAvailability(
            profileId: profile.id,
            amount: Constants.defaultAmount,
            currencies: [Constants.defaultCurrency],
            paymentMethods: PaymentRequestV2PaymentMethods.allCases.filter { $0 != .unknown },
            onlyPreferredPaymentMethods: true
        )
        .flatMap { receiverAvailability -> AnyPublisher<[DynamicForm], Error> in
            var forms: [DynamicForm] = []
            receiverAvailability.currencies[0].paymentMethods.forEach { paymentMethod in
                guard paymentMethod.type == .card,
                      case let .requiresUserAction(dynamicForms: dynamicForms) = paymentMethod.unavailabilityReason else {
                    return
                }
                forms = dynamicForms
            }
            return .just(forms)
        }
        .eraseToAnyPublisher()
    }

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

    func updateShareableLinkStatus(profileId: ProfileId, isDiscoverable: Bool)
        -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error> {
        wisetagUseCase.updateShareableLinkStatus(profileId: profileId, isDiscoverable: isDiscoverable)
            .flatMap { [weak self] status -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error> in
                guard let self else {
                    return .just((status, nil))
                }
                return fetchQRCode(status: status, link: nil)
            }
            .eraseToAnyPublisher()
    }

    func fetchNextStep() -> AnyPublisher<WisetagNextStep, Error> {
        wisetagUseCase.shareableLinkStatus(for: profile.id)
            .flatMap { [weak self] status -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error> in
                guard let self else {
                    return .just((status, nil))
                }
                return fetchQRCode(status: status, link: nil)
            }
            .flatMap { [weak self] status, image -> AnyPublisher<(ShareableLinkStatus, UIImage?, Bool), Error> in
                guard let self else {
                    return .fail(with: WisetagError.loadingError(error: GenericError("deallocated")))
                }
                return accountDetailsStep(status: status, image: image)
            }
            .combineLatest(isCardsEnabled().setFailureType(to: Error.self))
            .tryMap { [weak self] tuple1, isCardsEnabled in
                guard let self else {
                    throw WisetagError.loadingError(error: GenericError("deallocated"))
                }
                let (status, image, isEligible) = tuple1
                switch status {
                case .ineligible:
                    throw WisetagError.ineligible
                case let .eligible(discoverability):
                    if isEligible {
                        switch discoverability {
                        case .discoverable:
                            return WisetagNextStep.showWisetag(image: image, status: status, isCardsEnabled: isCardsEnabled)
                        case .notDiscoverable:
                            if wisetagUseCase.shouldShowStory(for: profile.id) {
                                wisetagUseCase.setShouldShowStory(false, for: profile.id)
                                return WisetagNextStep.showStory
                            } else {
                                return WisetagNextStep.showWisetag(
                                    image: image,
                                    status: status,
                                    isCardsEnabled: isCardsEnabled
                                )
                            }
                        }
                    } else {
                        return WisetagNextStep.showADFlow
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchQRCode(status: ShareableLinkStatus, link: String?) -> AnyPublisher<
        (ShareableLinkStatus, UIImage?),
        Error
    > {
        guard case let .eligible(discoverability) = status else {
            return .just((status, nil))
        }
        let content: String = { branding in
            switch discoverability {
            case .notDiscoverable:
                return branding.urlString
            case let .discoverable(urlString, _):
                guard let link else {
                    return urlString
                }
                return link
            }
        }(Branding.current)
        return wisetagUseCase.qrCode(content: content)
            .map { image in
                (status, image)
            }
            .catch { _ -> AnyPublisher<(ShareableLinkStatus, UIImage?), Error> in
                .just((status, nil))
            }
            .eraseToAnyPublisher()
    }
}

private extension WisetagInteractorImpl {
    private func accountDetailsStep(
        status: ShareableLinkStatus,
        image: UIImage?
    ) -> AnyPublisher<
        (ShareableLinkStatus, UIImage?, Bool),
        Error
    > {
        checkAccountDetails()
            .map { isEligible in
                (status, image, isEligible)
            }
            .catch { _ -> AnyPublisher<(ShareableLinkStatus, UIImage?, Bool), Error> in
                .just((status, nil, true))
            }
            .eraseToAnyPublisher()
    }

    private func isCardsEnabled() -> AnyPublisher<Bool, Never> {
        paymentMethodsUseCase.cardAvailability(profileId: profile.id)
            .map { availability in
                guard case .available = availability else {
                    return false
                }
                return true
            }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    private func checkAccountDetails() -> AnyPublisher<Bool, Error> {
        accountDetailsUseCase.accountDetails
            .handleEvents(receiveOutput: { [weak self] state in
                if state == nil {
                    self?.accountDetailsUseCase.refreshAccountDetails()
                }
            })
            .compactMap { state -> Bool in
                switch state {
                case let .loaded(details):
                    return details.contains { $0.isActive }
                case .recoverableError,
                     .loading,
                     .none:
                    return false
                }
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
