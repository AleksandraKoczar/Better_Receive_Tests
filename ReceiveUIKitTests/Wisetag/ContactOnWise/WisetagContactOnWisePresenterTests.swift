import AnalyticsKitTestingSupport
import Neptune
import Prism
@testable import ReceiveUIKit
import ReceiveUIKitTestingSupport
import TransferResources
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKit
import UserKitTestingSupport

@MainActor
final class WisetagContactOnWisePresenterTests: TWTestCase {
    private let nickname = LoremIpsum.short
    private let profile = {
        let info = FakePersonalProfileInfo()
        info.addPrivilege(ProfileIdentifierDiscoverabilityPrivilege.manage)
        info.firstName = "Harry"
        info.lastName = "Potter"
        return info.asProfile()
    }()

    private var presenter: WisetagContactOnWisePresenterImpl!
    private var router: WisetagContactOnWiseRouterMock!
    private var view: WisetagContactOnWiseViewMock!
    private var analyticsTracker: BusinessProfileLinkTrackingMock!

    override func setUp() {
        super.setUp()
        analyticsTracker = BusinessProfileLinkTrackingMock()
        router = WisetagContactOnWiseRouterMock()
        view = WisetagContactOnWiseViewMock()
        presenter = WisetagContactOnWisePresenterImpl(
            nickname: nickname,
            profile: profile,
            router: router,
            quickpayAnalyticsTracker: analyticsTracker
        )
    }

    override func tearDown() {
        presenter = nil
        view = nil
        router = nil
        analyticsTracker = nil
        super.tearDown()
    }

    func test_startGivenPersonalProfile() throws {
        presenter.start(with: view)
        XCTAssertEqual(view.configureCallsCount, 1)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        let expected = makeViewModel()
        expectNoDifference(viewModel, expected)
    }

    func test_startGivenBusinessProfile() throws {
        let profile = {
            let info = FakeBusinessProfileInfo()
            info.addPrivilege(ProfileIdentifierDiscoverabilityPrivilege.manage)
            return info.asProfile()
        }()
        let presenter = WisetagContactOnWisePresenterImpl(
            nickname: nickname,
            profile: profile,
            router: router,
            quickpayAnalyticsTracker: analyticsTracker
        )
        presenter.start(with: view)

        XCTAssertEqual(view.configureCallsCount, 1)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        let expected = makeViewModelForBusiness()
        expectNoDifference(viewModel, expected)
    }

    func test_confirmTapped_givenWisetagDiscoverableIsOn_thenDismissAndUpdateStatus() throws {
        presenter.start(with: view)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)

        viewModel.wisetagOption.onToggle(true)
        viewModel.action.handler()

        let arguments = try XCTUnwrap(router.dismissAndUpdateShareableLinkStatusReceivedArguments)
        XCTAssertTrue(arguments.isDiscoverable)
        XCTAssertEqual(router.dismissAndUpdateShareableLinkStatusCallsCount, 1)

        XCTAssertEqual(analyticsTracker.onDiscoverabilityToggledCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onDiscoverabilityToggledReceivedArguments?.toggleState, .enabled)
    }

    func test_confirmTapped_givenWisetagDiscoverableIsOff_thenDismissAndUpdateStatus() throws {
        presenter.start(with: view)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)

        viewModel.wisetagOption.onToggle(false)
        viewModel.action.handler()

        let arguments = try XCTUnwrap(router.dismissAndUpdateShareableLinkStatusReceivedArguments)
        XCTAssertFalse(arguments.isDiscoverable)
        XCTAssertEqual(router.dismissAndUpdateShareableLinkStatusCallsCount, 1)

        XCTAssertEqual(analyticsTracker.onDiscoverabilityToggledCallsCount, 1)
        XCTAssertEqual(analyticsTracker.onDiscoverabilityToggledReceivedArguments?.toggleState, .disabled)
    }

    func test_startGivenBusinessProfile_AndNoManagePermissions() throws {
        let profile = FakeBusinessProfileInfo().asProfile()
        let presenter = WisetagContactOnWisePresenterImpl(
            nickname: nickname,
            profile: profile,
            router: router,
            quickpayAnalyticsTracker: analyticsTracker
        )
        presenter.start(with: view)

        XCTAssertEqual(view.configureCallsCount, 1)
        let viewModel = try XCTUnwrap(view.configureReceivedViewModel)
        let expected = makeViewModelForBusinessWithAlert()
        expectNoDifference(viewModel, expected)
    }

    // MARK: - Helpers

    private func makeViewModel() -> WisetagContactOnWiseViewModel {
        WisetagContactOnWiseViewModel(
            title: L10n.Wisetag.ContactOnWise.title,
            subtitle: L10n.Wisetag.ContactOnWise.subtitle,
            inlineAlert: nil,
            wisetagOption: makeWisetagSwitchOption(),
            action: Action(
                title: L10n.Wisetag.ContactOnWise.Button.title,
                handler: {}
            )
        )
    }

    private func makeViewModelForBusiness() -> WisetagContactOnWiseViewModel {
        WisetagContactOnWiseViewModel(
            title: L10n.Quickpay.Discoverability.title,
            subtitle: L10n.Quickpay.Discoverability.subtitle,
            inlineAlert: nil,
            wisetagOption: makeWisetagSwitchOptionForBusiness(isEnabled: true),
            action: Action(
                title: L10n.Wisetag.ContactOnWise.Button.title,
                handler: {}
            )
        )
    }

    private func makeViewModelForBusinessWithAlert() -> WisetagContactOnWiseViewModel {
        WisetagContactOnWiseViewModel(
            title: L10n.Quickpay.Discoverability.title,
            subtitle: L10n.Quickpay.Discoverability.subtitle,
            inlineAlert: .init(viewModel: .init(markdown: L10n.Wisetag.ContactOnWise.PermissionsAlert.text), style: .neutral),
            wisetagOption: makeWisetagSwitchOptionForBusiness(isEnabled: false),
            action: Action(
                title: L10n.Wisetag.ContactOnWise.Button.title,
                handler: {}
            )
        )
    }

    private func makeWisetagSwitchOptionForBusiness(isEnabled: Bool) -> WisetagContactOnWiseViewModel.SwitchOption {
        WisetagContactOnWiseViewModel.SwitchOption(
            viewModel: SwitchOptionViewModel(
                model: OptionViewModel(
                    title: L10n.Quickpay.Discoverability.Options.title,
                    subtitle: L10n.Quickpay.Discoverability.Options.subtitle,
                    avatar: .initials(Initials(name: ""), badge: nil),
                    isEnabled: isEnabled
                ),
                isOn: true
            ),
            onToggle: { _ in }
        )
    }

    private func makeWisetagSwitchOption() -> WisetagContactOnWiseViewModel.SwitchOption {
        WisetagContactOnWiseViewModel.SwitchOption(
            viewModel: SwitchOptionViewModel(
                model: OptionViewModel(
                    title: L10n.Wisetag.ContactOnWise.Options.Title.wisetag,
                    subtitle: nickname,
                    avatar: .initials(Initials(name: "Harry Potter"))
                ),
                isOn: true
            ),
            onToggle: { _ in }
        )
    }
}
