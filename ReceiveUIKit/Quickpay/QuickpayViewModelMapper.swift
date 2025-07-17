import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UIKit
import UserKit

// sourcery: AutoMockable
protocol QuickpayViewModelDelegate: AnyObject {
    func showManageQuickpay()
    func shareTapped()
    func qrCodeTapped()
    func footerButtonTapped()
    func cardTapped(articleId: String)
    func linkTapped()
    func personaliseTapped()
    func giveFeedbackTapped()
}

// sourcery: AutoMockable
protocol QuickpayViewModelMapper {
    func make(
        status: ShareableLinkStatus.Discoverability,
        profile: Profile,
        qrCodeImage: UIImage?,
        isCardsEnabled: Bool,
        nudge: NudgeViewModel?,
        delegate: QuickpayViewModelDelegate
    ) -> QuickpayViewModel
}

struct QuickpayViewModelMapperImpl: QuickpayViewModelMapper {
    private enum Constants {
        static let wiseDomain = "wise.com/pay/business/"
        static let getPaidByCardArticle = "2ns36RddtM1kAb5vbWxGMx"
        static let getPaidInPersonArticle = "hXXUwbLoLDxtfU3w5c8Bu"
        static let getPaidByInvoiceArticle = "37PkGqZg1f4xElON1MqOuQ"
        static let getPaidByIntegrationArticle = "5qGvWQuTiX0RSSvxWvKcBC"
    }

    func make(
        status: ShareableLinkStatus.Discoverability,
        profile: Profile,
        qrCodeImage: UIImage?,
        isCardsEnabled: Bool,
        nudge: NudgeViewModel?,
        delegate: QuickpayViewModelDelegate
    ) -> QuickpayViewModel {
        let discoverability = QuickpayViewModel.ButtonViewModel(
            icon: Icons.slider.image,
            title: "",
            action: { [weak delegate] in
                delegate?.showManageQuickpay()
            }
        )

        let carouselCard: QuickpayCardViewModel? = isCardsEnabled ?
            QuickpayCardViewModel(
                id: 4,
                image: Neptune.Illustrations.digitalCard2.image,
                title: L10n.Quickpay.Carousel.Item4.title,
                subtitle: L10n.Quickpay.Carousel.Item4.subtitle,
                articleId: Constants.getPaidByCardArticle
            ) : nil

        let cardItems: [QuickpayCardViewModel] = [
            QuickpayCardViewModel(
                id: 1,
                image: ReceiveKitImages.invoiceImage,
                title: L10n.Quickpay.Carousel.Item1.title,
                subtitle: L10n.Quickpay.Carousel.Item1.subtitle,
                articleId: Constants.getPaidByInvoiceArticle
            ),
            QuickpayCardViewModel(
                id: 2,
                image: ReceiveKitImages.pwwImage,
                title: L10n.Quickpay.Carousel.Item2.title,
                subtitle: L10n.Quickpay.Carousel.Item2.subtitle,
                articleId: Constants.getPaidByIntegrationArticle
            ),
            carouselCard,
            QuickpayCardViewModel(
                id: 3,
                image: Neptune.Illustrations.shoppingBag.image,
                title: L10n.Quickpay.Carousel.Item3.title,
                subtitle: L10n.Quickpay.Carousel.Item3.subtitle,
                articleId: Constants.getPaidInPersonArticle
            ),
        ].compactMap { $0 }

        let linkType = makeLink(status: status, delegate: delegate)

        let fallbackAvatarViewModel = AvatarViewModel.initials(
            Initials(value: ProfileInitialsDisplayName(profile: profile).name)
        )
        let avatarViewModel = profile.avatar.downloadedImage.map { AvatarViewModel.image($0) }

        return QuickpayViewModel(
            avatar: avatarViewModel ?? fallbackAvatarViewModel,
            title: ProfileLocaleDisplayName(profile: profile, style: .full).name,
            subtitle: L10n.Quickpay.MainPage.subtitle2,
            linkType: linkType,
            footerAction: configureFooterAction(profile, status, delegate),
            nudge: nudge,
            qrCode: configureQRCode(status: status, qrCodeImage: qrCodeImage, delegate: delegate),
            navigationBarButtons: [discoverability],
            circularButtons: makeCircularButtons(
                status: status,
                delegate: delegate
            ),
            cardItems: cardItems,
            onCardTap: { [weak delegate] item in
                delegate?.cardTapped(articleId: item.articleId)
            }
        )
    }

