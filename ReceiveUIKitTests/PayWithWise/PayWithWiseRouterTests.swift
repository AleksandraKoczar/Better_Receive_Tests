import Foundation
@testable import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUI
import TWUITestingSupport
import UserKitTestingSupport
import WiseCore

final class PayWithWiseRouterTests: TWTestCase {
    private let profile = FakePersonalProfileInfo().asProfile()
    private var router: PayWithWiseRouterImpl!
    private var host: MockNavigationController!
    private var urlOpener: UrlOpenerMock!
    private var flowNavigationDelegate: PayWithWiseFlowNavigationDelegateMock!
    private var profileSwitcherFlowFactory: ProfileSwitcherFlowFactoryMock!
    private var topUpBalanceFlowFactory: TopUpBalanceFlowFactoryMock!
    private var contactsDiscoverabilitySettingsViewControllerFactory: ContactsDiscoverabilitySettingsViewControllerFactoryProtocolMock!
    private var userProvider: StubUserProvider!
    private var webViewControllerFactory: WebViewControllerFactoryMock.Type!

    override func setUp() {
        super.setUp()

        host = MockNavigationController()
        flowNavigationDelegate = PayWithWiseFlowNavigationDelegateMock()
        profileSwitcherFlowFactory = ProfileSwitcherFlowFactoryMock()
        topUpBalanceFlowFactory = TopUpBalanceFlowFactoryMock()
        urlOpener = UrlOpenerMock()
        userProvider = StubUserProvider()
        contactsDiscoverabilitySettingsViewControllerFactory = ContactsDiscoverabilitySettingsViewControllerFactoryProtocolMock()
        webViewControllerFactory = WebViewControllerFactoryMock.self
        router = PayWithWiseRouterImpl(
            flowNavigationDelegate: flowNavigationDelegate,
            host: host,
            profileSwitcherFlowFactory: profileSwitcherFlowFactory,
            appReviewNudgePresenter: AppReviewNudgePresenterMock(),
            topUpBalanceFlowFactory: topUpBalanceFlowFactory,
            contactsDiscoverabilitySettingsViewControllerFactory: contactsDiscoverabilitySettingsViewControllerFactory,
            urlOpener: urlOpener,
            webViewControllerFactory: webViewControllerFactory,
            userProvider: userProvider
        )
    }

    override func tearDown() {
        router = nil
        host = nil
        flowNavigationDelegate = nil
        profileSwitcherFlowFactory = nil
        topUpBalanceFlowFactory = nil
        urlOpener = nil
        userProvider = nil
        contactsDiscoverabilitySettingsViewControllerFactory = nil

        super.tearDown()
    }
}

// MARK: - Success screens

extension PayWithWiseRouterTests {
    func testShowingSuccess_WhenShowCalled_ThenSuccessScreenShowedWithExpectedFields() throws {
        let message = PromptConfiguration.MessageConfiguration.textWithLink(
            text: LoremIpsum.medium,
            linkText: LoremIpsum.short,
            action: {}
        )
        let amount = "20 GBP"
        let viewModel = PayWithWiseSuccessPromptViewModel(
            asset: .scene3D(.confetti),
            title: amount,
            message: message,
            primaryButtonTitle: "Done",
            completion: {}
        )

        router.showSuccess(viewModel: viewModel)
        let vc = try XCTUnwrap(host.lastPresentedViewController as? PromptViewController)
        vc.loadViewIfNeeded()

        guard case let .assetAndOneCta(title, messageConfig, primaryCta, _, _) = vc.configuration else {
            XCTAssert(false, "Config mismatch")
            return
        }

        XCTAssertEqual(title, amount)
        guard case let .textWithLink(text, linkText) = messageConfig else {
            XCTAssert(false, "Message config mismatch")
            return
        }
        XCTAssertEqual(text, LoremIpsum.medium)
        XCTAssertEqual(linkText, LoremIpsum.short)
        XCTAssertEqual(
            primaryCta?.title,
            L10n.PayWithWise.Payment.PaymentSuccess.Button.title
        )
    }

    func testShowinRejectSuccess_WhenShowCalled_ThenSuccessScreenShowedWithExpectedFields() throws {
        router.showRejectSuccess(profileId: profile.id)
        let vc = try XCTUnwrap((host.lastPresentedViewController as? UINavigationController)?.viewControllers.first as? PromptViewController)
        vc.loadViewIfNeeded()

        guard case let .assetAndTwoCtas(title, message, primaryCta, secondaryCta, _) = vc.configuration else {
            XCTAssert(false, "Config mismatch")
            return
        }

        XCTAssertEqual(
            title,
            L10n.PayWithWise.Payment.RequestRejected.Success.title
        )
        XCTAssertEqual(
            message?.markupText,
            L10n.PayWithWise.Payment.RequestRejected.Success.description
        )
        XCTAssertEqual(
            primaryCta.title,
            L10n.PayWithWise.Payment.PaymentSuccess.Button.title
        )
        XCTAssertEqual(
            secondaryCta.title,
            L10n.PayWithWise.Payment.RequestRejected.Success.ChangeSettingButton.title
        )
    }
}

// MARK: - Profile switcher

