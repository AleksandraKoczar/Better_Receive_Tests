import LoggingKit
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol PaymentDetailsRefundFlowDelegate: AnyObject {
    func didRefundFlowCompleted()
    func goBackToAllPayments()
}

// sourcery: AutoMockable
protocol PaymentDetailsRouter: AnyObject {
    func showRefundFlow(paymentId: String, profileId: ProfileId)
    func showRefundDisabledBottomSheet(
        title: String,
        illustrationUrn: String?,
        message: String
    )
}

final class PaymentDetailsRouterImpl {
    private weak var navigationController: UINavigationController?
    private weak var refundDisabledBottomSheet: UIViewController?
    private weak var paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate?
    private let paymentRequestId: PaymentRequestId
    private let webViewControllerFactory: WebViewControllerFactory.Type
    private let refundFlowFactory: PaymentRequestRefundFlowFactory
    private let userProvider: UserProvider
    private let featureService: FeatureService
    private let flowPresenter: FlowPresenter

    private var refundFlow: (any Flow<Void>)?

    init(
        paymentRequestId: PaymentRequestId,
        navigationController: UINavigationController,
        paymentDetailsRefundFlowDelegate: PaymentDetailsRefundFlowDelegate,
        webViewControllerFactory: WebViewControllerFactory.Type,
        refundFlowFactory: PaymentRequestRefundFlowFactory = PaymentRequestRefundFlowFactoryImpl(),
        userProvider: UserProvider = GOS[UserProviderKey.self],
        featureService: FeatureService = GOS[FeatureServiceKey.self],
        flowPresenter: FlowPresenter = .current
    ) {
        self.paymentRequestId = paymentRequestId
        self.navigationController = navigationController
        self.paymentDetailsRefundFlowDelegate = paymentDetailsRefundFlowDelegate
        self.webViewControllerFactory = webViewControllerFactory
        self.refundFlowFactory = refundFlowFactory
        self.userProvider = userProvider
        self.featureService = featureService
        self.flowPresenter = flowPresenter
    }

    // MARK: - Helpers

    private func makeRefundFlowUrl(paymentId: String) -> URL {
        let refundFlowUrl = Branding.current.url.appendingPathComponent(
            Constants.refundFlowPath(paymentId: paymentId)
        )
        var components = URLComponents(url: refundFlowUrl, resolvingAgainstBaseURL: false)
        // These query items will allow web to redirect users back to payment links
        components?.queryItems = [
            Constants.nextQueryItem,
            Constants.requestIdQueryItem(paymentRequestId: paymentRequestId),
        ]
        guard let url = components?.url else {
            return refundFlowUrl
        }
        return url
    }

    private func showWebRefundFlow(paymentId: String, profileId: ProfileId) {
        let refundFlowUrl = makeRefundFlowUrl(paymentId: paymentId)
        let webViewController = webViewControllerFactory.make(
            with: refundFlowUrl,
            userInfoForAuthentication: (
                userId: userProvider.user.userId,
                profileId: profileId
            )
        )
        webViewController.navigationDelegate = self
        webViewController.modalPresentationStyle = .fullScreen
        navigationController?.present(
            webViewController.navigationWrapped(),
            animated: UIView.shouldAnimate
        )
    }
}

extension PaymentDetailsRouterImpl: PaymentDetailsRouter {
    private enum Constants {
        static let accountPaymentLinksPath = "/account/payment-links"
        static let nextQueryItem = URLQueryItem(name: "next", value: "PAYMENT_LINKS")

        static func refundFlowPath(paymentId: String) -> String {
            "/flows/request-refund/\(paymentId)"
        }

        static func requestIdQueryItem(paymentRequestId: PaymentRequestId) -> URLQueryItem {
            URLQueryItem(name: "requestId", value: paymentRequestId.value)
        }
    }

    @MainActor
    func showRefundFlow(paymentId: String, profileId: ProfileId) {
        guard featureService.isOn(ReceiveKitFeatures.nativeRefundPaymentRequestEnabled) else {
            showWebRefundFlow(paymentId: paymentId, profileId: profileId)
            return
        }

        guard let navigationController else {
            softFailure("[REC] Attemp to open refund flow without a navigation controller.")
            return
        }

        let flow = refundFlowFactory.make(paymentId: paymentId, profileId: profileId, navigationController: navigationController)
        flow.onFinish { [weak self] _, dismisser in
            guard let self else { return }
            dismisser.dismiss {
                self.refundFlow = nil
                self.paymentDetailsRefundFlowDelegate?.goBackToAllPayments()
            }
        }

        refundFlow = flow

        flowPresenter.start(flow: flow)
    }

    func showRefundDisabledBottomSheet(
        title: String,
        illustrationUrn: String?,
        message: String
    ) {
        let illustrationConfiguration = illustrationUrn
            .flatMap { try? URN($0) }
            .flatMap(IllustrationFactory.illustrationAsset(urn:))
            .flatMap { $0?.image }
            .map(IllustrationView.Asset.image)
            .map(IllustrationViewConfiguration.init(asset:))
        let viewController = BottomSheetViewController.makeErrorSheet(
            viewModel: ErrorViewModel(
                illustrationConfiguration: illustrationConfiguration ?? .warning,
                title: title,
                message: .text(message),
                primaryViewModel: .init(
                    title: L10n.PaymentRequest.PaymentDetail.Action.Title.refundDisabled,
                    handler: { [weak self] in
                        self?.refundDisabledBottomSheet?.dismiss(animated: UIView.shouldAnimate)
                    }
                )
            )
        )
        navigationController?.presentBottomSheet(viewController)
        refundDisabledBottomSheet = viewController
    }
}

// MARK: - WebContentViewControllerNavigationDelegate

extension PaymentDetailsRouterImpl: WebContentViewControllerNavigationDelegate {
    func navigateToURL(
        viewController: WebContentViewController,
        url: URL?
    ) {
        // Dismiss the web refund flow when it tries to re-direct users to payment links on web
        // Instead, show the native payment request details screen and reload data
        let paymentLinksPath = Constants.accountPaymentLinksPath.appending("/\(paymentRequestId.value)")
        guard let path = url?.path,
              path.contains(paymentLinksPath) else {
            return
        }
        viewController.dismiss(animated: UIView.shouldAnimate) { [weak delegate = paymentDetailsRefundFlowDelegate] in
            delegate?.didRefundFlowCompleted()
        }
    }
}
