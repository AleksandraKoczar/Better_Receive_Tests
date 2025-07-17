import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import SwiftUI
import TWTestingSupportKit
import WiseCoreTestingSupport

final class ReceiveMethodsQRSharingCustomizationViewTests: TWSnapshotTestCase {
    func testLayout() throws {
        let delegate = ReceiveMethodsQRSharingCustomizationDelegateMock()
        let viewModel = ReceiveMethodsQRSharingCustomizationViewModel(
            alias: ReceiveMethodAlias.build(key: .build(type: .email, value: "test@example.com")),
            accountDetailsId: .canned,
            profileId: .canned,
            delegate: delegate
        )

        let vc = SwiftUIHostingController {
            NavigationView {
                ReceiveMethodsQRSharingCustomizationView(
                    viewModel: viewModel
                )
            }.navigationViewStyle(.stack)
        }
        TWSnapshotVerifyViewController(vc)
    }
}
