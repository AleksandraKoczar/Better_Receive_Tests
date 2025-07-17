import AnalyticsKit
import Combine
import CombineSchedulers
import ContactsKit
import Foundation
import Neptune
import Prism
import ReceiveKit
import TWFoundation
import TWUI
import UIKit
import UserKit
import WiseCore

// sourcery: AutoMockable
protocol CreatePaymentRequestViewControllerFactory: AnyObject, DynamicTypeAccessible {
    func makeCreatePaymentRequestFromContactSuccess(
        with viewModel: CreatePaymentRequestFromContactSuccessViewModel
    ) -> UIViewController

    func makeContactPicker(
        profile: Profile,
        router: RequestMoneyContactPickerRouter,
        navigationController: UINavigationController
    ) -> UIViewController

    func makeOnboardingViewController(
        profile: Profile,
        routingDelegate: PaymentRequestOnboardingRoutingDelegate
    ) -> UIViewController

    func makeCreatePaymentRequestBusiness(
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestRoutingDelegate
    ) -> UIViewController

    func makeCreatePaymentRequestPersonal(
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate
    ) -> UIViewController

    func makeCreatePaymentRequestPersonalBottomSheet(
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate
    ) -> UIViewController

    func makeRequestFromAnyoneViewController(
        profile: Profile,
        routingDelegate: RequestFromAnyoneRoutingDelegate
    ) -> UIViewController

    func makeConfirmation(
        paymentRequest: PaymentRequestV2,
        profile: Profile,
        onSuccess: @escaping (CreatePaymentRequestFlowResult) -> Void
    ) -> UIViewController

    func makeCardTerms(url: URL) -> UIViewController

    func makePaymentMethodsSelection(
        delegate: PaymentMethodsDelegate,
        routingDelegate: CreatePaymentRequestRoutingDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        paymentMethodsAvailability: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        onPaymentMethodsSelected: @escaping (([PaymentRequestV2PaymentMethods]) -> Void)
    ) -> UIViewController
}

final class CreatePaymentRequestViewControllerFactoryImpl: CreatePaymentRequestViewControllerFactory {
    private let paymentRequestUseCase: PaymentRequestUseCaseV2
    private let paymentMethodsUseCase: PaymentMethodsUseCase
    private let paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCase
    private let paymentRequestProductEligibilityUseCase: PaymentRequestProductEligibilityUseCase

    private let wisetagUseCase: WisetagUseCase
    private let paymentRequestOnboardingPreferenceUseCase: PaymentRequestOnboardingPreferenceUseCase
    private let payWithWiseNudgePreferenceUseCase: PayWithWiseNudgePreferenceUseCase
    private let featureService: FeatureService
    private let userProvider: UserProvider
    private let feedbackService: FeedbackService
    private let eligibilityService: ReceiveEligibilityService
    private let webViewControllerFactory: WebViewControllerFactory.Type

    init(
        paymentRequestUseCase: PaymentRequestUseCaseV2 = PaymentRequestUseCaseFactoryV2.make(),
        paymentMethodsUseCase: PaymentMethodsUseCase = PaymentMethodsUseCaseFactory.make(),
        paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCase = PaymentRequestEligibilityUseCaseFactory.make(),
        paymentRequestProductEligibilityUseCase: PaymentRequestProductEligibilityUseCase = PaymentRequestProductEligibilityUseCaseFactory.make(),
        paymentRequestOnboardingPreferenceUseCase: PaymentRequestOnboardingPreferenceUseCase = PaymentRequestOnboardingPreferenceUseCaseFactory.make(),
        payWithWiseNudgePreferenceUseCase: PayWithWiseNudgePreferenceUseCase = PayWithWiseNudgePreferenceUseCaseFactory.make(),
        wisetagUseCase: WisetagUseCase = WisetagUseCaseFactory.make(),
        eligibilityService: ReceiveEligibilityService,
        feedbackService: FeedbackService,
        featureService: FeatureService = GOS[FeatureServiceKey.self],
        userProvider: UserProvider = GOS[UserProviderKey.self],
        webViewControllerFactory: WebViewControllerFactory.Type
    ) {
        self.paymentRequestUseCase = paymentRequestUseCase
        self.paymentMethodsUseCase = paymentMethodsUseCase
        self.paymentRequestEligibilityUseCase = paymentRequestEligibilityUseCase
        self.paymentRequestProductEligibilityUseCase = paymentRequestProductEligibilityUseCase
        self.paymentRequestOnboardingPreferenceUseCase = paymentRequestOnboardingPreferenceUseCase
        self.payWithWiseNudgePreferenceUseCase = payWithWiseNudgePreferenceUseCase
        self.wisetagUseCase = wisetagUseCase
        self.eligibilityService = eligibilityService
        self.feedbackService = feedbackService
        self.featureService = featureService
        self.userProvider = userProvider
        self.webViewControllerFactory = webViewControllerFactory
    }

