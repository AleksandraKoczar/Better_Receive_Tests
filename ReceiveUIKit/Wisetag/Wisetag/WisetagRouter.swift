import DeepLinkKit
import Foundation
import UIKit
import WiseCore

// sourcery: AutoMockable
protocol WisetagRouter: AnyObject {
    func startAccountDetailsFlow(host: UIViewController)
    func showWisetagLearnMore(route: DeepLinkStoryRoute)
    func showScanQRcode()
    func showContactOnWise(nickname: String?)
    func showDownload(image: UIImage)
    func dismiss(isShareableLinkDiscoverable: Bool)
    func showStory(route: DeepLinkStoryRoute)
    func showLearnMoreStory(route: DeepLinkStoryRoute)
}
