import DeepLinkKit
import ReceiveKit
import TWUI
import UIKit

// sourcery: AutoMockable
protocol QuickpayRouter: AnyObject {
    func showIntroStory(route: DeepLinkStoryRoute)
    func showInPersonStory()
    func showManageQuickpay(nickname: String?)
    func showDiscoverability(nickname: String?)
    func showPaymentMethodsOnWeb()
    func showHelpArticle(url: String)
    func startDownload(image: UIImage)
    func startAccountDetailsFlow(host: UIViewController)
    func personaliseTapped(status: ShareableLinkStatus.Discoverability)
    func shareLinkTapped(link: String)
    func dismiss(isShareableLinkDiscoverable: Bool)
    func showFeedback(model: FeedbackViewModel, context: FeedbackContext, onSuccess: @escaping (() -> Void))
    func showDynamicFormsMethodManagement(
        _ dynamicForms: [PaymentMethodDynamicForm],
        delegate: PaymentMethodsDelegate?
    )
}
