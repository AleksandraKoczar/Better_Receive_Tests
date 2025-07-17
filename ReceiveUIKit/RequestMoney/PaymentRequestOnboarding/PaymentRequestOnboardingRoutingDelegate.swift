import Foundation

// sourcery: AutoMockable
protocol PaymentRequestOnboardingRoutingDelegate: AnyObject {
    func moveToNextStepAfterOnboarding(isOnboardingRequired: Bool)
    func dismiss()
}
