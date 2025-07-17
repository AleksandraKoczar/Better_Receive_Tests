import ContactsKit
import Neptune
import TWFoundation
import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
public protocol WisetagScannedProfileFlowFactory {
    func makeFlow(
        nickname: String,
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void>
}

public class WisetagScannedProfileFlowFactoryImpl: WisetagScannedProfileFlowFactory {
    private let requestMoneyFlowFactory: RequestMoneyFlowFactory
    private let wisetagTransferFlowFactory: WisetagScannedProfileTransferFlowFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type

    public init(
        requestMoneyFlowFactory: RequestMoneyFlowFactory,
        wisetagTransferFlowFactory: WisetagScannedProfileTransferFlowFactory,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) {
        self.requestMoneyFlowFactory = requestMoneyFlowFactory
        self.wisetagTransferFlowFactory = wisetagTransferFlowFactory
        self.webViewControllerFactory = webViewControllerFactory
    }

    public func makeFlow(
        nickname: String,
        profile: Profile,
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        let wisetagContactInteractor = WisetagContactInteractorFactory.make(
            profileId: profile.id,
            uriImageLoader: URIImageLoaderImpl(),
            svgImageLoader: ImageCacheImpl()
        )
        return WisetagScannedProfileFlow(
            profile: profile,
            nickname: nickname,
            navigationController: navigationController,
            requestMoneyFlowFactory: requestMoneyFlowFactory,
            transferFlowFactory: wisetagTransferFlowFactory,
            viewControllerFactory: WisetagScannedProfileViewControllerFactoryImp(
                wisetagContactInteractor: wisetagContactInteractor
            ),
            viewControllerPresenterFactory: ViewControllerPresenterFactoryImpl(),
            wisetagContactInteractor: wisetagContactInteractor,
            webViewControllerFactory: webViewControllerFactory,
            scheduler: .main
        )
    }
}
