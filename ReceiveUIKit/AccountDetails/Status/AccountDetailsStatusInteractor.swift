import Combine
import ReceiveKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol AccountDetailsStatusInteractor {
    func status(
        profileId: ProfileId,
        currencyCode: CurrencyCode
    ) -> AnyPublisher<AccountDetailsStatus, Error>
}

final class AccountDetailsStatusInteractorImpl {
    private let service: AccountDetailsStatusService

    init(
        service: AccountDetailsStatusService
    ) {
        self.service = service
    }
}

extension AccountDetailsStatusInteractorImpl: AccountDetailsStatusInteractor {
    func status(
        profileId: ProfileId,
        currencyCode: CurrencyCode
    ) -> AnyPublisher<AccountDetailsStatus, Error> {
        service.accountDetailsStatus(
            profileId: profileId,
            currency: currencyCode
        )
    }
}
