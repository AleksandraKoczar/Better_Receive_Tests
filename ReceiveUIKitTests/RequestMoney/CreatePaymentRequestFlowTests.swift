import AnalyticsKitTestingSupport
import Combine
import ContactsKit
import DynamicFlowKitTestingSupport
import DynamicFlowTestingSupport
@testable import Neptune
import NeptuneTestingSupport
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import TWUITestingSupport
import UIKit
import UserKit
import UserKitTestingSupport

@MainActor
final class CreatePaymentRequestFlowTests: TWTestCase {
    private let profile: Profile = FakeBusinessProfileInfo().asProfile()
    private var flowResult: CreatePaymentRequestFlowResult?

    private var createPaymentRequestFlow: CreatePaymentRequestFlow!
    private var navigationController: MockNavigationController!
    private var paymentRequestUseCase: PaymentRequestUseCaseV2Mock!
    private var presenterFactory: FakeViewControllerPresenterFactory!
    private var viewControllerFactory: CreatePaymentRequestViewControllerFactoryMock!
    private var cardOnboardingFlowFactory: RequestMoneyCardOnboardingFlowFactoryMock!
    private var payWithWiseEducationFlowFactory: RequestMoneyPayWithWiseEducationFlowFactoryMock!
    private var accountDetailsCreationFlowFactory: ReceiveAccountDetailsCreationFlowFactoryMock!
    private var contactSearchViewControllerFactory: ReceiveContactSearchViewControllerFactoryMock!
    private var analyticsTracker: StubAnalyticsTracker!
    private var dynamicFlowFactory: DynamicFlowFactoryMock!
    private var inviteFlowFactory: ReceiveInviteFlowFactoryMock!
    private var findFriendsFlowFactory: FindFriendsFlowFactoryMock!
    private var paymentMethodsDynamicFlowHandler: PaymentMethodsDynamicFlowHandlerMock!
    private var webViewControllerFactory: WebViewControllerFactoryMock.Type!

    override func setUp() {
        super.setUp()
        paymentRequestUseCase = PaymentRequestUseCaseV2Mock()
        navigationController = MockNavigationController()
        presenterFactory = FakeViewControllerPresenterFactory()
        viewControllerFactory = CreatePaymentRequestViewControllerFactoryMock()
        cardOnboardingFlowFactory = RequestMoneyCardOnboardingFlowFactoryMock()
        payWithWiseEducationFlowFactory = RequestMoneyPayWithWiseEducationFlowFactoryMock()
        accountDetailsCreationFlowFactory = ReceiveAccountDetailsCreationFlowFactoryMock()
        contactSearchViewControllerFactory = ReceiveContactSearchViewControllerFactoryMock()
        findFriendsFlowFactory = FindFriendsFlowFactoryMock()
        dynamicFlowFactory = DynamicFlowFactoryMock()
        analyticsTracker = StubAnalyticsTracker()

        inviteFlowFactory = ReceiveInviteFlowFactoryMock()
        webViewControllerFactory = WebViewControllerFactoryMock.self
        paymentMethodsDynamicFlowHandler = PaymentMethodsDynamicFlowHandlerMock()
        createPaymentRequestFlow = CreatePaymentRequestFlow(
            entryPoint: .canned,
            profile: profile,
            contact: .canned,
            preSelectedBalanceCurrencyCode: .cannedGBP,
            defaultBalance: .canned,
            eligibleBalances: .canned,
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            paymentMethodsDynamicFlowHandler: paymentMethodsDynamicFlowHandler,
            webViewControllerFactory: webViewControllerFactory,
            navController: navigationController,
            analyticsTracker: analyticsTracker,
            paymentRequestUseCase: paymentRequestUseCase,
            presenterFactory: presenterFactory,
            cardOnboardingFlowFactory: cardOnboardingFlowFactory,
            payWithWiseEducationFlowFactory: payWithWiseEducationFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            findFriendsFlowFactory: findFriendsFlowFactory,
            viewControllerFactory: viewControllerFactory,
            inviteFlowFactory: inviteFlowFactory,
            dynamicFlowFactory: dynamicFlowFactory,
            userProvider: StubUserProvider(),
            scheduler: .immediate
        )
        createPaymentRequestFlow.onFinish { result, _ in self.flowResult = result }
    }

