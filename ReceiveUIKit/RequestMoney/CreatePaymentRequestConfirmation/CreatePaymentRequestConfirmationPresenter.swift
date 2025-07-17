import AnalyticsKit
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UserKit

// sourcery: AutoMockable
protocol CreatePaymentRequestConfirmationPresenter: AnyObject {
    func start(with view: CreatePaymentRequestConfirmationView)
    func privacyPolicyTapped()
    func giveFeedbackTapped()
    func dismiss()
    func doneTapped()
}

final class CreatePaymentRequestConfirmationPresenterImpl: NSObject {
    private weak var view: CreatePaymentRequestConfirmationView?
    private let pasteboard: Pasteboard
    private let dateFormatter: WiseDateFormatterProtocol
    private let profile: Profile
    private let router: CreatePaymentRequestConfirmationRouter
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<CreatePaymentRequestConfirmationAnalyticsView>
    private let onSuccess: (CreatePaymentRequestFlowResult) -> Void

    private var paymentRequest: PaymentRequestV2

    init(
        profile: Profile,
        paymentRequest: PaymentRequestV2,
        router: CreatePaymentRequestConfirmationRouter,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        pasteboard: Pasteboard = UIPasteboard.general,
        dateFormatter: WiseDateFormatterProtocol = WiseDateFormatter.shared,
        onSuccess: @escaping (CreatePaymentRequestFlowResult) -> Void
    ) {
        self.paymentRequest = paymentRequest
        self.pasteboard = pasteboard
        self.dateFormatter = dateFormatter
        self.profile = profile
        self.router = router
        self.onSuccess = onSuccess
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: CreatePaymentRequestConfirmationAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }

    // MARK: - Helpers

    private func copyTapped() {
        let action = CreatePaymentRequestConfirmationAnalyticsView.ShareOptionSelected(vendor: "copied")
        analyticsViewTracker.track(action)
        pasteboard.addToClipboard(paymentRequest.link)
        view?.generateHapticFeedback()
        view?.showSnackbar(message: L10n.PaymentRequest.Create.Confirm.Share.Copy.confirmed)
    }

    private func shareTapped() {
        let action = CreatePaymentRequestConfirmationAnalyticsView.ShareOptionSelected(vendor: "share-sheet")
        analyticsViewTracker.track(action)
        view?.generateHapticFeedback()
        view?.showShareSheet(with: shareMessage)
    }

    private func qrCodeTapped() {
        let action = CreatePaymentRequestConfirmationAnalyticsView.ShareOptionSelected(vendor: "qr-code")
        analyticsViewTracker.track(action)
        router.showQRCode()
    }

    private var shareMessage: String {
        ShareMessageFactoryImpl().make(
            profile: profile,
            paymentRequest: paymentRequest
        )
    }

    private func getInfoText() -> String? {
        switch profile.type {
        case .business:
            paymentRequest.link
        case .personal:
            nil
        }
    }

