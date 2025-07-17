import Foundation
import WiseCore

// sourcery: AutoMockable
protocol ReceiveRestrictionRoutingDelegate: AnyObject {
    func handleURI(_ uri: URI)
    func dismiss()
}
