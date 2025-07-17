import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport

final class WisetagViewModelMapperTests: TWTestCase {
    private let profile: Profile = {
        let info = FakePersonalProfileInfo()
        info.addPrivilege(ProfileIdentifierDiscoverabilityPrivilege.manage)
        info.firstName = "Harry"
        info.lastName = "Potter"
        return info.asProfile()
    }()

    func test_make_shareableLinkStatusIsIneligible_thenReturnCorrectViewModel() {
        let mapper = WisetagViewModelMapperImpl()

        let viewModel = mapper.make(
            profile: profile,
            status: .ineligible,
            qrCodeImage: nil,
            delegate: WisetagViewModelDelegateMock()
        )

        let expected = makeExpectedViewModelForIneligibleStatus()
        expectNoDifference(viewModel.header, expected.header)
        expectNoDifference(viewModel.navigationBarButtons, expected.navigationBarButtons)
        expectNoDifference(viewModel.shareButtons, expected.shareButtons)
        expectNoDifference(viewModel.footerAction, expected.footerAction)
    }

    func test_make_shareableLinkStatusIsEligible_andDiscoverable_andShouldShowScanNavigationBarButtonIsTrue_thenReturnCorrectViewModel() {
        let mapper = WisetagViewModelMapperImpl()

        let viewModel = mapper.make(
            profile: profile,
            status: .eligible(
                .discoverable(
                    urlString: "@aleksandraa",
                    nickname: "@aleksandraa"
                )
            ),
            qrCodeImage: nil,
            delegate: WisetagViewModelDelegateMock()
        )

        let expected = makeExpectedViewModelForEligibleStatus(
            isDiscoverable: true,
            qrCode: makeEnabledQRCode(),
            shareButtons: makeShareButtons(),
            footerAction: nil,
            navigationBarButtons: makeNavigationBarButtons()
        )
        expectNoDifference(viewModel.header, expected.header)
        expectNoDifference(viewModel.navigationBarButtons, expected.navigationBarButtons)
        expectNoDifference(viewModel.shareButtons, expected.shareButtons)
        expectNoDifference(viewModel.footerAction, expected.footerAction)
    }

    func test_make_shareableLinkStatusIsEligible_andDiscoverable_andHasQRcodeImageData_thenReturnCorrectViewModel() throws {
        let mapper = WisetagViewModelMapperImpl()

        let qrCode = try XCTUnwrap(UIImage.qrCode(from: LoremIpsum.long))
        let viewModel = mapper.make(
            profile: profile,
            status: .eligible(
                .discoverable(
                    urlString: "@aleksandraa",
                    nickname: "@aleksandraa"
                )
            ),
            qrCodeImage: qrCode,
            delegate: WisetagViewModelDelegateMock()
        )

        let expected = makeExpectedViewModelForEligibleStatus(
            isDiscoverable: true,
            qrCode: makeEnabledQRCode(image: qrCode),
            shareButtons: makeShareButtons(),
            footerAction: nil,
            navigationBarButtons: makeNavigationBarButtons()
        )
        expectNoDifference(viewModel.header, expected.header)
        expectNoDifference(viewModel.navigationBarButtons, expected.navigationBarButtons)
        expectNoDifference(viewModel.shareButtons, expected.shareButtons)
        expectNoDifference(viewModel.footerAction, expected.footerAction)
    }

    func test_make_shareableLinkStatusIsEligible_andNotDiscoverable_andShouldShowNavigationBarButtonsIsTrue_thenReturnCorrectViewModel() {
        let mapper = WisetagViewModelMapperImpl()

        let viewModel = mapper.make(
            profile: profile,
            status: .eligible(
                .notDiscoverable
            ),
            qrCodeImage: nil,
            delegate: WisetagViewModelDelegateMock()
        )

        let expected = makeExpectedViewModelForEligibleStatus(
            isDiscoverable: false,
            qrCode: makeDisabledQRCode(),
            shareButtons: [],
            footerAction: makeFooterAction(),
            navigationBarButtons: makeNavigationBarButtons()
        )
        expectNoDifference(viewModel.header, expected.header)
        expectNoDifference(viewModel.navigationBarButtons, expected.navigationBarButtons)
        expectNoDifference(viewModel.shareButtons, expected.shareButtons)
        expectNoDifference(viewModel.footerAction, expected.footerAction)
    }