    private func makeCircularButtons(
        status: ShareableLinkStatus.Discoverability,
        delegate: QuickpayViewModelDelegate
    ) -> [QuickpayViewModel.ButtonViewModel] {
        guard case .discoverable = status else {
            return []
        }

        return [
            QuickpayViewModel.ButtonViewModel(
                icon: Icons.shareIos.image,
                title: L10n.Quickpay.MainPage.ShareButton.title,
                action: { [weak delegate] in
                    delegate?.shareTapped()
                }
            ),
            QuickpayViewModel.ButtonViewModel(
                icon: Icons.edit.image,
                title: L10n.Quickpay.MainPage.PersonaliseButton.title,
                action: { [weak delegate] in
                    delegate?.personaliseTapped()
                }
            ),
            QuickpayViewModel.ButtonViewModel(
                icon: Icons.speechBubbleMessage.image,
                title: L10n.Quickpay.MainPage.GiveFeedback.title,
                action: { [weak delegate] in
                    delegate?.giveFeedbackTapped()
                }
            ),
        ].compactMap { $0 }
    }

    private func makeLink(
        status: ShareableLinkStatus.Discoverability,
        delegate: QuickpayViewModelDelegate
    ) -> QuickpayViewModel.LinkType {
        switch status {
        case let .discoverable(_, nickname):
            let linkString = Constants.wiseDomain + String(nickname.dropFirst())
            return QuickpayViewModel.LinkType.active(link: linkString, touchHandler: { [weak delegate] in
                delegate?.linkTapped()
            })
        case .notDiscoverable:
            return QuickpayViewModel.LinkType.inactive(inactiveLink: L10n.Quickpay.MainPage.InactiveLink.title)
        }
    }

    private func configureQRCode(
        status: ShareableLinkStatus.Discoverability,
        qrCodeImage: UIImage?,
        delegate: QuickpayViewModelDelegate
    ) -> WisetagQRCodeViewModel {
        switch status {
        case .discoverable:
            return WisetagQRCodeViewModel(
                state: .qrCodeEnabled(
                    qrCode: qrCodeImage,
                    enabledText: L10n.Quickpay.QrCode.Download.title,
                    enabledTextOnTap: L10n.Quickpay.QrCode.Downloading.title,
                    onTap: { [weak delegate] in
                        delegate?.qrCodeTapped()
                    }
                )
            )
        case .notDiscoverable:
            let urlString = Branding.current.url.appendingPathComponent("wisetag").absoluteString
            let placeholderImage = qrCodeImage ?? UIImage.qrCode(from: urlString)
            return WisetagQRCodeViewModel(
                state: .qrCodeDisabled(
                    placeholderQRCode: placeholderImage,
                    disabledText: L10n.Quickpay.QrCode.TurnedOff.title,
                    onTap: { [weak delegate] in
                        delegate?.qrCodeTapped()
                    }
                )
            )
        }
    }

    private func configureFooterAction(
        _ profile: Profile,
        _ status: ShareableLinkStatus.Discoverability,
        _ delegate: QuickpayViewModelDelegate
    ) -> Action? {
        switch status {
        case .discoverable:
            nil
        case .notDiscoverable:
            profile.has(privilege: ProfileIdentifierDiscoverabilityPrivilege.manage)
                ? Action(
                    title: L10n.Quickpay.QrCode.TurnOn.title,
                    handler: { [weak delegate] in
                        delegate?.footerButtonTapped()
                    }
                )
                : nil
        }
    }
}
