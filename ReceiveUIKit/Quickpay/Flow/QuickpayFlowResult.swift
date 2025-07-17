import Foundation

// sourcery: AutoEquatableForTest
public enum QuickpayFlowResult {
    case completed(isShareableLinkDiscoverable: Bool)
    case abort
}
