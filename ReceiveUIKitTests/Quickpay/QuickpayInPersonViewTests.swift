import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import SwiftUI
import TWFoundation
import TWFoundationTestingSupport
import TWTestingSupportKit
import UserKitTestingSupport

final class QuickpayInPersonViewTests: TWSnapshotTestCase {
    var viewModel: QuickpayInPersonViewModel!
    var useCase: QuickpayUseCaseMock!
    var interactor: WisetagInteractorMock!
    var pasteboard: MockPasteboard!
    var vc: UIViewController!

    override func setUp() {
        super.setUp()
        let profile = FakeBusinessProfileInfo().asProfile()
        interactor = WisetagInteractorMock()
        let status = ShareableLinkStatus.eligible(.discoverable(urlString: LoremIpsum.short, nickname: LoremIpsum.short))
        let returnValue = (status, UIImage.canned)
        interactor.fetchQRCodeReturnValue = .just(returnValue)
        pasteboard = MockPasteboard()
        useCase = QuickpayUseCaseMock()
        useCase.getCurrencyAvailabilityReturnValue = .just(.content(
            .build(preferredCurrency: .GBP, availableCurrencies: [.GBP, .PLN]),
            error: nil
        ))

        let viewModel = QuickpayInPersonViewModel(
            profile: profile,
            quickpayUseCase: useCase,
            wisetagInteractor: interactor,
            status: .discoverable(urlString: "", nickname: ""),
            pasteboard: pasteboard,
            onDownloadQRCodeTapped: { _ in }
        )
        self.viewModel = viewModel

        vc = SwiftUIHostingController {
            QuickpayInPersonView(viewModel: viewModel)
        }
    }

    override func tearDown() {
        super.tearDown()
        useCase = nil
        viewModel = nil
        interactor = nil
        pasteboard = nil
        vc = nil
    }

    @MainActor
    func test_Loaded() async {
        await viewModel.handle(.load)
        TWSnapshotVerifyViewController(vc)
    }
}