    private func makeShareButtonViewModels() -> [CreatePaymentRequestConfirmationViewModel.ButtonViewModel] {
        [
            CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                icon: Icons.shareIos.image,
                title: L10n.PaymentRequest.Create.Confirm.Button.share,
                action: shareTapped
            ),
            CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                icon: Icons.link.image,
                title: L10n.PaymentRequest.Create.Confirm.Button.copy,
                action: copyTapped
            ),
            CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                icon: Icons.qrCode.image,
                title: L10n.PaymentRequest.Create.Confirm.Button.qrCode,
                action: qrCodeTapped
            ),
        ]
    }

    private func showPrivacyNoticeTapped() {
        view?.showPrivacyNotice(
            with: CreatePaymentRequestConfirmationPrivacyNoticeViewModel(
                title: L10n.PaymentRequest.Create.Confirm.PrivacyNotice.Explanation.title,
                info: getPrivacyNoticeText()
            )
        )
    }

    private func makeViewModel() -> CreatePaymentRequestConfirmationViewModel {
        CreatePaymentRequestConfirmationViewModel(
            asset: .scene3D(.checkMark, renderAutomatically: true),
            title: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: L10n.PaymentRequest.Create.Confirm.Header.title,
                style: LabelStyle.display.centered,
                action: nil
            ),
            info: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: getInfoText(),
                style: LabelStyle.largeBody.centered,
                action: nil
            ),
            privacyNotice: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: L10n.PaymentRequest.Create.Confirm.privacyNotice,
                style: LabelStyle.defaultBody.centered,
                action: { [weak self] in
                    self?.showPrivacyNoticeTapped()
                }
            ),
            shareButtons: makeShareButtonViewModels(),
            shouldShowExtendedFooter: profile.type == .business
        )
    }

    private func configureView() {
        let viewModel = makeViewModel()
        view?.configure(with: viewModel)
    }

    private func getPrivacyNoticeText() -> String {
        let hasAvatar = profile.avatar.downloadedImage != nil
        switch profile.type {
        case .business:
            if paymentRequest.selectedPaymentMethods.contains(.bankTransfer) {
                return hasAvatar
                    ? L10n.PaymentRequest.Create.Confirm.PrivacyNotice.Explanation.Business.withAccountDetailsAndAvatar
                    : L10n.PaymentRequest.Create.Confirm.PrivacyNotice.Explanation.Business.withAccountDetailsButNoAvatar
            } else {
                return hasAvatar
                    ? L10n.PaymentRequest.Create.Confirm.PrivacyNotice.Explanation.Business.withoutAccountDetailsButHasAvatar
                    : L10n.PaymentRequest.Create.Confirm.PrivacyNotice.Explanation.Business.withoutAccountDetailsAndAvatar
            }
        case .personal:
            return hasAvatar
                ? L10n.PaymentRequest.Create.Confirm.PrivacyNotice.Explanation.Personal.withAvatar
                : L10n.PaymentRequest.Create.Confirm.PrivacyNotice.Explanation.Personal.withoutAvatar
        }
    }
}

extension CreatePaymentRequestConfirmationPresenterImpl: CreatePaymentRequestConfirmationPresenter {
    func dismiss() {
        let result = CreatePaymentRequestFlowResult.success(
            paymentRequestId: paymentRequest.id,
            context: .completed
        )
        onSuccess(result)
    }

    func start(with view: CreatePaymentRequestConfirmationView) {
        self.view = view
        configureView()
    }

    func privacyPolicyTapped() {
        router.showPrivacyPolicy()
    }

    func giveFeedbackTapped() {
        let model = FeedbackViewModel(
            title: L10n.PaymentRequest.Create.Confirm.GiveFeedback.title,
            description: L10n.PaymentRequest.Create.Confirm.Feedback.title,
            ratingMode: .sevenScale(legend: .range(
                min: L10n.PaymentRequest.Create.Confirm.Feedback.Form.minValue,
                max: L10n.PaymentRequest.Create.Confirm.Feedback.Form.maxValue
            )),
            placeholder: L10n.Balance.Shared.Feedback.placeholder,
            submitButtonTitle: L10n.PaymentRequest.Create.Confirm.Feedback.Form.submit
        )
        let context = FeedbackContext(
            feature: "PAYMENT_LINKS_QUALITY_SURVEY",
            pageName: nil,
            profileId: profile.id
        )

        router.showFeedback(
            model: model,
            context: context,
            onSuccess: { [weak self] in
                guard let self else {
                    return
                }
                view?.showSnackbar(message: L10n.PaymentRequest.Create.Confirm.Feedback.successMessage)
            }
        )
    }

    func doneTapped() {
        let result = CreatePaymentRequestFlowResult.success(
            paymentRequestId: paymentRequest.id,
            context: .linkCreation
        )
        onSuccess(result)
    }
}
