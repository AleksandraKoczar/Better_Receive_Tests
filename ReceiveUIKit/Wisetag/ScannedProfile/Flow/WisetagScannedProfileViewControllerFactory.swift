import AnalyticsKit
import ContactsKit
import TWFoundation
import UIKit
import UserKit

// sourcery: AutoMockable
protocol WisetagScannedProfileViewControllerFactory {
    func makeScannedProfile(
        profile: Profile,
        nickname: String,
        contactSearch: ContactSearch,
        router: WisetagScannedProfileRouter
    ) -> (UIViewController, WisetagScannedProfilePresenter)
}

struct WisetagScannedProfileViewControllerFactoryImp: WisetagScannedProfileViewControllerFactory {
    private let wisetagContactInteractor: WisetagContactInteractor

    init(
        wisetagContactInteractor: WisetagContactInteractor
    ) {
        self.wisetagContactInteractor = wisetagContactInteractor
    }

    func makeScannedProfile(
        profile: Profile,
        nickname: String,
        contactSearch: ContactSearch,
        router: WisetagScannedProfileRouter
    ) -> (UIViewController, WisetagScannedProfilePresenter) {
        let presenter = WisetagScannedProfilePresenterImpl(
            profile: profile,
            scannedProfileNickname: nickname,
            contactSearch: contactSearch,
            router: router,
            analyticsTracker: GOS[AnalyticsTrackerKey.self],
            viewModelMapper: WisetagScannedProfileViewModelMapperImpl(),
            wisetagContactInteractor: wisetagContactInteractor,
            scheduler: .main
        )
        return (WisetagScannedProfileViewController(presenter: presenter), presenter)
    }
}
