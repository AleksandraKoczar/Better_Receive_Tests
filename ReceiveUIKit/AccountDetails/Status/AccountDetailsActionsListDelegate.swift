import Foundation

// sourcery: AutoMockable
public protocol AccountDetailsActionsListDelegate: AnyObject {
    func nextStep()
    func dismiss()
}
