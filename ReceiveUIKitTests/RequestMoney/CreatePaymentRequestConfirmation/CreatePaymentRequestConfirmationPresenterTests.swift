import AnalyticsKitTestingSupport
import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import UserKit
import UserKitTestingSupport

final class CreatePaymentRequestConfirmationPresenterTests: TWTestCase {
    private let profileName = "Christie's Cats"
    private let message = "fake message"
    private let productDescription = "fake product description"
    private let link = "https://wise.com/pay/r/asdfghuytre"
    private let personalProfile = FakePersonalProfileInfo().asProfile()
    private lazy var businessProfile: Profile = {
        let businessInfo = FakeBusinessProfileInfo()
        businessInfo.name = profileName
        return businessInfo.asProfile()
    }()

    private var paymentRequest: PaymentRequestV2!

    private var presenter: CreatePaymentRequestConfirmationPresenterImpl!
    private var router: CreatePaymentRequestConfirmationRouterMock!
    private var view: CreatePaymentRequestConfirmationViewMock!
    private var mockPasteboard: MockPasteboard!
    private var dateFormatter: WiseDateFormatterProtocolMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var flowFinishedResult: CreatePaymentRequestFlowResult = .aborted

    override func setUp() {
        super.setUp()
        router = CreatePaymentRequestConfirmationRouterMock()
        view = CreatePaymentRequestConfirmationViewMock()
        mockPasteboard = MockPasteboard()
        dateFormatter = WiseDateFormatterProtocolMock()
        dateFormatter.dynamicYearStringReturnValue = LoremIpsum.short
        analyticsTracker = StubAnalyticsTracker()
        paymentRequest = PaymentRequestV2.build(
            message: message,
            status: .draft,
            link: link
        )
        presenter = makePresenter(profile: businessProfile)
    }

    override func tearDown() {
        presenter = nil
        router = nil
        view = nil
        mockPasteboard = nil
        dateFormatter = nil
        analyticsTracker = nil
        super.tearDown()
    }

    func test_start_ForPersonalProfile() throws {
        paymentRequest = PaymentRequestV2.build(
            message: message,
            status: .draft,
            link: link
        )

        presenter = makePresenter(profile: personalProfile)

        presenter.start(with: view)

        let expected = makeExpectedViewModelForPersonal()
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(viewModel, expected)
    }

    func test_start_ForBusinessProfile() throws {
        paymentRequest = PaymentRequestV2.build(
            message: message,
            status: .draft,
            link: link
        )

        presenter = makePresenter(profile: businessProfile)

        presenter.start(with: view)

        let expected = makeExpectedViewModelForBusiness()
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        expectNoDifference(viewModel, expected)
    }

