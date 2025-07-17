import AnalyticsKit
import Combine
import CombineSchedulers
import Foundation
import Neptune
import Prism
import TransferResources
import UserKit

// sourcery: AutoMockable
protocol WisetagContactOnWisePresenter: AnyObject {
    func start(with view: WisetagContactOnWiseView)
}

final class WisetagContactOnWisePresenterImpl {
    private let nickname: String?
    private var isDiscoverable: Bool
    private let profile: Profile
    private let router: WisetagContactOnWiseRouter

    private weak var view: WisetagContactOnWiseView?
    private let quickpayAnalyticsTracker: BusinessProfileLinkTracking

    init(
        nickname: String?,
        profile: Profile,
        router: WisetagContactOnWiseRouter,
        quickpayAnalyticsTracker: BusinessProfileLinkTracking
    ) {
        self.nickname = nickname
        self.profile = profile
        self.router = router
        self.quickpayAnalyticsTracker = quickpayAnalyticsTracker
        isDiscoverable = nickname != nil ? true : false
    }
}

// MARK: - WisetagContactOnWisePresenter

extension WisetagContactOnWisePresenterImpl: WisetagContactOnWisePresenter {
    func start(with view: WisetagContactOnWiseView) {
        self.view = view
        let viewModel = makeViewModel()
        view.configure(with: viewModel)
    }
}

// MARK: - Helpers

private extension WisetagContactOnWisePresenterImpl {
    func makeAvatarViewModel() -> AvatarViewModel {
        guard let avatar = profile.avatar.downloadedImage else {
            let displayName = ProfileInitialsDisplayName(profile: profile)
            return .initials(Initials(value: displayName.name))
        }
        return .image(avatar)
    }

    func makeWisetagSwitchOption() -> WisetagContactOnWiseViewModel.SwitchOption {
        switch profile {
        case .personal:
            WisetagContactOnWiseViewModel.SwitchOption(
                viewModel: SwitchOptionViewModel(
                    model: OptionViewModel(
                        title: L10n.Wisetag.ContactOnWise.Options.Title.wisetag,
                        subtitle: nickname,
                        avatar: makeAvatarViewModel(),
                        isEnabled: profile.has(privilege: ProfileIdentifierDiscoverabilityPrivilege.manage)
                    ),
                    isOn: isDiscoverable
                ),
                onToggle: { [weak self] isOn in
                    self?.isDiscoverable = isOn
                }
            )
        case .business:
            WisetagContactOnWiseViewModel.SwitchOption(
                viewModel: SwitchOptionViewModel(
                    model: OptionViewModel(
                        title: L10n.Quickpay.Discoverability.Options.title,
                        subtitle: L10n.Quickpay.Discoverability.Options.subtitle,
                        avatar: makeAvatarViewModel(),
                        isEnabled: profile.has(privilege: ProfileIdentifierDiscoverabilityPrivilege.manage) ? true : false
                    ),
                    isOn: isDiscoverable
                ),
                onToggle: { [weak self] isOn in self?.isDiscoverable = isOn }
            )
        }
    }

    func makeAction() -> Action {
        Action(
            title: L10n.Wisetag.ContactOnWise.Button.title,
            handler: { [weak self] in
                guard let self else {
                    return
                }

                let didChangeStatus = (nickname == nil && isDiscoverable) || (nickname != nil && !isDiscoverable)
                router.dismissAndUpdateShareableLinkStatus(
                    didChangeDiscoverability: didChangeStatus,
                    isDiscoverable: isDiscoverable
                )
                quickpayAnalyticsTracker.onDiscoverabilityToggled(toggleState: isDiscoverable ? .enabled : .disabled)
            }
        )
    }

    func makeAlert() -> WisetagContactOnWiseViewModel.Alert? {
        profile.has(privilege: ProfileIdentifierDiscoverabilityPrivilege.manage)
            ? nil
            : WisetagContactOnWiseViewModel.Alert(
                viewModel: .init(markdown: L10n.Wisetag.ContactOnWise.PermissionsAlert.text),
                style: .neutral
            )
    }

    func getTitle() -> String {
        switch profile {
        case .personal:
            L10n.Wisetag.ContactOnWise.title
        case .business:
            L10n.Quickpay.Discoverability.title
        }
    }

    func getSubtitle() -> String {
        switch profile {
        case .personal:
            L10n.Wisetag.ContactOnWise.subtitle
        case .business:
            L10n.Quickpay.Discoverability.subtitle
        }
    }

    func makeViewModel() -> WisetagContactOnWiseViewModel {
        WisetagContactOnWiseViewModel(
            title: getTitle(),
            subtitle: getSubtitle(),
            inlineAlert: makeAlert(),
            wisetagOption: makeWisetagSwitchOption(),
            action: makeAction()
        )
    }
}
