import BalanceKit
import ContactsKit
import DeepLinkKit
import Neptune
import ReceiveKit
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
public protocol PayWithWiseFlowFactory {
    // sourcery: mockName = "makeModalFlowWithPaymentKey"
    func makeModalFlow(
        paymentKeySource: DeepLinkPayWithWiseSource,
        profile: Profile,
        host: UIViewController
    ) -> any Flow<Void>

    // sourcery: mockName = "makeModalFlowWithPaymentRequestId"
    func makeModalFlow(
        paymentRequestId: PaymentRequestId,
        profile: Profile,
        host: UIViewController
    ) -> any Flow<Void>

    // sourcery: mockName = "makeModalFlowWithAcquiringPaymentKey"
    func makeModalFlow(
        payerData: QuickpayPayerData,
        businessInfo: ContactSearch,
        profile: Profile,
        host: UIViewController
    ) -> any Flow<Void>
}

public struct PayWithWiseFlowFactoryImpl: PayWithWiseFlowFactory {
    private let breakdownViewFactory: BreakdownViewFactory
    private let balanceFormatter: BalanceFormatter
    private let profileSwitcherFlowFactory: ProfileSwitcherFlowFactory
    private let requestMoneyFlowFactory: RequestMoneyFlowFactory
    private let appReviewNudgePresenter: AppReviewNudgePresenter
    private let topUpBalanceFlowFactory: TopUpBalanceFlowFactory
    private let contactsDiscoverabilitySettingsViewControllerFactory: ContactsDiscoverabilitySettingsViewControllerFactoryProtocol
    private let webViewControllerFactory: WebViewControllerFactory.Type

    public init(
        breakdownViewFactory: BreakdownViewFactory,
        balanceFormatter: BalanceFormatter,
        profileSwitcherFlowFactory: ProfileSwitcherFlowFactory,
        appReviewNudgePresenter: AppReviewNudgePresenter,
        requestMoneyFlowFactory: RequestMoneyFlowFactory,
        topUpBalanceFlowFactory: TopUpBalanceFlowFactory,
        contactsDiscoverabilitySettingsViewControllerFactory: ContactsDiscoverabilitySettingsViewControllerFactoryProtocol,
        webViewControllerFactory: WebViewControllerFactory.Type
    ) {
        self.breakdownViewFactory = breakdownViewFactory
        self.balanceFormatter = balanceFormatter
        self.profileSwitcherFlowFactory = profileSwitcherFlowFactory
        self.requestMoneyFlowFactory = requestMoneyFlowFactory
        self.appReviewNudgePresenter = appReviewNudgePresenter
        self.topUpBalanceFlowFactory = topUpBalanceFlowFactory
        self.contactsDiscoverabilitySettingsViewControllerFactory = contactsDiscoverabilitySettingsViewControllerFactory
        self.webViewControllerFactory = webViewControllerFactory
    }

    public func makeModalFlow(
        paymentKeySource: DeepLinkPayWithWiseSource,
        profile: Profile,
        host: UIViewController
    ) -> any Flow<Void> {
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen

        let flow = PayWithWiseFlow(
            profile: profile,
            host: navigationController,
            presenterFactory: ViewControllerPresenterFactoryImpl(),
            viewControllerFactory: PayWithWiseViewControllerFactoryImpl(
                source: .paymentKey(paymentKeySource),
                breakdownViewFactory: breakdownViewFactory,
                balanceFormatter: balanceFormatter,
                profileSwitcherFlowFactory: profileSwitcherFlowFactory,
                appReviewNudgePresenter: appReviewNudgePresenter,
                topUpBalanceFlowFactory: topUpBalanceFlowFactory,
                contactsDiscoverabilitySettingsViewControllerFactory: contactsDiscoverabilitySettingsViewControllerFactory,
                webViewControllerFactory: webViewControllerFactory
            ),
            requestMoneyFlowFactory: requestMoneyFlowFactory
        )

        return ModalPresentationFlow(
            flow: flow,
            rootViewController: host,
            flowController: navigationController
        )
    }

    public func makeModalFlow(
        paymentRequestId: PaymentRequestId,
        profile: Profile,
        host: UIViewController
    ) -> any Flow<Void> {
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        let flow = PayWithWiseFlow(
            profile: profile,
            host: navigationController,
            presenterFactory: ViewControllerPresenterFactoryImpl(),
            viewControllerFactory: PayWithWiseViewControllerFactoryImpl(
                source: .paymentRequestId(paymentRequestId),
                breakdownViewFactory: breakdownViewFactory,
                balanceFormatter: balanceFormatter,
                profileSwitcherFlowFactory: profileSwitcherFlowFactory,
                appReviewNudgePresenter: appReviewNudgePresenter,
                topUpBalanceFlowFactory: topUpBalanceFlowFactory,
                contactsDiscoverabilitySettingsViewControllerFactory: contactsDiscoverabilitySettingsViewControllerFactory,
                webViewControllerFactory: webViewControllerFactory
            ),
            requestMoneyFlowFactory: requestMoneyFlowFactory
        )

        return ModalPresentationFlow(
            flow: flow,
            rootViewController: host,
            flowController: navigationController
        )
    }

    public func makeModalFlow(
        payerData: QuickpayPayerData,
        businessInfo: ContactSearch,
        profile: Profile,
        host: UIViewController
    ) -> any Flow<Void> {
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        let flow = PayWithWiseFlow(
            profile: profile,
            host: navigationController,
            presenterFactory: ViewControllerPresenterFactoryImpl(),
            viewControllerFactory: PayWithWiseViewControllerFactoryImpl(
                source: .quickpay(payerData, businessInfo),
                breakdownViewFactory: breakdownViewFactory,
                balanceFormatter: balanceFormatter,
                profileSwitcherFlowFactory: profileSwitcherFlowFactory,
                appReviewNudgePresenter: appReviewNudgePresenter,
                topUpBalanceFlowFactory: topUpBalanceFlowFactory,
                contactsDiscoverabilitySettingsViewControllerFactory: contactsDiscoverabilitySettingsViewControllerFactory,
                webViewControllerFactory: webViewControllerFactory
            ),
            requestMoneyFlowFactory: requestMoneyFlowFactory
        )

        return ModalPresentationFlow(
            flow: flow,
            rootViewController: host,
            flowController: navigationController
        )
    }
}