    override func tearDown() {
        createPaymentRequestFlow = nil
        navigationController = nil
        paymentRequestUseCase = nil
        presenterFactory = nil
        viewControllerFactory = nil
        cardOnboardingFlowFactory = nil
        payWithWiseEducationFlowFactory = nil
        contactSearchViewControllerFactory = nil
        accountDetailsCreationFlowFactory = nil
        findFriendsFlowFactory = nil
        inviteFlowFactory = nil
        paymentMethodsDynamicFlowHandler = nil
        dynamicFlowFactory = nil
        super.tearDown()
    }

    func test_StartAnalytics_GivenDefaultValues_ThenCorrectAnalyticsEventAndPropertiesTracked() {
        createPaymentRequestFlow = CreatePaymentRequestFlow(
            entryPoint: .paymentRequestList,
            profile: FakeBusinessProfileInfo().asProfile(),
            contact: RequestMoneyContact.build(hasRequestCapability: true),
            preSelectedBalanceCurrencyCode: .cannedGBP,
            defaultBalance: .canned,
            eligibleBalances: .build(balances: [.build(currency: .cannedUSD)]),
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            paymentMethodsDynamicFlowHandler: paymentMethodsDynamicFlowHandler,
            webViewControllerFactory: webViewControllerFactory,
            navController: navigationController,
            analyticsTracker: analyticsTracker,
            paymentRequestUseCase: paymentRequestUseCase,
            presenterFactory: presenterFactory,
            cardOnboardingFlowFactory: cardOnboardingFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            findFriendsFlowFactory: findFriendsFlowFactory,
            viewControllerFactory: viewControllerFactory,
            inviteFlowFactory: inviteFlowFactory,
            dynamicFlowFactory: dynamicFlowFactory,
            userProvider: StubUserProvider(),
            scheduler: .immediate
        )
        viewControllerFactory.makeOnboardingViewControllerReturnValue = UIViewController()
        createPaymentRequestFlow.start()

        let properties = analyticsTracker.lastMixpanelEventPropertiesTracked
        XCTAssertEqual(analyticsTracker.lastMixpanelEventNameTracked, "Request Flow - Started")

        XCTAssertEqual(properties?["Entry Point"] as? String, "Payment Request List")

        XCTAssertEqual(properties?["Initiated With Contact"] as? String, "Yes")
        XCTAssertEqual(properties?["Is Contact Request Eligible"] as? String, "Yes")
        XCTAssertEqual(properties?["Initiated With Currency"] as? String, "GBP")
        XCTAssertEqual(properties?["Currency"] as? String, "USD")
    }

    func test_showConfirmation_givenPaymentRequestStatueIsDraft_butFetchPaymentRequestFails_thenShowError() {
        paymentRequestUseCase.createPaymentRequestReturnValue = .fail(with: PaymentRequestUseCaseError.customError(message: "custom"))
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .fail(with: PaymentRequestUseCaseError.customError(message: "custom"))

        let draftPaymentRequest = PaymentRequestV2.build(status: .draft)
        createPaymentRequestFlow.showConfirmation(paymentRequest: draftPaymentRequest)

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        XCTAssertTrue(navigationController.didShowDismissableAlert)
    }

    func test_showConfirmation_givenPaymentRequestStatueIsDraft_butPublishPaymentRequestFails_theShowError() {
        let draftPaymentRequest = PaymentRequestV2.build(status: .draft)
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .fail(with: PaymentRequestUseCaseError.customError(message: "custom"))

        createPaymentRequestFlow.showConfirmation(paymentRequest: draftPaymentRequest)

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        XCTAssertTrue(navigationController.didShowDismissableAlert)
    }

