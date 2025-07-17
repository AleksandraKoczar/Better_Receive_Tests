import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PayWithWiseRouter: AnyObject {
    func showSuccess(
        viewModel: PayWithWiseSuccessPromptViewModel
    )
    func showRejectConfirmation(viewModel: InfoSheetViewModel)
    func showRejectSuccess(profileId: ProfileId)
    func showPaymentMethodsBottomSheet(
        paymentMethods: [PayerAcquiringPaymentMethod],
        requesterName: String,
        completion: @escaping (PayerAcquiringPaymentMethod) -> Void
    )
    func showPaymentMethodsBottomSheetQuickpay(
        paymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        businessName: String,
        completion: @escaping (QuickpayAcquiringPayment.PaymentMethodAvailability) -> Void
    )
    func showPaymentMethod(
        profileId: ProfileId,
        paymentMethod: PayerAcquiringPaymentMethod,
        paymentKey: String
    )
    func showPaymentMethodQuickpay(
        profileId: ProfileId,
        paymentMethod: QuickpayAcquiringPayment.PaymentMethodAvailability,
        quickpayLookup: QuickpayAcquiringPayment,
        quickpay: String
    )
    func showProfileSwitcher(completion: @escaping () -> Void)
    func showBalanceSelector(
        viewModel: PayWithWiseBalanceSelectorViewModel
    )
    func showTopUpFlow(
        profile: Profile,
        targetAmount: Money?,
        rootViewController: UIViewController,
        completion: @escaping (TopUpBalanceFlowResult) -> Void
    )
    func showDetails(viewModel: PayWithWiseRequestDetailsView.ViewModel)
    func showAttachment(
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate
    )
    func showRequestMoney(profile: Profile)
    func dismissBalanceSelector()
    func dismiss()
}

final class PayWithWiseRouterImpl {
    private enum Constants {
        static let payWithWisePath = "/pay/r"
        static let paymentMethodQueryParam = "payerMode"
        static let payWithWiseQuickpayPath = "/pay/business"
        static let payWithWiseQuickpayAmount = "amount"
        static let payWithWiseQuickpayCurrency = "currency"
    }

    private let host: UINavigationController
    private let profileSwitcherFlowFactory: ProfileSwitcherFlowFactory
    private let appReviewNudgePresenter: AppReviewNudgePresenter
    private let topUpBalanceFlowFactory: TopUpBalanceFlowFactory
    private let contactsDiscoverabilitySettingsViewControllerFactory: ContactsDiscoverabilitySettingsViewControllerFactoryProtocol
    private let viewControllerPresenterFactory: ViewControllerPresenterFactory
    private let urlOpener: UrlOpener
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let userProvider: UserProvider

    private weak var flowNavigationDelegate: PayWithWiseFlowNavigationDelegate?

    private var profileSwitcherFlow: (any Flow<ProfileSwitcherFlowResult>)?
    private var topUpBalanceFlow: (any Flow<TopUpBalanceFlowResult>)?
    private var balanceSelectorBottomSheet: UIViewController?

    init(
        flowNavigationDelegate: PayWithWiseFlowNavigationDelegate?,
        host: UINavigationController,
        profileSwitcherFlowFactory: ProfileSwitcherFlowFactory,
        appReviewNudgePresenter: AppReviewNudgePresenter,
        topUpBalanceFlowFactory: TopUpBalanceFlowFactory,
        contactsDiscoverabilitySettingsViewControllerFactory: ContactsDiscoverabilitySettingsViewControllerFactoryProtocol,
        viewControllerPresenterFactory: ViewControllerPresenterFactory = ViewControllerPresenterFactoryImpl(),
        urlOpener: UrlOpener = UIApplication.shared,
        webViewControllerFactory: WebViewControllerFactory.Type,
        userProvider: UserProvider = GOS[UserProviderKey.self]
    ) {
        self.flowNavigationDelegate = flowNavigationDelegate
        self.host = host
        self.profileSwitcherFlowFactory = profileSwitcherFlowFactory
        self.appReviewNudgePresenter = appReviewNudgePresenter
        self.topUpBalanceFlowFactory = topUpBalanceFlowFactory
        self.contactsDiscoverabilitySettingsViewControllerFactory = contactsDiscoverabilitySettingsViewControllerFactory
        self.viewControllerPresenterFactory = viewControllerPresenterFactory
        self.userProvider = userProvider
        self.urlOpener = urlOpener
        self.webViewControllerFactory = webViewControllerFactory
    }
}

// MARK: - PayWithWiseRouter

