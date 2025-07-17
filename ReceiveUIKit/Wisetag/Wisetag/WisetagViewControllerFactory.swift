import AnalyticsKit
import BalanceKit
import DeepLinkKit
import Neptune
import Prism
import ReceiveKit
import TransferResources
import TWFoundation
import TWUI
import UIKit
import UserKit

// sourcery: AutoMockable
protocol WisetagViewControllerFactory {
    func makeWisetag(
        shouldBecomeDiscoverable: Bool,
        profile: Profile,
        router: WisetagRouter
    ) -> (UIViewController, WisetagShareableLinkStatusUpdater)
    func makeQuickpay(
        profile: Profile,
        router: QuickpayRouter
    ) -> (UIViewController, QuickpayShareableLinkStatusUpdater)
    func makeWisetagLearnMore(
        router: WisetagRouter,
        route: DeepLinkStoryRoute
    ) -> UIViewController
    func makeContactOnWise(
        nickname: String?,
        profile: Profile,
        router: WisetagContactOnWiseRouter
    ) -> UIViewController
    func makeManageQuickpay(
        router: QuickpayRouter,
        nickname: String?
    ) -> UIViewController
    func makeQuickpayInPerson(
        profile: Profile,
        status: ShareableLinkStatus.Discoverability,
        router: QuickpayRouter
    ) -> (UIViewController, QuickpayShareableLinkStatusUpdater)
    func makeQuickpayPersonalise(
        profile: Profile,
        status: ShareableLinkStatus.Discoverability,
        router: QuickpayRouter
    ) -> UIViewController
}

struct WisetagViewControllerFactoryImpl: WisetagViewControllerFactory {
    private let featureService: FeatureService

    init(featureService: FeatureService = GOS[FeatureServiceKey.self]) {
        self.featureService = featureService
    }

    func makeWisetag(
        shouldBecomeDiscoverable: Bool,
        profile: Profile,
        router: WisetagRouter
    ) -> (UIViewController, WisetagShareableLinkStatusUpdater) {
        let wisetagInteractor = WisetagInteractorImpl(
            profile: profile,
            wisetagUseCase: WisetagUseCaseFactory.make(),
            accountDetailsUseCase: AccountDetailsUseCaseFactory.makeUseCase(),
            paymentMethodsUseCase: PaymentMethodsUseCaseFactory.make(),
            paymentRequestUseCase: PaymentRequestUseCaseFactoryV2.make()
        )
        let presenter = WisetagPresenterImpl(
            shouldBecomeDiscoverable: shouldBecomeDiscoverable,
            profile: profile,
            interactor: wisetagInteractor,
            viewModelMapper: WisetagViewModelMapperImpl(),
            router: router,
            analyticsTracker: GOS[AnalyticsTrackerKey.self],
            pasteboard: UIPasteboard.general,
            scheduler: .main
        )
        return (WisetagViewController(presenter: presenter), presenter)
    }

    func makeQuickpay(
        profile: Profile,
        router: QuickpayRouter
    ) -> (UIViewController, QuickpayShareableLinkStatusUpdater) {
        let prismTracker = MixpanelPrismTracker()
        let quickpayTracker = BusinessProfileLinkTrackingFactory().make(
            onTrack: prismTracker.trackEvent(name:properties:)
        )

        let wisetagInteractor = WisetagInteractorImpl(
            profile: profile,
            wisetagUseCase: WisetagUseCaseFactory.make(),
            accountDetailsUseCase: AccountDetailsUseCaseFactory.makeUseCase(),
            paymentMethodsUseCase: PaymentMethodsUseCaseFactory.make(),
            paymentRequestUseCase: PaymentRequestUseCaseFactoryV2.make()
        )

        let presenter = QuickpayPresenterImpl(
            profile: profile,
            quickpayUseCase: QuickpayUseCaseFactory.make(),
            wisetagInteractor: wisetagInteractor,
            viewModelMapper: QuickpayViewModelMapperImpl(),
            router: router,
            analyticsTracker: quickpayTracker,
            pasteboard: UIPasteboard.general,
            featureService: featureService,
            scheduler: .main
        )
        return (QuickpayViewController(presenter: presenter), presenter)
    }