    func makeCreatePaymentRequestFromContactSuccess(
        with viewModel: CreatePaymentRequestFromContactSuccessViewModel
    ) -> UIViewController {
        let configuation = PromptConfiguration.make(
            asset: viewModel.asset,
            title: viewModel.title,
            message: .text(viewModel.message),
            secondaryButton: viewModel.buttonConfiguration,
            appearHaptics: .success
        )
        return PromptViewControllerFactory.make(from: configuation)
    }

    func makeContactPicker(
        profile: Profile,
        router: RequestMoneyContactPickerRouter,
        navigationController: UINavigationController
    ) -> UIViewController {
        let contactListPagePublisherFactory = ContactsFactory.makeContactListPagePublisherFactory(
            profileId: profile.id,
            uriImageLoader: URIImageLoaderImpl(),
            svgImageLoader: ImageCacheImpl()
        )

        let nudgeProvider = ContactPickerNudgeProviderImpl(
            userProvider: userProvider,
            inviteStorage: ContactPickerInviteFriendsPreferenceStorageImpl()
        )

        let presenter = RequestMoneyContactPickerPresenterImpl(
            profile: profile,
            contactListPagePublisherFactory: contactListPagePublisherFactory,
            nudgeProvider: nudgeProvider,
            mapper: RequestMoneyContactPickerMapperImpl(),
            router: router
        )

        return RequestMoneyContactPickerViewController(
            presenter: presenter
        )
    }

    func makeOnboardingViewController(
        profile: Profile,
        routingDelegate: PaymentRequestOnboardingRoutingDelegate
    ) -> UIViewController {
        let presenter = PaymentRequestOnboardingPresenterImpl(
            profile: profile,
            paymentRequestOnboardingPreferenceUseCase: paymentRequestOnboardingPreferenceUseCase,
            routingDelegate: routingDelegate
        )
        return PaymentRequestOnboardingViewController(presenter: presenter)
    }

    func makeRequestFromAnyoneViewController(
        profile: Profile,
        routingDelegate: RequestFromAnyoneRoutingDelegate
    ) -> UIViewController {
        let presenter = RequestFromAnyonePresenterImpl(
            wisetagUseCase: wisetagUseCase,
            routingDelegate: routingDelegate,
            profile: profile,
            pasteboard: UIPasteboard.general
        )
        return RequestPaymentFromAnyoneViewController(presenter: presenter)
    }

    func makeCreatePaymentRequestPersonal(
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestPersonalRoutingDelegate
    ) -> UIViewController {
        let presenter = CreatePaymentRequestPersonalPresenterImpl(
            paymentRequestUseCase: paymentRequestUseCase,
            paymentMethodsUseCase: paymentMethodsUseCase,
            paymentRequestEligibilityUseCase: paymentRequestEligibilityUseCase,
            payWithWiseNudgePreferenceUseCase: payWithWiseNudgePreferenceUseCase,
            viewModelMapper: CreatePaymentRequestPersonalViewModelMapperImpl(),
            profile: profile,
            paymentRequestInfo: paymentRequestInfo,
            routingDelegate: routingDelegate,
            avatarFetcher: CancellableAvatarFetcherImpl(
                scheduler: .main
            ),
            eligibilityService: eligibilityService
        )
        return CreatePaymentRequestPersonalViewController(presenter: presenter)
    }

    func makeCreatePaymentRequestPersonalBottomSheet(
        paymentRequestInfo: CreatePaymentRequestPersonalPresenterInfo,
        profile: UserKit.Profile,
        routingDelegate: any CreatePaymentRequestPersonalRoutingDelegate
    ) -> UIViewController {
        let presenter = CreatePaymentRequestPersonalPresenterImpl(
            paymentRequestUseCase: paymentRequestUseCase,
            paymentMethodsUseCase: paymentMethodsUseCase,
            paymentRequestEligibilityUseCase: paymentRequestEligibilityUseCase,
            payWithWiseNudgePreferenceUseCase: payWithWiseNudgePreferenceUseCase,
            viewModelMapper: CreatePaymentRequestPersonalViewModelMapperImpl(),
            profile: profile,
            paymentRequestInfo: paymentRequestInfo,
            routingDelegate: routingDelegate,
            avatarFetcher: CancellableAvatarFetcherImpl(
                scheduler: .main
            ),
            eligibilityService: eligibilityService
        )
        return CreatePaymentRequestPersonalBottomSheetViewController(presenter: presenter)
    }

