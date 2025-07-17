import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UIKit
import UserKit

// sourcery: AutoMockable
protocol WisetagViewModelDelegate: AnyObject {
    func showWisetagLearnMore()
    func shareLinkTapped(_ urlString: String)
    func qrCodeTapped()
    func footerButtonTapped()
    func showDiscoverabilityBottomSheet()
    func scanQRcodeTapped()
    func downloadTapped()
    func linkTapped()
}

// sourcery: AutoMockable
protocol WisetagViewModelMapper {
    func make(
        profile: Profile,
        status: ShareableLinkStatus,
        qrCodeImage: UIImage?,
        delegate: WisetagViewModelDelegate
    ) -> WisetagViewModel
}

struct WisetagViewModelMapperImpl: WisetagViewModelMapper {
    func make(
        profile: Profile,
        status: ShareableLinkStatus,
        qrCodeImage: UIImage?,
        delegate: WisetagViewModelDelegate
    ) -> WisetagViewModel {
        WisetagViewModel(
            header: makeHeaderViewModel(
                profile: profile,
                status: status,
                delegate: delegate
            ),
            qrCode: makeQRCodeViewModel(
                status: status,
                qrCodeImage: qrCodeImage,
                delegate: delegate
            ),
            shareButtons: makeShareButtonViewModels(
                status: status,
                delegate: delegate
            ),
            footerAction: makeFooterAction(
                profile: profile,
                status: status,
                delegate: delegate
            ),
            navigationBarButtons: makeNavigationBarButtonViewModels(
                status: status,
                delegate: delegate
            )
        )
    }
}

// MARK: - Helpers

private extension WisetagViewModelMapperImpl {
    private enum Constants {
        static let placeholderURL = Branding.current.url.appendingPathComponent("wisetag")
        static let wiseDomain = "wise.com/pay/me/"
    }

    func makeHeaderLinkButton(
        status: ShareableLinkStatus,
        delegate: WisetagViewModelDelegate
    ) -> SmallButtonView.ViewModel? {
        guard case let .eligible(discoverability) = status,
              case let .discoverable(_, nickname) = discoverability else {
            return nil
        }
        return SmallButtonView.ViewModel(
            title: nickname,
            leadingIcon: Icons.fastFlag.image,
            handler: { [weak delegate] in
                delegate?.showWisetagLearnMore()
            }
        )
    }

    func makeHeaderViewModel(
        profile: Profile,
        status: ShareableLinkStatus,
        delegate: WisetagViewModelDelegate
    ) -> WisetagHeaderViewModel {
        let fallbackAvatarViewModel = AvatarViewModel.initials(
            Initials(value: ProfileInitialsDisplayName(profile: profile).name)
        )
        let avatarViewModel = profile.avatar.downloadedImage.map { AvatarViewModel.image($0) }
        guard case let .eligible(discoverability) = status,
              case let .discoverable(_, nickname) = discoverability else {
            return WisetagHeaderViewModel(
                avatar: avatarViewModel ?? fallbackAvatarViewModel,
                title: ProfileLocaleDisplayName(profile: profile, style: .full).name,
                linkType: .inactive(inactiveLink: L10n.Wisetag.subtitle)
            )
        }
        let linkString = Constants.wiseDomain + String(nickname.dropFirst())
        return WisetagHeaderViewModel(
            avatar: avatarViewModel ?? fallbackAvatarViewModel,
            title: ProfileLocaleDisplayName(profile: profile, style: .full).name,
            linkType: .active(link: linkString, touchHandler: { [weak delegate] in
                delegate?.linkTapped()
            })
        )
    }

    func makeQRCodeViewModel(
        status: ShareableLinkStatus,
        qrCodeImage: UIImage?,
        delegate: WisetagViewModelDelegate
    ) -> WisetagQRCodeViewModel {
        guard case let .eligible(discoverability) = status,
              case let .discoverable(urlString, nickname) = discoverability else {
            let urlString = Constants.placeholderURL.absoluteString
            let placeholderQRCode = qrCodeImage ?? UIImage.qrCode(from: urlString)

            return WisetagQRCodeViewModel(state: .qrCodeDisabled(
                placeholderQRCode: placeholderQRCode,
                disabledText: L10n.Wisetag.inactiveWisetag,
                onTap: { [weak delegate] in
                    delegate?.showDiscoverabilityBottomSheet()
                }
            ))
        }
        let qrCode = qrCodeImage ?? UIImage.qrCode(from: urlString)
        return WisetagQRCodeViewModel(state: .qrCodeEnabled(
            qrCode: qrCode,
            enabledText: nickname,
            enabledTextOnTap: L10n.Wisetag.QrCode.Copied.title,
            onTap: { [weak delegate] in
                delegate?.qrCodeTapped()
            }
        ))
    }

    func makeShareButtonViewModels(
        status: ShareableLinkStatus,
        delegate: WisetagViewModelDelegate
    ) -> [WisetagViewModel.ButtonViewModel] {
        guard case let .eligible(discoverability) = status,
              case let .discoverable(urlString, _) = discoverability else {
            return []
        }
        return [
            WisetagViewModel.ButtonViewModel(
                icon: Icons.shareIos.image,
                title: L10n.Wisetag.ShareButton.ShareLink.title,
                action: { [weak delegate] in
                    delegate?.shareLinkTapped(urlString)
                }
            ),
            WisetagViewModel.ButtonViewModel(
                icon: Icons.download.image,
                title: L10n.Wisetag.ShareButton.Download.title,
                action: { [weak delegate] in
                    delegate?.downloadTapped()
                }
            ),
            WisetagViewModel.ButtonViewModel(
                icon: Icons.scanQrCode.image,
                title: L10n.Wisetag.ScanButton.ScanLink.title,
                action: { [weak delegate] in
                    delegate?.scanQRcodeTapped()
                }
            ),
        ]
    }

    func makeFooterAction(
        profile: Profile,
        status: ShareableLinkStatus,
        delegate: WisetagViewModelDelegate
    ) -> Action? {
        guard case let .eligible(discoverability) = status,
              case .notDiscoverable = discoverability,
              profile.has(privilege: ProfileIdentifierDiscoverabilityPrivilege.manage) else {
            return nil
        }
        return Action(
            title: L10n.Wisetag.FooterButton.title,
            handler: { [weak delegate] in
                delegate?.footerButtonTapped()
            }
        )
    }

    func makeNavigationBarButtonViewModels(
        status: ShareableLinkStatus,
        delegate: WisetagViewModelDelegate
    ) -> [WisetagViewModel.ButtonViewModel] {
        guard case .eligible = status else {
            return []
        }
        let info = WisetagViewModel.ButtonViewModel(
            icon: Icons.infoCircle.image,
            title: "",
            action: { [weak delegate] in
                delegate?.showWisetagLearnMore()
            }
        )
        let discoverability = WisetagViewModel.ButtonViewModel(
            icon: Icons.slider.image,
            title: "",
            action: { [weak delegate] in
                delegate?.showDiscoverabilityBottomSheet()
            }
        )
        return [info, discoverability]
    }
}
