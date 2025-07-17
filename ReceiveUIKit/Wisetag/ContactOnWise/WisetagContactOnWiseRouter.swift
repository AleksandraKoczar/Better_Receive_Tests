import Foundation

// sourcery: AutoMockable
protocol WisetagContactOnWiseRouter: AnyObject {
    func dismissAndUpdateShareableLinkStatus(didChangeDiscoverability: Bool, isDiscoverable: Bool)
}
