import Foundation

enum PaymentMethodsDynamicFormId: String {
    case waitlistFormId = "acquiringOnboardingWaitlistForm"
    case acquiringEvidenceCollectionFormId = "acquiringOnboardingProcessEvidenceCollectionForm"
    case acquiringOnboardingConsentFormId = "acquiringOnboardingConsentForm"
}

// sourcery: AutoMockable
protocol PaymentMethodsDelegate: AnyObject {
    func refreshPaymentMethods()
    func trackDynamicFlowFailed()
}
