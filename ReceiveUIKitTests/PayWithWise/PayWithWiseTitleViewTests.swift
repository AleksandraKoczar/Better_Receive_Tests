import ContactsKit
import Foundation
import Neptune
@testable import ReceiveUIKit
import TWTestingSupportKit
import UIKit
import WiseAtomsAssets

final class PayWithWiseHeaderViewTests: TWSnapshotTestCase {
    func testLayout() {
        let viewModel = PayWithWiseHeaderView.ViewModel(
            title: .init(title: LoremIpsum.veryShort),
            recipientName: "Aleksandra",
            description: "cookies",
            avatarImage: .just(AvatarViewModel(avatar: AvatarModel.image(Illustrations.electricPlug.image)))
        )
        let view = PayWithWiseHeaderView()
        view.configure(with: viewModel)
        view.layoutForTest(fittingWidth: 320)
        TWSnapshotVerifyView(view, appearances: .all)
    }
}