extension PayWithWiseRouterTests {
    func testShowingProfileSwitcher_WhenShowCalled_ThenFlowCreated() {
        let flow = MockFlow<ProfileSwitcherFlowResult>()
        profileSwitcherFlowFactory.makeFlowReturnValue = flow

        XCTAssertFalse(flow.startCalled)
        XCTAssertFalse(profileSwitcherFlowFactory.makeFlowCalled)
        router.showProfileSwitcher {}
        XCTAssertTrue(profileSwitcherFlowFactory.makeFlowCalled)
        XCTAssertTrue(flow.startCalled)
    }
}

// MARK: - Balance selector

extension PayWithWiseRouterTests {
    func testShowingBalanceSelector_WhenShowCalled_ThenVCPresented() {
        XCTAssertNil(host.lastPresentedViewController)
        router.showBalanceSelector(
            viewModel: PayWithWiseBalanceSelectorViewModel.canned
        )
        XCTAssertNotNil(host.lastPresentedViewController)
    }
}

// MARK: - Alternative payment methods

extension PayWithWiseRouterTests {
    func test_paymentMethodIsOpenBanking_ThenOpenURLAndDismiss() {
        urlOpener.canOpenURLReturnValue = true

        router.showPaymentMethod(
            profileId: profile.id,
            paymentMethod: PayerAcquiringPaymentMethod.build(type: .pisp),
            paymentKey: "key"
        )

        XCTAssertEqual(urlOpener.openCallsCount, 1)
        XCTAssertEqual(host.dismissInvokedCount, 1)
    }

    func testShowingAlternativePaymentMethods_GivenSinglePaymentMethod_ThenNavigatedToURL() {
        let paymentKey = "key"
        let accountDetailsValue = "ACCOUNT_DETAILS"

        let expectedProfileId = ProfileId(1)
        let expectedUserId = UserId(10)
        userProvider.activeProfile = FakeBusinessProfileInfo()
            .with(profileId: expectedProfileId)
            .asProfile()
        userProvider.user = StubUserInfo(userId: expectedUserId)

        let webViewController = WebContentViewController(url: URL(string: "https://abc.com")!)
        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = webViewController

        router.showPaymentMethod(
            profileId: profile.id,
            paymentMethod: PayerAcquiringPaymentMethod.build(
                type: .bankTransfer,
                value: accountDetailsValue
            ),
            paymentKey: paymentKey
        )

        let expectedUrl = URL(string: "https://wise.com/pay/r/\(paymentKey)?payerMode=\(accountDetailsValue)")

        let receivedArguments = webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReceivedArguments
        XCTAssertEqual(receivedArguments?.url, expectedUrl)
        XCTAssertEqual(receivedArguments?.userInfoForAuthentication.userId, expectedUserId)
        XCTAssertEqual(receivedArguments?.userInfoForAuthentication.profileId, expectedProfileId)
        XCTAssertTrue(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationCalled)
        XCTAssertTrue(webViewController.isDownloadSupported)
    }

    func testShowingAlternativePaymentMethods_GivenMultiplePaymentMethods_ThenViewControllerPresented() {
        router.showPaymentMethodsBottomSheet(
            paymentMethods: [
                PayerAcquiringPaymentMethod.build(
                    type: .bankTransfer,
                    value: "ACCOUNT_DETAILS"
                ),
                PayerAcquiringPaymentMethod.build(
                    type: .card,
                    value: "CARD"
                ),
            ],
            requesterName: "",
            completion: { _ in }
        )
        XCTAssertNotNil(host.lastPresentedViewController)
    }
}

// MARK: - Details

extension PayWithWiseRouterTests {
    func testShowingDetails_WhenShowDetailsCalled_ThenViewControllerPresented() {
        router.showDetails(
            viewModel: PayWithWiseRequestDetailsView.ViewModel(
                title: "",
                rows: [LegacyListItemViewModel(title: "", subtitle: "")],
                buttonConfiguration:
                (title: "", handler: {})
            )
        )

        XCTAssertNotNil(host.lastPresentedViewController)
    }
}

// MARK: - Attachment

extension PayWithWiseRouterTests {
    func testShowingAttachment_GivenAttachmentFileURL_ThenURLPreviewStarted() throws {
        let viewController = StubDocumentInteractionViewController()
        host.present(viewController, animated: false)
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(#function + ".pdf")

        try "Jane Doe"
            .data(using: .utf8)?
            .write(to: path)
        router.showAttachment(url: path, delegate: viewController)

        XCTAssertTrue(viewController.previewWillStart)
    }
}

// MARK: - Request Money

extension PayWithWiseRouterTests {
    func testShowingRequestMoney() {
        router.showRequestMoney(profile: FakePersonalProfileInfo().asProfile())

        XCTAssertEqual(host.dismissInvokedCount, 1)
        XCTAssertEqual(flowNavigationDelegate.startRequestMoneyFlowCallsCount, 1)
    }
}

// MARK: - Dismiss

extension PayWithWiseRouterTests {
    func testDismiss() {
        router.dismiss()

        XCTAssertEqual(host.dismissInvokedCount, 1)
        XCTAssertEqual(flowNavigationDelegate.dismissedReceivedAt, .singlePagePayer)
    }
}

// MARK: - Reject

extension PayWithWiseRouterTests {
    func testRejectConfirmation() {
        XCTAssertNil(host.lastPresentedViewController)
        router.showRejectConfirmation(viewModel: InfoSheetViewModel.canned)
        XCTAssertNotNil(host.lastPresentedViewController)
    }
}
