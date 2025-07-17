import AnalyticsKit
import Combine
import CombineSchedulers
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UserKit

// sourcery: AutoMockable
protocol PaymentRequestOnboardingPresenter: AnyObject {
    func start(with view: PaymentRequestOnboardingView)
    func dismissTapped()
}

final class PaymentRequestOnboardingPresenterImpl {
    private weak var view: PaymentRequestOnboardingView?
    private weak var routingDelegate: PaymentRequestOnboardingRoutingDelegate?

    private let profile: Profile
    private let paymentRequestOnboardingPreferenceUseCase: PaymentRequestOnboardingPreferenceUseCase
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let analyticsViewTracker: AnalyticsViewTrackerImpl<PaymentRequestOnboardingAnalyticsView>

    private var cancellable: AnyCancellable?

    init(
        profile: Profile,
        paymentRequestOnboardingPreferenceUseCase: PaymentRequestOnboardingPreferenceUseCase,
        routingDelegate: PaymentRequestOnboardingRoutingDelegate,
        analyticsTracker: AnalyticsTracker = GOS[AnalyticsTrackerKey.self],
        scheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.profile = profile
        self.paymentRequestOnboardingPreferenceUseCase = paymentRequestOnboardingPreferenceUseCase
        self.routingDelegate = routingDelegate
        self.scheduler = scheduler
        analyticsViewTracker = AnalyticsViewTrackerImpl(
            contextIdentity: PaymentRequestOnboardingAnalyticsView.identity,
            analyticsTracker: analyticsTracker
        )
    }
}

// MARK: - View model creation

private extension PaymentRequestOnboardingPresenterImpl {
    func makeSubtitle() -> String {
        profile.type == .business
            ? L10n.PaymentRequest.Onboarding.Business.subtitle
            : L10n.PaymentRequest.Onboarding.Personal.subtitle
    }

    func makeFirstSummaryViewModel() -> PaymentRequestOnboardingViewModel.SummaryViewModel {
        let description = profile.type == .business
            ? L10n.PaymentRequest.Onboarding.FirstSummary.Business.description
            : L10n.PaymentRequest.Onboarding.FirstSummary.Personal.description
        return PaymentRequestOnboardingViewModel.SummaryViewModel(
            title: L10n.PaymentRequest.Onboarding.FirstSummary.title,
            description: description,
            icon: Icons.limit.image
        )
    }

    func makeSecondSummaryViewModel() -> PaymentRequestOnboardingViewModel.SummaryViewModel {
        PaymentRequestOnboardingViewModel.SummaryViewModel(
            title: L10n.PaymentRequest.Onboarding.SecondSummary.title,
            description: L10n.PaymentRequest.Onboarding.SecondSummary.description,
            icon: Icons.link.image
        )
    }

    func makeThirdSummaryViewModel() -> PaymentRequestOnboardingViewModel.SummaryViewModel {
        let isBusinessProfile = profile.type == .business
        let title = isBusinessProfile
            ? L10n.PaymentRequest.Onboarding.ThirdSummary.Business.title
            : L10n.PaymentRequest.Onboarding.ThirdSummary.Personal.title
        let description = isBusinessProfile
            ? L10n.PaymentRequest.Onboarding.ThirdSummary.Business.description
            : L10n.PaymentRequest.Onboarding.ThirdSummary.Personal.description
        return PaymentRequestOnboardingViewModel.SummaryViewModel(
            title: title,
            description: description,
            icon: Icons.requestReceive.image
        )
    }

    func makeFooterButtonAction(isOnboardingRequired: Bool) -> Action {
        Action(
            title: L10n.PaymentRequest.Onboarding.FooterButton.title,
            handler: { [weak self] in
                guard let self else {
                    return
                }
                let action = PaymentRequestOnboardingAnalyticsView.StartPressed()
                analyticsViewTracker.track(action)
                paymentRequestOnboardingPreferenceUseCase.setIsOnboardingRequired(false, for: profile)
                routingDelegate?.moveToNextStepAfterOnboarding(isOnboardingRequired: isOnboardingRequired)
            }
        )
    }

    func makeViewModel(isOnboardingRequired: Bool) -> PaymentRequestOnboardingViewModel {
        let summaryViewModels = [
            makeFirstSummaryViewModel(),
            makeSecondSummaryViewModel(),
            makeThirdSummaryViewModel(),
        ]
        return PaymentRequestOnboardingViewModel(
            titleText: L10n.PaymentRequest.Onboarding.title,
            subtitleText: makeSubtitle(),
            image: Neptune.Illustrations.receive.image,
            summaryViewModels: summaryViewModels,
            footerButtonAction: makeFooterButtonAction(isOnboardingRequired: isOnboardingRequired)
        )
    }
}

// MARK: - PaymentRequestOnboardingPresenter

extension PaymentRequestOnboardingPresenterImpl: PaymentRequestOnboardingPresenter {
    func start(with view: PaymentRequestOnboardingView) {
        self.view = view
        self.view?.showHud()
        cancellable = paymentRequestOnboardingPreferenceUseCase
            .isOnboardingRequired(for: profile)
            .receive(on: scheduler)
            .sink { [weak self] isOnboardingRequired in
                guard let self else {
                    return
                }
                self.view?.hideHud()
                guard isOnboardingRequired else {
                    routingDelegate?.moveToNextStepAfterOnboarding(isOnboardingRequired: false)
                    return
                }
                let viewModel = makeViewModel(isOnboardingRequired: isOnboardingRequired)
                self.view?.configure(with: viewModel)
            }
    }

    func dismissTapped() {
        let action = PaymentRequestOnboardingAnalyticsView.ExitPressed()
        analyticsViewTracker.track(action)
        paymentRequestOnboardingPreferenceUseCase.setIsOnboardingRequired(false, for: profile)
        routingDelegate?.dismiss()
    }
}