    // MARK: - Helpers

    private func makeEnabledQRCode(image: UIImage? = nil) -> WisetagQRCodeViewModel {
        let qrCode = image ?? UIImage.qrCode(from: "LoremIpsum.short")
        return WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeEnabled(
            qrCode: qrCode,
            enabledText: "@aleksandraa",
            enabledTextOnTap: "Copied",
            onTap: {}
        ))
    }

    private func makeDisabledQRCode() -> WisetagQRCodeViewModel {
        let placeholderQRCode = UIImage.qrCode(from: "https://wise.com/wisetag")
        return WisetagQRCodeViewModel(state: WisetagQRCodeViewModel.QRCodeState.qrCodeDisabled(
            placeholderQRCode: placeholderQRCode,
            disabledText: "Wisetag inactive",
            onTap: {}
        ))
    }

    private func makeShareButtons() -> [WisetagViewModel.ButtonViewModel] {
        [
            WisetagViewModel.ButtonViewModel(
                icon: Icons.shareIos.image,
                title: "Share",
                action: {}
            ),
            WisetagViewModel.ButtonViewModel(
                icon: Icons.download.image,
                title: "Download",
                action: {}
            ),
            WisetagViewModel.ButtonViewModel(
                icon: Icons.scanQrCode.image,
                title: "Scan",
                action: {}
            ),
        ]
    }

    private func makeFooterAction() -> Action {
        Action(
            title: "Get your Wisetag",
            handler: {}
        )
    }

    private func makeNavigationBarButtons() -> [WisetagViewModel.ButtonViewModel] {
        let info = WisetagViewModel.ButtonViewModel(
            icon: Icons.infoCircle.image,
            title: "",
            action: {}
        )
        let discoverability = WisetagViewModel.ButtonViewModel(
            icon: Icons.slider.image,
            title: "",
            action: {}
        )

        return [
            info, discoverability,
        ]
    }

    private func makeScanQRCoreBarButton() -> WisetagViewModel.ButtonViewModel {
        WisetagViewModel.ButtonViewModel(
            icon: Icons.scanQrCode.image,
            title: "Scan QR code",
            action: {}
        )
    }

    private func makeExpectedViewModelForIneligibleStatus() -> WisetagViewModel {
        WisetagViewModel(
            header: WisetagHeaderViewModel(
                avatar: AvatarViewModel.initials(Initials(name: "Harry Potter")),
                title: "Harry Potter",
                linkType: .inactive(inactiveLink: "Turn on your Wisetag to receive payments")
            ),
            qrCode: makeDisabledQRCode(),
            shareButtons: [],
            footerAction: nil,
            navigationBarButtons: []
        )
    }

    private func makeExpectedViewModelForEligibleStatus(
        isDiscoverable: Bool,
        qrCode: WisetagQRCodeViewModel,
        shareButtons: [WisetagViewModel.ButtonViewModel],
        footerAction: Action?,
        navigationBarButtons: [WisetagViewModel.ButtonViewModel]
    ) -> WisetagViewModel {
        if isDiscoverable {
            WisetagViewModel(
                header: WisetagHeaderViewModel(
                    avatar: AvatarViewModel.initials(Initials(name: "Harry Potter")),
                    title: "Harry Potter",
                    linkType: .active(link: "wise.com/pay/aleksandraa", touchHandler: {})
                ),
                qrCode: qrCode,
                shareButtons: shareButtons,
                footerAction: footerAction,
                navigationBarButtons: navigationBarButtons
            )
        } else {
            WisetagViewModel(
                header: WisetagHeaderViewModel(
                    avatar: AvatarViewModel.initials(Initials(name: "Harry Potter")),
                    title: "Harry Potter",
                    linkType: .inactive(inactiveLink: "Turn on your Wisetag to receive payments")
                ),
                qrCode: qrCode,
                shareButtons: shareButtons,
                footerAction: footerAction,
                navigationBarButtons: navigationBarButtons
            )
        }
    }
}
