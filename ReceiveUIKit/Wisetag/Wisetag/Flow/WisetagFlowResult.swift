import Foundation

// sourcery: AutoEquatableForTest
public enum WisetagFlowResult {
    case completed(isShareableLinkDiscoverable: Bool)
    case abort
}
