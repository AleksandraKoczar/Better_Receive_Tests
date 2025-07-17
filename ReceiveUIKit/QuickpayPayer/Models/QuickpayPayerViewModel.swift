import Combine
import Neptune

// sourcery: AutoEquatableForTest
struct QuickpayPayerViewModel {
    // sourcery: skipEquality
    let avatar: AnyPublisher<AvatarViewModel, Never>
    let businessName: String
    let subtitle: String
    let moneyInputViewModel: MoneyInputViewModel
    let description: String?
}