    func test_showConfirmation_givenPaymentRequestStatueIsPublished_theShowConfirmation() throws {
        let publishedPaymentRequest = PaymentRequestV2.build(status: .published)
        paymentRequestUseCase.createPaymentRequestReturnValue = .just(publishedPaymentRequest)
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .just(publishedPaymentRequest)

        let viewController = UIViewController()
        viewControllerFactory.makeConfirmationReturnValue = viewController
        createPaymentRequestFlow.showConfirmation(paymentRequest: publishedPaymentRequest)

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        let pushPresenter = presenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.keepOnlyLastViewControllerOnStack)
        XCTAssertTrue(pushPresenter.presentCalled)
        let presentedViewController = try XCTUnwrap(pushPresenter.presentedViewControllers.last)
        XCTAssertEqual(presentedViewController, viewController)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share - Started")
        let properties = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked)
        let flowVariant = try XCTUnwrap(properties["FlowVariant"] as? String)
        XCTAssertEqual(flowVariant, "Business")
    }

    func test_addAmountAndNoteTapped_thenShowBottomSheetCreatePaymentRequest_thenShowConfirmation_AndLogAnalytics() throws {
        let createPaymentRequestFlow = CreatePaymentRequestFlow(
            entryPoint: .canned,
            profile: FakePersonalProfileInfo().asProfile(),
            contact: .canned,
            preSelectedBalanceCurrencyCode: .cannedGBP,
            defaultBalance: .canned,
            eligibleBalances: .canned,
            contactSearchViewControllerFactory: contactSearchViewControllerFactory,
            paymentMethodsDynamicFlowHandler: paymentMethodsDynamicFlowHandler,
            webViewControllerFactory: webViewControllerFactory,
            navController: navigationController,
            analyticsTracker: analyticsTracker,
            paymentRequestUseCase: paymentRequestUseCase,
            presenterFactory: presenterFactory,
            cardOnboardingFlowFactory: cardOnboardingFlowFactory,
            payWithWiseEducationFlowFactory: payWithWiseEducationFlowFactory,
            accountDetailsCreationFlowFactory: accountDetailsCreationFlowFactory,
            findFriendsFlowFactory: findFriendsFlowFactory,
            viewControllerFactory: viewControllerFactory,
            inviteFlowFactory: inviteFlowFactory,
            dynamicFlowFactory: dynamicFlowFactory,
            userProvider: StubUserProvider(),
            scheduler: .immediate
        )

        let publishedPaymentRequest = PaymentRequestV2.build(status: .published)
        paymentRequestUseCase.createPaymentRequestReturnValue = .just(publishedPaymentRequest)
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .just(publishedPaymentRequest)

        let viewController1 = UIViewController()
        let viewController2 = UIViewController()
        viewControllerFactory.makeCreatePaymentRequestPersonalBottomSheetReturnValue = viewController1
        viewControllerFactory.makeConfirmationReturnValue = viewController2
        createPaymentRequestFlow.addAmountAndNote()
        createPaymentRequestFlow.showConfirmation(paymentRequest: publishedPaymentRequest)

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        let pushPresenter = presenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.keepOnlyLastViewControllerOnStack)
        XCTAssertTrue(pushPresenter.presentCalled)
        let presentedViewController = try XCTUnwrap(pushPresenter.presentedViewControllers.last)
        XCTAssertEqual(presentedViewController, viewController2)
        let eventName = try XCTUnwrap(analyticsTracker.lastMixpanelEventNameTracked)
        XCTAssertEqual(eventName, "Request Flow - Share - Started")
        let properties = try XCTUnwrap(analyticsTracker.lastMixpanelEventPropertiesTracked)
        let flowVariant = try XCTUnwrap(properties["FlowVariant"] as? String)
        XCTAssertEqual(flowVariant, "Personal")
    }

    func test_showRequestFromContactsSuccess_givenPaymentRequestStatueIsDraft_andPublishPaymentRequestSucceeds_thenShowSuccessScreen() throws {
        let publishedPaymentRequest = PaymentRequestV2.build(status: .published)
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .just(publishedPaymentRequest)
        viewControllerFactory.makeCreatePaymentRequestFromContactSuccessReturnValue = MockViewController()

        createPaymentRequestFlow.showRequestFromContactsSuccess(
            contact: .canned,
            paymentRequest: publishedPaymentRequest
        )

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventNameTracked,
            "Request Flow - Request Published"
        )
        XCTAssertEqual(
            analyticsTracker.lastMixpanelEventPropertiesTracked?["FlowVariant"] as? String,
            "Business"
        )
        let pushPresenter = presenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.keepOnlyLastViewControllerOnStack)
        XCTAssertTrue(pushPresenter.presentCalled)
        let presentedViewController = try XCTUnwrap(pushPresenter.presentedViewControllers.last)
        XCTAssertTrue(presentedViewController is MockViewController)
    }

    func test_requestFromContactsSuccessPrimaryAction() {
        let publishedPaymentRequest = PaymentRequestV2.build(status: .published)
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .just(publishedPaymentRequest)
        viewControllerFactory.makeCreatePaymentRequestFromContactSuccessReturnValue = MockViewController()
        createPaymentRequestFlow.showRequestFromContactsSuccess(
            contact: .canned,
            paymentRequest: publishedPaymentRequest
        )

        viewControllerFactory
            .makeCreatePaymentRequestFromContactSuccessReceivedViewModel?
            .buttonConfiguration
            .actionHandler(nil)

        XCTAssertTrue(
            analyticsTracker.trackedMixpanelEventNames.contains(
                "Request Flow - Success Screen - Done Tapped"
            )
        )
        XCTAssertFalse(
            analyticsTracker.trackedMixpanelEventNames.contains(
                "Request Flow - Success Screen - View Request Tapped"
            )
        )
        XCTAssertEqual(
            flowResult,
            .success(
                paymentRequestId: publishedPaymentRequest.id,
                context: .completed
            )
        )
    }

    func test_showRequestFromContactsSuccess_givenPaymentRequestStatueIsDraft_butFetchPaymentRequestFails_thenShowError() {
        paymentRequestUseCase.createPaymentRequestReturnValue = .fail(with: PaymentRequestUseCaseError.customError(message: "custom"))
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .fail(with: PaymentRequestUseCaseError.customError(message: "custom"))

        let draftPaymentRequest = PaymentRequestV2.build(status: .draft)
        createPaymentRequestFlow.showRequestFromContactsSuccess(
            contact: .canned,
            paymentRequest: draftPaymentRequest
        )

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        XCTAssertTrue(navigationController.didShowDismissableAlert)
    }

    func test_showRequestFromContactsSuccess_givenPaymentRequestStatueIsDraft_butPublishPaymentRequestFails_thenShowError() {
        let draftPaymentRequest = PaymentRequestV2.build(status: .draft)
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .fail(with: PaymentRequestUseCaseError.customError(message: "custom"))

        createPaymentRequestFlow.showRequestFromContactsSuccess(
            contact: .canned,
            paymentRequest: draftPaymentRequest
        )

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        XCTAssertTrue(navigationController.didShowDismissableAlert)
    }

    func test_showRequestFromContactsSuccess_givenPaymentRequestStatusIsPublished_thenShowSuccessScreen() throws {
        let publishedPaymentRequest = PaymentRequestV2.build(status: .published)
        paymentRequestUseCase.createPaymentRequestReturnValue = .just(publishedPaymentRequest)
        paymentRequestUseCase.updatePaymentRequestStatusReturnValue = .just(publishedPaymentRequest)

        viewControllerFactory.makeCreatePaymentRequestFromContactSuccessReturnValue = MockViewController()

        createPaymentRequestFlow.showRequestFromContactsSuccess(
            contact: .canned,
            paymentRequest: publishedPaymentRequest
        )

        XCTAssertTrue(navigationController.didShowHud)
        XCTAssertTrue(navigationController.didHideHud)
        let pushPresenter = presenterFactory.pushPresenter
        XCTAssertTrue(pushPresenter.keepOnlyLastViewControllerOnStack)
        XCTAssertTrue(pushPresenter.presentCalled)
        let presentedViewController = try XCTUnwrap(pushPresenter.presentedViewControllers.last)
        XCTAssertTrue(presentedViewController is MockViewController)
    }

    func test_showPayWithWiseEducation() {
        let mockFlow = MockFlow<RequestMoneyPayWithWiseEducationFlowResult>()
        payWithWiseEducationFlowFactory.makeBottomSheetFlowReturnValue = mockFlow

        createPaymentRequestFlow.showPayWithWiseEducation()

        XCTAssertEqual(payWithWiseEducationFlowFactory.makeBottomSheetFlowCallsCount, 1)
        XCTAssertTrue(mockFlow.startCalled)
    }

    func test_inviteFriendsSelected_shouldStartInviteFlow() throws {
        let mockFlow = MockFlow<RequestMoneyPayWithWiseEducationFlowResult>()
        payWithWiseEducationFlowFactory.makeBottomSheetFlowReturnValue = mockFlow
        createPaymentRequestFlow.showPayWithWiseEducation()
        let inviteFlow = MockFlow<Void>()
        inviteFlowFactory.makeReturnValue = inviteFlow

        let dismisser = FakeViewControllerDismisser()
        mockFlow.flowHandler.flowFinished(result: .inviteFriendsSelected, dismisser: dismisser)

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertTrue(inviteFlow.startCalled)
    }

    func test_EndFlowInvoked_OnRequestFromAnyoneScreen_GivenAborted() throws {
        let dismisser = FakeViewControllerDismisser()
        let mockFlow = MockFlow<CreatePaymentRequestFlowResult>()
        mockFlow.flowHandler.flowFinished(result: .aborted, dismisser: dismisser)
        let viewController = MockViewController()
        let viewController2 = MockViewController()
        viewControllerFactory.makeCreatePaymentRequestPersonalReturnValue = viewController
        viewControllerFactory.makeRequestFromAnyoneViewControllerReturnValue = viewController2
        createPaymentRequestFlow.createPaymentRequest(contact: nil)
        createPaymentRequestFlow.endFlow()

        XCTAssertTrue(dismisser.dismissCalled)
        XCTAssertEqual(
            flowResult,
            .aborted
        )
    }

    func test_EndFlowInvoked_OnRequestFromAnyoneScreen_GivenSharedWisetag() throws {
        let dismisser = FakeViewControllerDismisser()
        let mockFlow = MockFlow<CreatePaymentRequestFlowResult>()
        mockFlow.flowHandler.flowFinished(result: .aborted, dismisser: dismisser)
        let viewController = MockViewController()
        let viewController2 = MockViewController()
        viewControllerFactory.makeCreatePaymentRequestPersonalReturnValue = viewController
        viewControllerFactory.makeRequestFromAnyoneViewControllerReturnValue = viewController2
        createPaymentRequestFlow.createPaymentRequest(contact: nil)
        createPaymentRequestFlow.endFlow()

        XCTAssertTrue(dismisser.dismissCalled)
        // TODO: next PR - implement new result value
    }

    func test_search_GivenContactSelected_WhenSearchStarted_ThenCorrectValuesReceived() throws {
        let viewController = UIViewController()
        let expectedContact = Contact.build(
            id: Contact.Id.contact("11")
        )
        let subject: PassthroughSubject<ReceiveContactPickerSearchResult, Never> = .init()
        contactSearchViewControllerFactory.makeContactSearchReturnValue = ReceiveContactSearchViewControllerFactoryMakeResult(
            viewController: viewController,
            resultPublisher: subject.eraseToAnyPublisher()
        )

        let viewController2 = UIViewController()
        viewControllerFactory.makeCreatePaymentRequestPersonalReturnValue = viewController2

        createPaymentRequestFlow.startSearch()
        XCTAssertEqual(
            contactSearchViewControllerFactory.makeContactSearchReceivedArguments?.profile.id,
            profile.id
        )
        subject.send(.selected(expectedContact))
        XCTAssertEqual(
            presenterFactory.pushPresenter.presentedViewControllers.first,
            viewController
        )
        XCTAssertEqual(
            analyticsTracker.trackedMixpanelEventNames,
            [
                "Request Flow - Contact Picker - Search - Started",
                "Request Flow - Contact Picker - Search - Contact Selected",
                "Request Flow - Create - Started",
            ]
        )

        XCTAssertEqual(
            presenterFactory.pushPresenter.presentedViewControllers.last,
            viewController2
        )
    }

    func test_showPaymentMethods_thenChangeDefaultsSelected() {
        let delegate = PaymentMethodsDelegateMock()

        let viewController = UIViewController()
        viewControllerFactory.makePaymentMethodsSelectionReturnValue = viewController

        createPaymentRequestFlow.showPaymentMethodsSheet(
            delegate: delegate,
            localPreferences: [.payWithWise],
            methods: .canned,
            completion: { _ in }
        )

        webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReturnValue = WebContentViewController(url: URL(string: "https://abc.com")!)

        createPaymentRequestFlow.showPaymentMethodManagementOnWeb(delegate: delegate)

        let expectedUrl = Branding.current.url
            .appendingPathComponent("/payments/method-management")
        let receivedArguments = webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationReceivedArguments
        receivedArguments?.modalDismissalHandler!()
        XCTAssertEqual(receivedArguments?.url, expectedUrl)
        XCTAssertTrue(webViewControllerFactory.makeWithURLAndUserInfoForAuthenticationCalled)
        XCTAssertEqual(delegate.refreshPaymentMethodsCallsCount, 1)
    }

    func test_showDynamicForms_thenDynamicFlowHandlerIsInvoked() throws {
        let delegate = PaymentMethodsDelegateMock()
        let forms = [PaymentMethodDynamicForm.build(flowId: "", url: "")]

        createPaymentRequestFlow.showDynamicFormsMethodManagement(forms, delegate: delegate)

        XCTAssertTrue(paymentMethodsDynamicFlowHandler.showDynamicFormsCalled)
    }
}
