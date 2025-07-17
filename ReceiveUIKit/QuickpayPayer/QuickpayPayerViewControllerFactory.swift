import AnalyticsKit
import ContactsKit
import Foundation
import Prism
import ReceiveKit
import TWFoundation
import UIKit
import UserKit

// sourcery: AutoMockable
protocol QuickpayPayerViewControllerFactory {
    func makePayerBottomsheet(
        profile: Profile,
        quickpay: String,
        payerInputs: QuickpayPayerInputs?,
        businessInfo: ContactSearch,
        router: QuickpayPayerRouter
    ) -> UIViewController
}

struct QuickpayPayerViewControllerFactoryImpl: QuickpayPayerViewControllerFactory {
    func makePayerBottomsheet(
        profile: Profile,
        quickpay: String,
        payerInputs: QuickpayPayerInputs?,
        businessInfo: ContactSearch,
        router: QuickpayPayerRouter
    ) -> UIViewController {
        let prismTracker = MixpanelPrismTracker()
        let quickpayTracker = QuickpayTrackingFactory().make(
            onTrack: prismTracker.trackEvent(name:properties:)
        )

        let presenter = QuickpayPayerPresenterImpl(
            profile: profile,
            businessInfo: businessInfo,
            quickpayName: quickpay,
            quickpayPayerInputs: payerInputs,
            quickpayUseCase: QuickpayUseCaseFactory.make(),
            analyticsTracker: quickpayTracker,
            router: router,
            scheduler: .main
        )

        return QuickpayPayerViewController(presenter: presenter)
    }
}