extension PayWithWiseRouterImpl: PayWithWiseRouter {
    func showSuccess(
        viewModel: PayWithWiseSuccessPromptViewModel
    ) {
        let windowScene = host.view.window?.windowScene
        let successViewController = PromptViewControllerFactory.make(
            from: PromptConfiguration.make(
                asset: viewModel.asset,
                title: viewModel.title,
                message: viewModel.message,
                primaryButton: PromptConfiguration.PrimaryButtonConfiguration(
                    title: viewModel.primaryButtonTitle,
                    actionHandler: { [weak self] _ in
                        guard let self else { return }
                        host.presentingViewController?.dismiss(animated: UIView.shouldAnimate)
                        flowNavigationDelegate?.dismissed(at: .success)
                        viewModel.completion()
                        appReviewNudgePresenter.nudgeIfNeeded(
                            PayWithWiseAppReviewNudge(),
                            in: windowScene
                        )
                    }
                ), appearHaptics: .success
            )
        )
        successViewController.modalPresentationStyle = .fullScreen
        host.present(successViewController, animated: UIView.shouldAnimate)
    }

    func showRejectConfirmation(viewModel: InfoSheetViewModel) {
        host.presentInfoSheet(viewModel: viewModel)
    }

    func showRejectSuccess(profileId: ProfileId) {
        let navigationController = TWNavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        let successViewController = PromptViewControllerFactory.make(
            from: PromptConfiguration.make(
                asset: .image(Illustrations.flag.image),
                title: L10n.PayWithWise.Payment.RequestRejected.Success.title,
                message: PromptConfiguration.MessageConfiguration.text(
                    L10n.PayWithWise.Payment.RequestRejected.Success.description
                ),
                primaryButton: PromptConfiguration.PrimaryButtonConfiguration(
                    title: L10n.PayWithWise.Payment.RequestRejected.Success.Button.title,
                    actionHandler: { [weak self] _ in
                        guard let self else { return }
                        host.presentingViewController?.dismiss(animated: UIView.shouldAnimate)
                        flowNavigationDelegate?.dismissed(at: .rejected)
                    }
                ),
                secondaryButton: PromptConfiguration.SecondaryButtonConfiguration(
                    title: L10n.PayWithWise.Payment.RequestRejected.Success.ChangeSettingButton.title,
                    actionHandler: { [weak self] _ in
                        guard let self else { return }
                        let vc = contactsDiscoverabilitySettingsViewControllerFactory.make(
                            navigationController: navigationController,
                            profileId: profileId
                        )
                        navigationController.pushViewController(vc, animated: UIView.shouldAnimate)
                    }
                ),
                theme: \.primary,
                appearHaptics: .success
            )
        )
        navigationController.viewControllers = [successViewController]
        host.present(navigationController, animated: UIView.shouldAnimate)
    }

    func showPaymentMethodsBottomSheet(
        paymentMethods: [PayerAcquiringPaymentMethod],
        requesterName: String,
        completion: @escaping (PayerAcquiringPaymentMethod) -> Void
    ) {
        let options: [PayWithWisePaymentOption] = paymentMethods
            .compactMap {
                guard let option = makePaymentOptions(
                    requesterName: requesterName,
                    paymentMethod: $0
                ) else {
                    return nil
                }
                return option
            }

        let bottomSheet = BottomSheetViewController.makeNavigationOptionSheet(
            title: L10n.PayWithWise.PaymentOptions.Screen.title,
            items: options.map { $0.viewModel },
            handler: { index, _ in
                guard let paymentMethod = paymentMethods.first(where: {
                    $0.type == options[index].type
                }) else {
                    return
                }
                completion(paymentMethod)
            }
        )
        host.presentBottomSheet(bottomSheet)
    }

    func showPaymentMethodsBottomSheetQuickpay(
        paymentMethods: [QuickpayAcquiringPayment.PaymentMethodAvailability],
        businessName: String,
        completion: @escaping (QuickpayAcquiringPayment.PaymentMethodAvailability) -> Void
    ) {
        let options: [PayWithWisePaymentOptionQuickpay] = paymentMethods
            .compactMap {
                guard let option = makeQuickpayPaymentOptions(
                    paymentMethod: $0
                ) else {
                    return nil
                }
                return option
            }

        let bottomSheet = BottomSheetViewController.makeNavigationOptionSheet(
            items: options.map { $0.viewModel },
            handler: { index, _ in
                guard let paymentMethod = paymentMethods.first(where: {
                    $0.type == options[index].type
                }) else {
                    return
                }
                completion(paymentMethod)
            }
        )
        host.presentBottomSheet(bottomSheet)
    }