    @MainActor
    func makeQuickpayInPerson(
        profile: Profile,
        status: ShareableLinkStatus.Discoverability,
        router: QuickpayRouter
    ) -> (UIViewController, QuickpayShareableLinkStatusUpdater) {
        let wisetagInteractor = WisetagInteractorImpl(
            profile: profile,
            wisetagUseCase: WisetagUseCaseFactory.make(),
            accountDetailsUseCase: AccountDetailsUseCaseFactory.makeUseCase(),
            paymentMethodsUseCase: PaymentMethodsUseCaseFactory.make(),
            paymentRequestUseCase: PaymentRequestUseCaseFactoryV2.make()
        )

        let viewModel = QuickpayInPersonViewModel(
            profile: profile,
            quickpayUseCase: QuickpayUseCaseFactory.make(),
            wisetagInteractor: wisetagInteractor,
            status: status,
            pasteboard: UIPasteboard.general,
            onDownloadQRCodeTapped: { [weak router] image in
                guard let router else { return }
                router.startDownload(image: image)
            }
        )

        let vc = SwiftUIHostingController {
            QuickpayInPersonView(viewModel: viewModel)
        }

        vc.navigationItem.title = L10n.Quickpay.PersonalisePage.InPersonPayments.title
        let barButtonItem = UIBarButtonItem()
        barButtonItem.customView = IconButtonView(
            icon: Icons.slider.image,
            discoverabilityTitle: "",
            handler: { [weak viewModel, weak router] in
                guard let router else { return }
                router.showManageQuickpay(nickname: viewModel?.nickname)
            }
        )
        vc.navigationItem.rightBarButtonItem = barButtonItem
        return (vc, viewModel)
    }

    @MainActor
    func makeQuickpayPersonalise(
        profile: Profile,
        status: ShareableLinkStatus.Discoverability,
        router: QuickpayRouter
    ) -> UIViewController {
        let prismTracker = MixpanelPrismTracker()
        let quickpayTracker = BusinessProfileLinkTrackingFactory().make(
            onTrack: prismTracker.trackEvent(name:properties:)
        )
        let wisetagInteractor = WisetagInteractorImpl(
            profile: profile,
            wisetagUseCase: WisetagUseCaseFactory.make(),
            accountDetailsUseCase: AccountDetailsUseCaseFactory.makeUseCase(),
            paymentMethodsUseCase: PaymentMethodsUseCaseFactory.make(),
            paymentRequestUseCase: PaymentRequestUseCaseFactoryV2.make()
        )
        let viewModel = QuickpayPersonaliseViewModel(
            quickpayUseCase: QuickpayUseCaseFactory.make(),
            wisetagInteractor: wisetagInteractor,
            status: status,
            analyticsTracker: quickpayTracker,
            pasteboard: UIPasteboard.general,
            onDownloadQRCodeTapped: { [weak router] image in
                guard let router else { return }
                router.startDownload(image: image)
            }
        )

        let vc = SwiftUIHostingController {
            QuickpayPersonaliseView(viewModel: viewModel)
        }
        vc.navigationItem.title = L10n.Quickpay.MainPage.PersonaliseButton.title
        return vc
    }

    func makeWisetagLearnMore(
        router: WisetagRouter,
        route: DeepLinkStoryRoute
    ) -> UIViewController {
        BottomSheetViewController.makeInfoSheet(
            viewModel: InfoSheetViewModel(
                title: L10n.Wisetag.LearnMore.title,
                info: .text(L10n.Wisetag.LearnMore.info),
                primaryAction: .init(makeAction(router: router, route: route)),
                footer: .simple(button: .secondary)
            )
        )
    }

    func makeManageQuickpay(
        router: QuickpayRouter,
        nickname: String?
    ) -> UIViewController {
        let methodsOption = StackNavigationOptionView(
            viewModel: .init(
                title: L10n.Quickpay.ManageQuickpay.PaymentMethods.title,
                subtitle: L10n.Quickpay.ManageQuickpay.PaymentMethods.subtitle,
                avatar: AvatarViewModel._icon(Icons.bank.image, badge: nil)
            ),
            onTap: { [weak router] in
                guard let router else { return }
                router.showPaymentMethodsOnWeb()
            }
        )
        let discoverabilityOption = StackNavigationOptionView(
            viewModel: .init(
                title: L10n.Quickpay.ManageQuickpay.Discoverability.title,
                subtitle: L10n.Quickpay.ManageQuickpay.Discoverability.subtitle,
                avatar: AvatarViewModel._icon(Icons.search.image, badge: nil)
            ),
            onTap: { [weak router] in
                guard let router else { return }
                router.showDiscoverability(nickname: nickname)
            }
        )
        return BottomSheetViewController(
            title: L10n.Quickpay.ManageQuickpay.title,
            arrangedSubviews: [methodsOption, discoverabilityOption]
        )
    }

    func makeAction(router: WisetagRouter, route: DeepLinkStoryRoute) -> Action {
        Action(
            title: L10n.Wisetag.LearnMore.cta,
            handler: { [weak router] in
                guard let router else { return }
                router.showLearnMoreStory(route: route)
            }
        )
    }

    func makeContactOnWise(
        nickname: String?,
        profile: Profile,
        router: WisetagContactOnWiseRouter
    ) -> UIViewController {
        let prismTracker = MixpanelPrismTracker()
        let quickpayTracker = BusinessProfileLinkTrackingFactory().make(
            onTrack: prismTracker.trackEvent(name:properties:)
        )

        let presenter = WisetagContactOnWisePresenterImpl(
            nickname: nickname,
            profile: profile,
            router: router,
            quickpayAnalyticsTracker: quickpayTracker
        )
        return WisetagContactOnWiseViewController(presenter: presenter)
    }
}
