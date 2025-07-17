import Combine
import ContactsKit
import ContactsKitTestingSupport
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TransferResources
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport

final class WisetagScannedProfileMapperTests: TWTestCase {
    func test_make_findingUserStatus_thenReturnCorrectViewModel() {
        let mapper = WisetagScannedProfileViewModelMapperImpl()

        let viewModel = mapper.make(
            state: WisetagScannedProfileLoadingState.findingUser, nickname: "123",
            delegate: WisetagScannedProfileModelDelegateMock()
        )

        let expectedViewModel = makeExpectedViewModelForFindingUser()
        expectNoDifference(viewModel, expectedViewModel)
    }

    func test_make_userFoundStatus_thenReturnCorrectViewModel() {
        let mapper = WisetagScannedProfileViewModelMapperImpl()

        let model = Just(AvatarModel.initials(Initials(value: "CB"))).eraseToAnyPublisher()
        let publisher = AvatarPublisher.initials(avatarPublisher: model, gradientPublisher: .canned)

        let contact = Contact.build(
            id: Contact.Id.contact("123"),
            title: "Connor Berry",
            subtitle: "cberry",
            isVerified: true,
            isHighlighted: false,
            labels: [],
            hasAvatar: true,
            avatarPublisher: publisher,
            lastUsedDate: nil,
            nickname: nil
        )

        let viewModel = mapper.make(
            state: WisetagScannedProfileLoadingState.userFound(scannedProfile: contact), nickname: "@123",
            delegate: WisetagScannedProfileModelDelegateMock()
        )

        let expectedViewModel = makeExpectedViewModelForUserFound()
        expectNoDifference(viewModel, expectedViewModel)
    }

    func test_make_isSelfStatus_thenReturnCorrectViewModel() {
        let model = Just(AvatarModel.initials(Initials(value: "CB"))).eraseToAnyPublisher()
        let publisher = AvatarPublisher.initials(avatarPublisher: model, gradientPublisher: .canned)

        let contact = Contact.build(
            id: Contact.Id.contact("123"),
            title: "Connor Berry",
            subtitle: "@123",
            isVerified: true,
            isHighlighted: false,
            labels: [],
            hasAvatar: true,
            avatarPublisher: publisher,
            lastUsedDate: nil,
            nickname: nil
        )

        let mapper = WisetagScannedProfileViewModelMapperImpl()

        let viewModel = mapper.make(
            state: WisetagScannedProfileLoadingState.isSelf(scannedProfile: contact), nickname: "@123",
            delegate: WisetagScannedProfileModelDelegateMock()
        )

        let expectedViewModel = makeExpectedViewModelForIsSelf()
        expectNoDifference(viewModel, expectedViewModel)
    }

    // MARK: - Helpers

    private func makeExpectedViewModelForFindingUser() -> WisetagScannedProfileViewModel {
        WisetagScannedProfileViewModel(header: nil, footer: makeFooterForFindingUserStatus())
    }

    private func makeFooterForFindingUserStatus() -> WisetagScannedProfileViewModel.FooterViewModel {
        WisetagScannedProfileViewModel.FooterViewModel(buttons: nil, isLoading: true)
    }

    private func makeExpectedViewModelForUserFound() -> WisetagScannedProfileViewModel {
        WisetagScannedProfileViewModel(header: makeHeaderForUserFoundStatus(), footer: makeFooterForUserFoundStatus())
    }

    private func makeExpectedViewModelForIsSelf() -> WisetagScannedProfileViewModel {
        WisetagScannedProfileViewModel(
            header: makeHeaderForIsSelfStatus(),
            footer: makeFooterForIsSelf()
        )
    }

    private func makeHeaderForIsSelfStatus() -> WisetagScannedProfileViewModel.HeaderViewModel {
        let alert = WisetagScannedProfileViewModel.HeaderViewModel.Alert(
            style: .neutral,
            viewModel: Neptune.InlineAlertViewModel(message: L10n.Wisetag.ScannedProfile.IsSelf.Alert.message)
        )

        return WisetagScannedProfileViewModel.HeaderViewModel(
            avatar: .canned,
            title: "Connor Berry",
            subtitle: "@123",
            alert: alert
        )
    }

    private func makeHeaderForUserFoundStatus() -> WisetagScannedProfileViewModel.HeaderViewModel {
        WisetagScannedProfileViewModel.HeaderViewModel(
            avatar: .canned,
            title: "Connor Berry",
            subtitle: "@123",
            alert: nil
        )
    }

    private func makeFooterForIsSelf() -> WisetagScannedProfileViewModel.FooterViewModel {
        WisetagScannedProfileViewModel.FooterViewModel(
            buttons: nil,
            isLoading: false
        )
    }

    private func makeFooterForUserFoundStatus() -> WisetagScannedProfileViewModel.FooterViewModel {
        let sendButton = WisetagScannedProfileViewModel.ButtonViewModel(
            icon: Icons.send.image,
            title: "Send",
            enabled: true,
            action: {}
        )

        let requestButton = WisetagScannedProfileViewModel.ButtonViewModel(
            icon: Icons.receive.image,
            title: "Request",
            enabled: true,
            action: {}
        )

        let recipientButton = WisetagScannedProfileViewModel.ButtonViewModel(
            icon: Icons.plus.image,
            title: "Add recipient",
            enabled: true,
            action: {}
        )

        let buttons = [sendButton, requestButton, recipientButton]

        return WisetagScannedProfileViewModel.FooterViewModel(
            buttons: buttons,
            isLoading: false
        )
    }
}