    func showPaymentMethodQuickpay(
        profileId: ProfileId,
        paymentMethod: QuickpayAcquiringPayment.PaymentMethodAvailability,
        quickpayLookup: QuickpayAcquiringPayment,
        quickpay: String
    ) {
        guard let url = makePaymentOptionURLForQuickpay(
            quickpayLookup: quickpayLookup,
            quickpay: quickpay,
            paymentMethod: paymentMethod
        ) else {
            return
        }

        // open external browser due to bug
        if paymentMethod.type == .pisp {
            urlOpener.open(url)
            dismiss() // Dismiss the flow to avoid making payments again.
            return
        }

        let webViewController = webViewControllerFactory.make(
            with: url,
            userInfoForAuthentication: (
                userId: userProvider.user.userId,
                profileId: profileId
            )
        )
        webViewController.isDownloadSupported = true
        webViewController.modalPresentationStyle = .fullScreen
        host.present(
            webViewController.navigationWrapped(),
            animated: UIView.shouldAnimate
        )
    }

    func showPaymentMethod(
        profileId: ProfileId,
        paymentMethod: PayerAcquiringPaymentMethod,
        paymentKey: String
    ) {
        guard let url = makePaymentOptionURL(
            paymentKey: paymentKey,
            paymentMethod: paymentMethod
        ) else {
            return
        }

        if shouldOpenExternalBrowser(for: paymentMethod) {
            urlOpener.open(url)
            dismiss() // Dismiss the flow to avoid making payments again.
            return
        }

        let webViewController = webViewControllerFactory.make(
            with: url,
            userInfoForAuthentication: (
                userId: userProvider.user.userId,
                profileId: profileId
            )
        )
        webViewController.isDownloadSupported = true
        webViewController.modalPresentationStyle = .fullScreen
        host.present(
            webViewController.navigationWrapped(),
            animated: UIView.shouldAnimate
        )
    }

    func showProfileSwitcher(completion: @escaping () -> Void) {
        profileSwitcherFlow = profileSwitcherFlowFactory.makeFlow(rootViewController: host)

        profileSwitcherFlow?.onFinish { [weak self] result, dismisser in
            guard let self else { return }
            switch result {
            case .completed:
                completion()
            }
            dismisser?.dismiss()
            profileSwitcherFlow = nil
        }

        profileSwitcherFlow?.start()
    }

    func showBalanceSelector(
        viewModel: PayWithWiseBalanceSelectorViewModel
    ) {
        let vc = PayWithWiseBalanceSelectorViewController(viewModel: viewModel)
        balanceSelectorBottomSheet = host.presentBottomSheet(
            vc,
            source: nil,
            completion: nil
        )
    }

    func showTopUpFlow(
        profile: Profile,
        targetAmount: Money?,
        rootViewController: UIViewController,
        completion: @escaping (TopUpBalanceFlowResult) -> Void
    ) {
        let targetCurrencies: [CurrencyCode] = {
            guard let targetAmount else { return [] }
            return [targetAmount.currency]
        }()
        let flow = topUpBalanceFlowFactory.makeModalFlow(
            profile: profile,
            targetCurrencies: targetCurrencies,
            targetAmount: targetAmount?.value,
            minimumAmounts: [],
            rootViewController: rootViewController
        )
        flow.onFinish { [weak self] result, dismisser in
            dismisser?.dismiss()
            completion(result)
            self?.topUpBalanceFlow = nil
        }

        topUpBalanceFlow = flow
        flow.start()
    }

    func showDetails(viewModel: PayWithWiseRequestDetailsView.ViewModel) {
        let vc = BottomSheetViewController.makeWithSwiftUIContent(
            title: viewModel.title,
            content: {
                PayWithWiseRequestDetailsView(viewModel: viewModel)
            }
        )

        let bottomSheetPresenter = viewControllerPresenterFactory.makeBottomSheetPresenter(
            parent: host
        )
        bottomSheetPresenter.present(viewController: vc)
    }

    func showAttachment(
        url: URL,
        delegate: UIDocumentInteractionControllerDelegate
    ) {
        let documentPreviewer = UIDocumentInteractionController(url: url)
        documentPreviewer.name = ""
        documentPreviewer.delegate = delegate
        documentPreviewer.presentPreview(animated: UIView.shouldAnimate)
    }

    func showRequestMoney(profile: Profile) {
        host.dismiss(
            animated: UIView.shouldAnimate,
            completion: { [weak self] in
                self?.flowNavigationDelegate?.startRequestMoneyFlow(profile: profile)
            }
        )
    }

    func dismissBalanceSelector() {
        balanceSelectorBottomSheet?.dismiss(animated: UIView.shouldAnimate)
    }

    func dismiss() {
        host.dismiss(
            animated: UIView.shouldAnimate,
            completion: { [weak self] in
                self?.flowNavigationDelegate?.dismissed(
                    at: .singlePagePayer
                )
            }
        )
    }
}

// MARK: - Helpers

