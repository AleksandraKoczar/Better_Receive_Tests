import PreloadKit
import UserKit

// sourcery: AutoMockable
public protocol ReceiveEligibilityService {
    func mcaEligibility(profile: Profile) -> MCAEligibility
}
