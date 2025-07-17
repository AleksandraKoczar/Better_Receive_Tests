import ReceiveKit
import TWFoundation
import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
protocol CreatePaymentRequestConfirmationRouter: AnyObject {
    func showPrivacyPolicy()
    func showQRCode()
    func showFeedback(model: FeedbackViewModel, context: FeedbackContext, onSuccess: @escaping (() -> Void))
}

final class CreatePaymentRequestConfirmationRouterImpl {
    private let profile: Profile
    private let paymentRequest: PaymentRequestV2
    private let feedbackFlowFactory: AutoSubmittingFeedbackFlowFactory
    private let feedbackService: FeedbackService
    private let urlOpener: UrlOpener

    weak var viewController: UIViewController?
    private var activeFeedbackFlow: (any Flow<AutoSubmittingFeedbackFlowResult>)?

    init(
        profile: Profile,
        paymentRequest: PaymentRequestV2,
        feedbackFlowFactory: AutoSubmittingFeedbackFlowFactory = AutoSubmittingFeedbackFlowFactoryImpl(),
        feedbackService: FeedbackService,
        urlOpener: UrlOpener = UIApplication.shared
    ) {
        self.profile = profile
        self.paymentRequest = paymentRequest
        self.feedbackFlowFactory = feedbackFlowFactory
        self.feedbackService = feedbackService
        self.urlOpener = urlOpener
    }
}

extension CreatePaymentRequestConfirmationRouterImpl: CreatePaymentRequestConfirmationRouter {
    func showPrivacyPolicy() {
        let url = Branding.current.url.appendingPathComponent("terms-and-conditions")
        urlOpener.open(url)
    }

    func showQRCode() {
        let qrCodeViewController = PaymentRequestQRSharingViewControllerFactory.make(
            profile: profile,
            paymentRequest: paymentRequest
        )
        viewController?.presentBottomSheet(qrCodeViewController)
    }

    func showFeedback(model: FeedbackViewModel, context: FeedbackContext, onSuccess: @escaping (() -> Void)) {
        guard let viewControlller = viewController else { return }
        let flow = feedbackFlowFactory.make(
            viewModel: model,
            context: context,
            service: feedbackService,
            hostController: viewControlller,
            additionalProperties: nil
        )
        flow.onFinish { [weak self] result, dismisser in
            dismisser?.dismiss()
            if result == .success {
                onSuccess()
            }
            self?.activeFeedbackFlow = nil
        }
        activeFeedbackFlow = flow
        flow.start()
    }
}