private extension PayWithWiseRouterImpl {
    func makePaymentOptionURL(
        paymentKey: String,
        paymentMethod: PayerAcquiringPaymentMethod
    ) -> URL? {
        guard var components = URLComponents(
            url: Branding.current.url
                .appendingPathComponent(Constants.payWithWisePath)
                .appendingPathComponent(paymentKey),
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }

        // TODO: remove next week when web makes the change
        var value = ""
        switch paymentMethod.type {
        case .applePay:
            value = "WEB_VIEW_APPLE_PAY"
        case .bankTransfer:
            value = "ACCOUNT_DETAILS"
        case .card:
            value = "CARD"
        case .payWithWise:
            break
        case .payNow:
            value = "SG_PAYNOW"
        case .pisp:
            value = "PISP"
        }

        components.queryItems = [
            URLQueryItem(
                name: Constants.paymentMethodQueryParam,
                value: value
            ),
        ]

        return components.url
    }

    func makePaymentOptionURLForQuickpay(
        quickpayLookup: QuickpayAcquiringPayment,
        quickpay: String,
        paymentMethod: QuickpayAcquiringPayment.PaymentMethodAvailability
    ) -> URL? {
        guard var components = URLComponents(
            url: Branding.current.url
                .appendingPathComponent(Constants.payWithWiseQuickpayPath)
                .appendingPathComponent(quickpay),
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(
                name: Constants.paymentMethodQueryParam,
                value: paymentMethod.name
            ),
            URLQueryItem(
                name: Constants.payWithWiseQuickpayAmount,
                value: quickpayLookup.amount.value.description
            ),
            URLQueryItem(
                name: Constants.payWithWiseQuickpayCurrency,
                value: quickpayLookup.amount.currency.value
            ),
        ]

        return components.url
    }

    func makeQuickpayPaymentOptions(
        paymentMethod: QuickpayAcquiringPayment.PaymentMethodAvailability
    ) -> PayWithWisePaymentOptionQuickpay? {
        switch paymentMethod.type {
        case .card:
            PayWithWisePaymentOptionQuickpay(
                type: .card,
                viewModel: OptionViewModel(
                    title: paymentMethod.name,
                    subtitle: L10n.PayWithWise.PaymentOptions.Screen.Option.Cards.description,
                    avatar: AvatarViewModel.icon(Icons.card.image)
                )
            )
        case .pisp:
            PayWithWisePaymentOptionQuickpay(
                type: .pisp,
                viewModel: OptionViewModel(
                    title: paymentMethod.name,
                    avatar: AvatarViewModel.icon(Icons.bank.image)
                )
            )
        case .payWithWise:
            nil
        }
    }

    func makePaymentOptions(
        requesterName: String,
        paymentMethod: PayerAcquiringPaymentMethod
    ) -> PayWithWisePaymentOption? {
        switch paymentMethod.type {
        case .applePay:
            PayWithWisePaymentOption(
                type: .applePay,
                viewModel: OptionViewModel(
                    title: paymentMethod.name,
                    leadingView: LeadingViewModel.icon(
                        WiseAtomsAssets.Assets.applePay.image
                    )
                )
            )
        case .bankTransfer:
            PayWithWisePaymentOption(
                type: .bankTransfer,
                viewModel: OptionViewModel(
                    title: paymentMethod.name,
                    subtitle: L10n.PayWithWise.PaymentOptions.Screen.Option.BankTransfer.description(
                        requesterName
                    ),
                    avatar: AvatarViewModel.icon(Icons.bank.image)
                )
            )
        case .card:
            PayWithWisePaymentOption(
                type: .card,
                viewModel: OptionViewModel(
                    title: paymentMethod.name,
                    subtitle: L10n.PayWithWise.PaymentOptions.Screen.Option.Cards.description,
                    avatar: AvatarViewModel.icon(Icons.card.image)
                )
            )
        case .payNow:
            PayWithWisePaymentOption(
                type: .payNow,
                viewModel: OptionViewModel(
                    title: L10n.PayWithWise.PaymentOptions.Screen.Option.PayNow.title,
                    avatar: AvatarViewModel.icon(Icons.qrCode.image)
                )
            )
        case .pisp:
            PayWithWisePaymentOption(
                type: .pisp,
                viewModel: OptionViewModel(
                    title: paymentMethod.name,
                    avatar: AvatarViewModel.icon(Icons.bank.image)
                )
            )
        case .payWithWise:
            nil
        }
    }

    func shouldOpenExternalBrowser(for paymentMethod: PayerAcquiringPaymentMethod) -> Bool {
        // We should open the external browser because of conflict error for Open Banking
        // (https://transferwise.atlassian.net/browse/GPAID-3751)
        paymentMethod.type == .pisp
    }
}

private struct PayWithWiseAppReviewNudge: AppReviewNudge {
    var rule: Bool { true }
}
