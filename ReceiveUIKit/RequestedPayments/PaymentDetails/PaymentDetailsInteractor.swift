import Combine
import ReceiveKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentDetailsInteractor: AnyObject {
    func paymentDetails(profileId: ProfileId) -> AnyPublisher<PaymentDetails, Error>
}
