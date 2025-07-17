import DeepLinkKit
import Neptune
import TWFoundation
import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
public protocol QuickpayFlowFactory {
    func makeFlow(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<QuickpayFlowResult>
}

public class QuickpayFlowFactoryImpl: QuickpayFlowFactory {
    private let allDeepLinksUIFactory: AllDeepLinksUIFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let accountDetailsFlowFactory: SingleAccountDetailsFlowFactory
    private let feedbackService: FeedbackService

    public init(
        allDeepLinksUIFactory: AllDeepLinksUIFactory = GOS[AllDeepLinksUIFactoryKey.self],
        accountDetailsFlowFactory: SingleAccountDetailsFlowFactory,
        feedbackService: FeedbackService,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) {
        self.allDeepLinksUIFactory = allDeepLinksUIFactory
        self.accountDetailsFlowFactory = accountDetailsFlowFactory
        self.feedbackService = feedbackService
        self.webViewControllerFactory = webViewControllerFactory
    }

    public func makeFlow(
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<QuickpayFlowResult> {
        QuickpayFlow(
            profile: profile,
            viewControllerFactory: WisetagViewControllerFactoryImpl(),
            qrDownloadViewControllerFactory: QRDownloadViewControllerFactoryImpl(),
            viewControllerPresenterFactory: ViewControllerPresenterFactoryImpl(),
            feedbackFlowFactory: AutoSubmittingFeedbackFlowFactoryImpl(),
            paymentMethodsDynamicFlowHandler: PaymentMethodsDynamicFlowHandlerImpl(navigationController: navigationController),
            feedbackService: feedbackService,
            accountDetailsFlowFactory: accountDetailsFlowFactory,
            webViewControllerFactory: webViewControllerFactory,
            navigationController: navigationController,
            allDeepLinksUIFactory: allDeepLinksUIFactory,
            cameraRollPermissionFlowFactory: CameraPermissionFlowFactoryImpl()
        )
    }
}
