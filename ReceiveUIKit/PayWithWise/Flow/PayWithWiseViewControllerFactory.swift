import AnalyticsKit
import BalanceKit
import Prism
import ReceiveKit
import TWFoundation
import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
protocol PayWithWiseViewControllerFactory: AnyObject {
    func setFlowNavigationDelegate(_ delegate: PayWithWiseFlowNavigationDelegate)

    func makeViewController(
        profile: Profile,
        host: UINavigationController
    ) -> UIViewController
}

final class PayWithWiseViewControllerFactoryImpl {
    private let balanceFormatter: BalanceFormatter
    private let topUpBalanceFlowFactory: TopUpBalanceFlowFactory
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let profileSwitcherFlowFactory: ProfileSwitcherFlowFactory
    private let appReviewNudgePresenter: AppReviewNudgePresenter
    private let contactsDiscoverabilitySettingsViewControllerFactory: ContactsDiscoverabilitySettingsViewControllerFactoryProtocol
    private let featureService: FeatureService
    private let breakdownViewFactory: BreakdownViewFactory

    private let source: PayWithWiseFlow.PaymentInitializationSource

    private weak var flowNavigationDelegate: PayWithWiseFlowNavigationDelegate?

    init(
        source: PayWithWiseFlow.PaymentInitializationSource,
        breakdownViewFactory: BreakdownViewFactory,
        balanceFormatter: BalanceFormatter,
        profileSwitcherFlowFactory: ProfileSwitcherFlowFactory,
        appReviewNudgePresenter: AppReviewNudgePresenter,
        topUpBalanceFlowFactory: TopUpBalanceFlowFactory,
        contactsDiscoverabilitySettingsViewControllerFactory: ContactsDiscoverabilitySettingsViewControllerFactoryProtocol,
        webViewControllerFactory: WebViewControllerFactory.Type,
        featureService: FeatureService = GOS[FeatureServiceKey.self]
    ) {
        self.source = source
        self.breakdownViewFactory = breakdownViewFactory
        self.balanceFormatter = balanceFormatter
        self.profileSwitcherFlowFactory = profileSwitcherFlowFactory
        self.appReviewNudgePresenter = appReviewNudgePresenter
        self.topUpBalanceFlowFactory = topUpBalanceFlowFactory
        self.contactsDiscoverabilitySettingsViewControllerFactory = contactsDiscoverabilitySettingsViewControllerFactory
        self.webViewControllerFactory = webViewControllerFactory
        self.featureService = featureService
    }

    func setFlowNavigationDelegate(_ delegate: PayWithWiseFlowNavigationDelegate) {
        flowNavigationDelegate = delegate
    }
}

extension PayWithWiseViewControllerFactoryImpl: PayWithWiseViewControllerFactory {
    func makeViewController(
        profile: Profile,
        host: UINavigationController
    ) -> UIViewController {
        let payWithWiseUseCase = PayWithWiseUseCaseFactory.make()
        let balancesUseCase = BalancesUseCaseFactory.make()
        let owedPaymentRequestUseCase = OwedPaymentRequestUseCaseFactory.make()
        let attachmentFileService = AttachmentFileServiceFactory.make()
        let interactor = PayWithWiseInteractorImpl(
            source: source,
            payWithWiseUseCase: payWithWiseUseCase,
            balancesUseCase: balancesUseCase,
            owedPaymentRequestUseCase: owedPaymentRequestUseCase,
            attachmentFileService: attachmentFileService
        )

        let quickpayUseCase = QuickpayUseCaseFactory.make()

        let router = PayWithWiseRouterImpl(
            flowNavigationDelegate: flowNavigationDelegate,
            host: host,
            profileSwitcherFlowFactory: profileSwitcherFlowFactory,
            appReviewNudgePresenter: appReviewNudgePresenter,
            topUpBalanceFlowFactory: topUpBalanceFlowFactory,
            contactsDiscoverabilitySettingsViewControllerFactory: contactsDiscoverabilitySettingsViewControllerFactory,
            webViewControllerFactory: webViewControllerFactory
        )

        let viewModelFactory = PayWithWiseViewModelFactoryImpl(
            balanceFormatter: balanceFormatter
        )

        switch source {
        case .paymentKey,
             .paymentRequestId:
            let presenter = PayWithWisePresenterImpl(
                source: source,
                profile: profile,
                interactor: interactor,
                router: router,
                flowNavigationDelegate: flowNavigationDelegate,
                viewModelFactory: viewModelFactory
            )

            return PayWithWiseViewController(
                presenter: presenter,
                breakdownViewFactory: breakdownViewFactory
            )
        case let .quickpay(payerData, businessInfo):

            let prismTracker = MixpanelPrismTracker()
            let quickpayTracker = QuickpayTrackingFactory().make(
                onTrack: prismTracker.trackEvent(name:properties:)
            )

            let presenter = PayWithWiseQuickpayPresenterImpl(
                profile: profile,
                payerData: payerData,
                businessInfo: businessInfo,
                interactor: interactor,
                quickpayUseCase: quickpayUseCase,
                router: router,
                analyticsTracker: quickpayTracker,
                flowNavigationDelegate: flowNavigationDelegate,
                viewModelFactory: viewModelFactory
            )

            return PayWithWiseViewController(
                presenter: presenter,
                breakdownViewFactory: breakdownViewFactory
            )
        }
    }
}
