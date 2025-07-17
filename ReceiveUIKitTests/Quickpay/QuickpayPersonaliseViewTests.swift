import Neptune
import Prism
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import SwiftUI
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport

final class QuickpayPersonaliseViewTests: TWSnapshotTestCase {
    var viewModel: QuickpayPersonaliseViewModel!
    var useCase: QuickpayUseCaseMock!
    var interactor: WisetagInteractorMock!
    var pasteboard: MockPasteboard!
    var analyticsTracker: BusinessProfileLinkTrackingMock!
    var vc: UIViewController!

    override func setUp() {
        super.setUp()
        interactor = WisetagInteractorMock()
        let status = ShareableLinkStatus.eligible(.discoverable(urlString: LoremIpsum.short, nickname: LoremIpsum.short))
        let returnValue = (status, UIImage.canned)
        analyticsTracker = BusinessProfileLinkTrackingMock()
        interactor.fetchQRCodeReturnValue = .just(returnValue)
        pasteboard = MockPasteboard()
        useCase = QuickpayUseCaseMock()
        useCase.getCurrencyAvailabilityReturnValue = .just(.content(
            .build(preferredCurrency: .GBP, availableCurrencies: [.GBP, .PLN]),
            error: nil
        ))

        let viewModel = QuickpayPersonaliseViewModel(
            quickpayUseCase: useCase,
            wisetagInteractor: interactor,
            status: .discoverable(urlString: LoremIpsum.short, nickname: LoremIpsum.short),
            analyticsTracker: analyticsTracker,
            pasteboard: pasteboard,
            onDownloadQRCodeTapped: { _ in }
        )
        self.viewModel = viewModel

        vc = SwiftUIHostingController {
            QuickpayPersonaliseView(viewModel: viewModel)
        }
    }

    override func tearDown() {
        super.tearDown()
        useCase = nil
        viewModel = nil
        interactor = nil
        pasteboard = nil
        analyticsTracker = nil
        vc = nil
    }

    @MainActor
    func test_Loaded() async {
        await viewModel.handle(.load)
        TWSnapshotVerifyViewController(vc)
    }
}