    func makeCreatePaymentRequestBusiness(
        paymentRequestInfo: CreatePaymentRequestPresenterInfo,
        profile: Profile,
        routingDelegate: CreatePaymentRequestRoutingDelegate
    ) -> UIViewController {
        let prismTracker = MixpanelPrismTracker()
        let paymentRequestTracker = PaymentRequestTrackingFactory().make(
            onTrack: prismTracker.trackEvent(name:properties:)
        )

        let interactor = CreatePaymentRequestInteractorImpl(
            profile: profile,
            paymentRequestUseCase: PaymentRequestUseCaseFactoryV2.make(),
            paymentMethodsUseCase: PaymentMethodsUseCaseFactory.make(),
            paymentRequestProductEligibilityUseCase: PaymentRequestProductEligibilityUseCaseFactory.make(),
            paymentRequestEligibilityUseCase: PaymentRequestEligibilityUseCaseFactory.make(),
            paymentRequestListUseCase: PaymentRequestListUseCaseFactory.make(),
            paymentRequestDetailsUseCase: PaymentRequestDetailsUseCaseFactory.make()
        )

        let presenter = CreatePaymentRequestPresenterImpl(
            interactor: interactor,
            viewModelMapper: CreatePaymentRequestViewModelMapperImpl(),
            profile: profile,
            paymentRequestInfo: paymentRequestInfo,
            featureService: featureService,
            routingDelegate: routingDelegate,
            prismAnalyticsTracker: paymentRequestTracker
        )
        return CreatePaymentRequestViewController(presenter: presenter)
    }

    func makeConfirmation(
        paymentRequest: PaymentRequestV2,
        profile: Profile,
        onSuccess: @escaping (CreatePaymentRequestFlowResult) -> Void
    ) -> UIViewController {
        let router = CreatePaymentRequestConfirmationRouterImpl(
            profile: profile,
            paymentRequest: paymentRequest,
            feedbackService: feedbackService
        )
        let presenter = CreatePaymentRequestConfirmationPresenterImpl(
            profile: profile,
            paymentRequest: paymentRequest,
            router: router,
            onSuccess: onSuccess
        )
        let viewController = CreatePaymentRequestConfirmationViewController(presenter: presenter)
        router.viewController = viewController
        return viewController
    }

    func makeCardTerms(url: URL) -> UIViewController {
        webViewControllerFactory.make(with: url)
    }

    func makePaymentMethodsSelection(
        delegate: PaymentMethodsDelegate,
        routingDelegate: CreatePaymentRequestRoutingDelegate,
        localPreferences: [PaymentRequestV2PaymentMethods],
        paymentMethodsAvailability: PaymentRequestV2ReceiverAvailability.ReceiverCurrencyAvailability,
        onPaymentMethodsSelected: @escaping (([PaymentRequestV2PaymentMethods]) -> Void)
    ) -> UIViewController {
        let presenter = CreatePaymentRequestPaymentMethodManagementPresenterImpl(
            delegate: delegate,
            routingDelegate: routingDelegate,
            localPreferences: localPreferences,
            paymentMethodsAvailability: paymentMethodsAvailability,
            onSave: onPaymentMethodsSelected
        )
        return CreatePaymentRequestPaymentMethodManagementViewController(presenter: presenter)
    }
}

// MARK: - Conformances

struct URIImageLoaderImpl {
    private let thumbnailLoader: ThumbnailLoader

    init(thumbnailLoader: ThumbnailLoader = ThumbnailLoaderFactory.make()) {
        self.thumbnailLoader = thumbnailLoader
    }
}

extension URIImageLoaderImpl: URIImageLoader {
    func load(_ uri: URI) -> AnyPublisher<UIImage, Error> {
        thumbnailLoader.load(uri)
            .map { $0.image }
            .eraseError()
            .eraseToAnyPublisher()
    }
}

extension ImageCacheImpl: @retroactive SVGImageLoader {}