    func test_copyTapped() throws {
        presenter.start(with: view)

        view.configureReceivedInvocations.first?.shareButtons[1].action()

        XCTAssertEqual(mockPasteboard.clipboard, [link])
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share - Share Option Selected")
        let properties = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked)
        XCTAssertEqual(properties["Vendor"] as? String, "copied")
    }

    func test_qrCodeTapped() throws {
        presenter.start(with: view)

        view.configureReceivedViewModel?.shareButtons[2].action()

        XCTAssertEqual(router.showQRCodeCallsCount, 1)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share - Share Option Selected")
        let properties = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked)
        XCTAssertEqual(properties["Vendor"] as? String, "qr-code")
    }

    func test_shareTapped_givenBusinessProfileAndNoDescription_thenCopyCorrectMessage() throws {
        presenter.start(with: view)

        view.configureReceivedInvocations.first?.shareButtons[0].action()

        let expectedMessage = [
            "Hello,\nWe’re ready for you to make your payment.\nThanks,",
            profileName,
            "Pay securely with our payment provider, Wise:",
            link,
        ].joined(separator: "\n")

        XCTAssertTrue(view.showShareSheetCalled)
        XCTAssertEqual(view.showShareSheetReceivedText, expectedMessage)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share - Share Option Selected")
        let properties = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked)
        XCTAssertEqual(properties["Vendor"] as? String, "share-sheet")
    }

    func test_shareTapped_givenBusinessProfileAndDescription_thenCopyCorrectMessage() {
        paymentRequest = PaymentRequestV2.build(
            message: message,
            description: productDescription,
            status: .published,
            link: link,
            expirationAt: Date.distantPast
        )
        presenter = makePresenter(profile: businessProfile)

        presenter.start(with: view)

        view.configureReceivedInvocations.first?.shareButtons[0].action()

        let expectedMessage = [
            "Hello,\nWe’re ready for you to make your payment of 0  for fake product description.\nThanks,",
            profileName,
            "Pay securely with our payment provider, Wise:",
            link,
        ].joined(separator: "\n")

        XCTAssertTrue(view.showShareSheetCalled)
        XCTAssertEqual(view.showShareSheetReceivedText, expectedMessage)
    }

    func test_shareTapped_givenPersonalProfile_thenCopyCorrectMessage() {
        paymentRequest = PaymentRequestV2.build(
            status: .published,
            link: link,
            expirationAt: Date.distantPast
        )
        presenter = makePresenter(profile: personalProfile)

        presenter.start(with: view)

        view.configureReceivedInvocations.first?.shareButtons[0].action()

        let expectedMessage = [
            "Use this link to pay me 0  with Wise:",
            link,
        ].joined(separator: "\n")

        XCTAssertTrue(view.showShareSheetCalled)
        XCTAssertEqual(view.showShareSheetReceivedText, expectedMessage)
    }

    func test_showPrivacyNotice_thenShowPrivacy() throws {
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.privacyNotice.action?()

        XCTAssertTrue(view.showPrivacyNoticeCalled)
    }

    func test_showPrivacyNoticeContent_forPersonalProfile_withAvatar() throws {
        paymentRequest = PaymentRequestV2.build(
            status: .published,
            link: link,
            expirationAt: .distantPast
        )
        let personalInfo = FakePersonalProfileInfo()
        personalInfo.avatar = .build(downloadedImage: UIImage())
        let personalProfile = Profile.personal(personalInfo)
        presenter = makePresenter(profile: personalProfile)
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.privacyNotice.action?()

        XCTAssertEqual(view.showPrivacyNoticeCallsCount, 1)
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.title,
            "The details you are sharing"
        )
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.info,
            "Your name and account details will be visible to anyone you share this link with. Check our [privacy policy]() to learn more."
        )
    }

    func test_showPrivacyNoticeContent_forPersonalProfile_withoutAvatar() throws {
        paymentRequest = PaymentRequestV2.build(
            status: .published,
            link: link,
            expirationAt: .distantPast
        )
        presenter = makePresenter(profile: personalProfile)
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.privacyNotice.action?()

        XCTAssertEqual(view.showPrivacyNoticeCallsCount, 1)
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.title,
            "The details you are sharing"
        )
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.info,
            "Your name, photo and account details will be visible to anyone you share this link with. Check our [privacy policy]() to learn more."
        )
    }

    func test_showPrivacyNoticeContent_forBusinessProfile_withAccountDetailsAndAvatar() throws {
        let businessInfo = FakeBusinessProfileInfo()
        businessInfo.avatar = .build(downloadedImage: UIImage())
        let businessProfile = Profile.business(businessInfo)
        paymentRequest = PaymentRequestV2.build(
            status: .published,
            link: link,
            expirationAt: .distantPast,
            selectedPaymentMethods: [.bankTransfer]
        )
        presenter = makePresenter(profile: businessProfile)
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.privacyNotice.action?()

        XCTAssertEqual(view.showPrivacyNoticeCallsCount, 1)
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.title,
            "The details you are sharing"
        )
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.info,
            "Your business name, account photo, and account details will be visible to anyone you share this link with. Check our [privacy policy]() to learn more."
        )
    }

    func test_showPrivacyNoticeContent_forBusinessProfile_withAccountDetailsButNoAvatar() throws {
        paymentRequest = PaymentRequestV2.build(
            status: .published,
            link: link,
            expirationAt: .distantPast,
            selectedPaymentMethods: [.bankTransfer]
        )
        presenter = makePresenter(profile: businessProfile)
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.privacyNotice.action?()

        XCTAssertEqual(view.showPrivacyNoticeCallsCount, 1)
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.title,
            "The details you are sharing"
        )
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.info,
            "Your business name and account details will be visible to anyone you share this link with. Check our [privacy policy]() to learn more."
        )
    }

    func test_showPrivacyNoticeContent_forBusinessProfile_withoutAccountDetailsButHasAvatar() throws {
        paymentRequest = PaymentRequestV2.build(
            status: .published,
            link: link,
            expirationAt: .distantPast
        )
        let businessInfo = FakeBusinessProfileInfo()
        businessInfo.avatar = .build(downloadedImage: UIImage())
        let businessProfile = Profile.business(businessInfo)
        presenter = makePresenter(profile: businessProfile)
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.privacyNotice.action?()

        XCTAssertEqual(view.showPrivacyNoticeCallsCount, 1)
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.title,
            "The details you are sharing"
        )
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.info,
            "Your business name and account photo will be visible to anyone you share this link with. Check our [privacy policy]() to learn more."
        )
    }

    func test_showPrivacyNoticeContent_forBusinessProfile_withoutAccountDetailsAndAvatar() throws {
        presenter.start(with: view)

        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        viewModel.privacyNotice.action?()

        XCTAssertEqual(view.showPrivacyNoticeCallsCount, 1)
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.title,
            "The details you are sharing"
        )
        XCTAssertEqual(
            view.showPrivacyNoticeReceivedViewModel?.info,
            "Your business name will be visible to anyone you share this link with. Check our [privacy policy]() to learn more."
        )
    }

    func test_dismiss() {
        presenter.dismiss()

        let result = CreatePaymentRequestFlowResult.success(
            paymentRequestId: paymentRequest.id,
            context: .completed
        )
        XCTAssertEqual(flowFinishedResult, result)
    }

    func test_doneButtonTapped() throws {
        presenter.start(with: view)
        presenter.doneTapped()

        let result = CreatePaymentRequestFlowResult.success(
            paymentRequestId: paymentRequest.id,
            context: .linkCreation
        )
        XCTAssertEqual(flowFinishedResult, result)
    }

    func test_privacyPolicyTapped() {
        presenter.privacyPolicyTapped()
        XCTAssertEqual(router.showPrivacyPolicyCallsCount, 1)
    }

    // MARK: - Helpers

    private func makePresenter(profile: Profile) -> CreatePaymentRequestConfirmationPresenterImpl {
        CreatePaymentRequestConfirmationPresenterImpl(
            profile: profile,
            paymentRequest: paymentRequest,
            router: router,
            analyticsTracker: analyticsTracker,
            pasteboard: mockPasteboard,
            dateFormatter: dateFormatter,
            onSuccess: { self.flowFinishedResult = $0 }
        )
    }

    private func makeExpectedViewModelForPersonal() -> CreatePaymentRequestConfirmationViewModel {
        CreatePaymentRequestConfirmationViewModel(
            asset: .scene3D(.checkMark, renderAutomatically: true),
            title: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: "Share your request",
                style: LabelStyle.display.centered,
                action: nil
            ),
            info: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: nil,
                style: LabelStyle.largeBody.centered,
                action: nil
            ),
            privacyNotice: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: "By sharing your link, you accept that some of your details will be shared, too. <link>Learn more</link>",
                style: LabelStyle.defaultBody.centered,
                action: {}
            ),
            shareButtons: [
                CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                    icon: Icons.shareIos.image,
                    title: "Share",
                    action: {}
                ),
                CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                    icon: Icons.link.image,
                    title: "Copy",
                    action: {}
                ),
                CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                    icon: Icons.qrCode.image,
                    title: "QR code",
                    action: {}
                ),
            ],
            shouldShowExtendedFooter: false
        )
    }

    private func makeExpectedViewModelForBusiness() -> CreatePaymentRequestConfirmationViewModel {
        CreatePaymentRequestConfirmationViewModel(
            asset: .scene3D(.checkMark, renderAutomatically: true),
            title: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: "Share your request",
                style: LabelStyle.display.centered,
                action: nil
            ),
            info: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: link,
                style: LabelStyle.largeBody.centered,
                action: nil
            ),
            privacyNotice: CreatePaymentRequestConfirmationViewModel.LabelViewModel(
                text: "By sharing your link, you accept that some of your details will be shared, too. <link>Learn more</link>",
                style: LabelStyle.defaultBody.centered,
                action: {}
            ),
            shareButtons: [
                CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                    icon: Icons.shareIos.image,
                    title: "Share",
                    action: {}
                ),
                CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                    icon: Icons.link.image,
                    title: "Copy",
                    action: {}
                ),
                CreatePaymentRequestConfirmationViewModel.ButtonViewModel(
                    icon: Icons.qrCode.image,
                    title: "QR code",
                    action: {}
                ),
            ],
            shouldShowExtendedFooter: true
        )
    }
}
