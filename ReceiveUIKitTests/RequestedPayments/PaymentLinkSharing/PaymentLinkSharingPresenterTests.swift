import CombineSchedulers
import Prism
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import Testing
import TWFoundationTestingSupport
import TWTestingSupportKit
import WiseCore
import WiseCoreTestingSupport

@MainActor
struct PaymentLinkSharingPresenterTests {
    private let presenter: PaymentLinkSharingPresenterImpl
    private let interactor: PaymentLinkSharingInteractorMock
    private let router: PaymentLinkSharingRouterMock
    private let tracking: PaymentRequestShareModalTrackingMock
    private let viewModelMapper: PaymentLinkSharingViewModelMapperMock
    private let view: PaymentLinkSharingViewMock

    init() {
        interactor = .init()
        router = .init()
        tracking = .init()
        viewModelMapper = .init()
        view = .init()
        presenter = .init(
            source: .billSplit,
            interactor: interactor,
            router: router,
            tracking: tracking,
            viewModelMapper: viewModelMapper,
            scheduler: .immediate
        )

        interactor.fetchDetailsReturnValue = .just(.loading(nil))
        viewModelMapper.mapReturnValue = viewModel
    }

    @Test
    func viewLoaded_callsInteractor() {
        presenter.viewLoaded(with: view)

        #expect(interactor.fetchDetailsCallsCount == 1)
        assertViewModelStates(expectedStates: [.loading(nil)])
    }

    @Test
    func viewLoaded_sendsAnalyticsEvent() {
        presenter.viewLoaded(with: view)

        #expect(tracking.onPaymentRequestModalStartedCallsCount == 1)
        #expect(tracking.onPaymentRequestModalStartedReceivedArguments?.source == .billSplit)
    }

    @Test
    func viewLoaded_calledTwice_doesNotSendAnalyticsEventAgain() {
        presenter.viewLoaded(with: view)
        #expect(tracking.onPaymentRequestModalStartedCallsCount == 1)

        presenter.viewLoaded(with: view)
        #expect(tracking.onPaymentRequestModalStartedCallsCount == 1)
    }

    @Test
    func viewLoaded_withLoadedDetails() {
        interactor.fetchDetailsReturnValue = .just(.content(.canned))

        presenter.viewLoaded(with: view)

        #expect(viewModelMapper.mapCallsCount == 1)
        #expect(viewModelMapper.mapReceivedArguments?.model == PaymentLinkSharingDetails.canned)
        #expect(view.configureCallsCount == 1)
        #expect(view.configureReceivedViewModel == viewModel)
        assertViewModelStates(expectedStates: [.content(.canned)])
    }

    @Test
    func viewLoaded_withError() {
        interactor.fetchDetailsReturnValue = .just(.error(MockError.dummy))

        presenter.viewLoaded(with: view)

        #expect(!viewModelMapper.mapCalled)
        #expect(!view.configureCalled)
        assertViewModelStates(expectedStates: [.error(MockError.dummy)])
    }

    @Test
    func refresh_callsInteractor() {
        presenter.viewLoaded(with: view)
        #expect(interactor.fetchDetailsCallsCount == 1)

        presenter.refresh()
        #expect(interactor.fetchDetailsCallsCount == 2)
    }

    @Test
    func handleShareLinkAction() throws {
        interactor.fetchDetailsReturnValue = .just(.content(.canned))
        presenter.viewLoaded(with: view)

        let actionHandler = try #require(viewModelMapper.mapReceivedArguments?.actionHandler)
        actionHandler(.shareLink(.canned))

        #expect(router.openLinkSharingCallsCount == 1)
        expectNoDifference(router.openLinkSharingReceivedPaymentRequest, PaymentRequestV2.canned)
        #expect(tracking.onPaymentRequestModalShareLinkClickedCallsCount == 1)
    }

    @Test
    func handleViewPaymentRequestAction() throws {
        interactor.fetchDetailsReturnValue = .just(.content(.canned))
        presenter.viewLoaded(with: view)

        let actionHandler = try #require(viewModelMapper.mapReceivedArguments?.actionHandler)
        actionHandler(.viewPaymentRequest(.canned))

        #expect(router.openPaymentRequestDetailsCallsCount == 1)
        expectNoDifference(router.openPaymentRequestDetailsReceivedPaymentRequestId, PaymentRequestId.canned)
        #expect(tracking.onPaymentRequestModalViewRequestClickedCallsCount == 1)
    }
}

private extension PaymentLinkSharingPresenterTests {
    var viewModel: PaymentLinkSharingViewModel {
        .init(
            qrCodeImage: nil,
            title: "title",
            amount: "10 GBP",
            navigationOptions: []
        )
    }

    func assertViewModelStates(
        expectedStates: [PaymentLinkSharingDetailsModelState],
        line: UInt = #line,
        column: UInt = #column
    ) {
        expectNoDifference(
            view.loadingStateChangedReceivedInvocations as? [PaymentLinkSharingDetailsModelState],
            expectedStates,
            line: line,
            column: column
        )
    }
}
