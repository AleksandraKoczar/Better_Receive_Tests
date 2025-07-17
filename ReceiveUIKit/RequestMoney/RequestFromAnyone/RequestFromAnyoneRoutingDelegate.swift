import Foundation

// sourcery: AutoMockable
protocol RequestFromAnyoneRoutingDelegate: AnyObject {
    func addAmountAndNote()
    func useOldFlow()
    func endFlow()
}
