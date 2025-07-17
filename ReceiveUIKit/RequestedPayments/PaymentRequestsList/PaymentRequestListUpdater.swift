import Foundation

// sourcery: AutoMockable
protocol PaymentRequestListUpdater: AnyObject {
    func requestStatusUpdated()
    func invoiceRequestCreated()
}
