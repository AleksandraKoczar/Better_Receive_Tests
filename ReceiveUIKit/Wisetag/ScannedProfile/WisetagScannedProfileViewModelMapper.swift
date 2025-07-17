import ContactsKit
import Foundation
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UserKit

// sourcery: AutoMockable
protocol WisetagScannedProfileModelDelegate: AnyObject {
    func sendButtonTapped()
    func requestButtonTapped()
    func addRecipientButtonTapped()
}

// sourcery: AutoMockable
protocol WisetagScannedProfileViewModelMapper {
    func make(
        state: WisetagScannedProfileLoadingState,
        nickname: String,
        delegate: WisetagScannedProfileModelDelegate
    ) -> WisetagScannedProfileViewModel
}

struct WisetagScannedProfileViewModelMapperImpl: WisetagScannedProfileViewModelMapper {
    func make(
        state: WisetagScannedProfileLoadingState,
        nickname: String,
        delegate: WisetagScannedProfileModelDelegate
    ) -> WisetagScannedProfileViewModel {
        var header: WisetagScannedProfileViewModel.HeaderViewModel?
        var footer: WisetagScannedProfileViewModel.FooterViewModel

        switch state {
        case let .userFound(scannedProfile: scannedProfile):
            header = makeHeaderViewModel(contact: scannedProfile, nickname: nickname, isSelf: false)
            footer = WisetagScannedProfileViewModel.FooterViewModel(
                buttons:
                makeFooterButtonsViewModel(
                    inContacts: false,
                    recipientActive: true,
                    delegate: delegate
                ), isLoading: false
            )
        case let .recipientAdded(scannedProfile: scannedProfile, contactId: _):
            header = makeHeaderViewModel(contact: scannedProfile, nickname: nickname, isSelf: false)
            footer = WisetagScannedProfileViewModel.FooterViewModel(
                buttons:
                makeFooterButtonsViewModel(
                    inContacts: false,
                    recipientActive: false,
                    delegate: delegate
                ), isLoading: false
            )
        case .findingUser:
            footer = WisetagScannedProfileViewModel.FooterViewModel(
                buttons: nil, isLoading: true
            )
        case let .isSelf(scannedProfile):
            header = makeHeaderViewModel(
                contact: scannedProfile,
                nickname: nickname,
                isSelf: true
            )
            footer = WisetagScannedProfileViewModel.FooterViewModel(
                buttons: nil, isLoading: false
            )
        case let .inContacts(scannedProfile: scannedProfile, contactId: _):
            header = makeHeaderViewModel(contact: scannedProfile, nickname: nickname, isSelf: false)
            footer = WisetagScannedProfileViewModel.FooterViewModel(
                buttons:
                makeFooterButtonsViewModel(
                    inContacts: true,
                    recipientActive: false,
                    delegate: delegate
                ), isLoading: false
            )
        }

        return WisetagScannedProfileViewModel(
            header: header,
            footer: footer
        )
    }
}

extension WisetagScannedProfileViewModelMapperImpl {
    func makeHeaderViewModel(
        contact: Contact,
        nickname: String,
        isSelf: Bool
    ) -> WisetagScannedProfileViewModel.HeaderViewModel {
        if isSelf {
            let alert = WisetagScannedProfileViewModel.HeaderViewModel.Alert(
                style: .neutral,
                viewModel: Neptune.InlineAlertViewModel(message: L10n.Wisetag.ScannedProfile.IsSelf.Alert.message)
            )

            return WisetagScannedProfileViewModel.HeaderViewModel(
                avatar: contact.avatarPublisher.avatarPublisher
                    .map { AvatarViewModel(avatar: $0) }
                    .eraseToAnyPublisher(),
                title: contact.title,
                subtitle: nickname,
                alert: alert
            )
        } else {
            return WisetagScannedProfileViewModel.HeaderViewModel(
                avatar: contact.avatarPublisher.avatarPublisher
                    .map { AvatarViewModel(avatar: $0) }
                    .eraseToAnyPublisher(),
                title: contact.title,
                subtitle: nickname,
                alert: nil
            )
        }
    }

    func makeLoadingView(label: Bool) -> LoadingView {
        let loader = LoadingView()
        if label {
            loader.setLabel(L10n.Wisetag.ScannedProfile.findingUserTitle)
        }
        return loader
    }

    func makeFooterButtonsViewModel(
        inContacts: Bool,
        recipientActive: Bool,
        delegate: WisetagScannedProfileModelDelegate
    ) -> [WisetagScannedProfileViewModel.ButtonViewModel] {
        let sendButton = WisetagScannedProfileViewModel.ButtonViewModel(
            icon: Icons.send.image,
            title: L10n.Wisetag.ScannedProfile.sendMoneyTitle,
            enabled: true
        ) {
            [weak delegate] in
            delegate?.sendButtonTapped()
        }

        let requestButton = WisetagScannedProfileViewModel.ButtonViewModel(
            icon: Icons.receive.image,
            title: L10n.Wisetag.ScannedProfile.requestMoneyTitle,
            enabled: true
        ) {
            [weak delegate] in
            delegate?.requestButtonTapped()
        }

        let recipientButton: WisetagScannedProfileViewModel.ButtonViewModel

        if inContacts {
            return [sendButton, requestButton]
        }

        if recipientActive {
            recipientButton = WisetagScannedProfileViewModel.ButtonViewModel(
                icon: Icons.plus.image,
                title: L10n.Wisetag.ScannedProfile.addRecipientTitle,
                enabled: true
            ) {
                [weak delegate] in
                delegate?.addRecipientButtonTapped()
            }
        } else {
            recipientButton = WisetagScannedProfileViewModel.ButtonViewModel(
                icon: Icons.check.image,
                title: L10n.Wisetag.ScannedProfile.addedRecipientTitle,
                enabled: false,
                action: nil
            )
        }
        return [sendButton, requestButton, recipientButton]
    }
}
