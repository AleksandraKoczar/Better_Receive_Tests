import Neptune
@testable import ReceiveUIKit
import TWFoundationTestingSupport
import TWTestingSupportKit

final class PaymentRequestQRSharingViewControllerTests: TWSnapshotTestCase {
    func testLayout() {
        let viewController = PaymentRequestQRSharingViewController(
            presenter: PaymentRequestQRSharingPresenterMock(),
            autoBrightnessAdjuster: AutoBrightnessAdjusterMock()
        )
        viewController.configure(
            with: PaymentRequestQRSharingViewModel(
                avatar: AvatarViewModel.image(
                    UIImage.color(.gray)
                ),
                title: "Scan to pay",
                subtitle: "Jane Doe",
                qrCodeImage: UIImage.qrCode(from: "https://wise.com/pay/me/abcd-wxyz-1234-5678"),
                requestDetailsHeader: "Request Details",
                requestItems: [
                    PaymentRequestQRSharingViewModel.ListItemViewModel(
                        title: "Amount", value: "1255 GBP"
                    ),
                    .init(
                        title: "Note",
                        value: "Payment for cheese"
                    ),
                ]
            )
        )
        TWSnapshotVerifyViewController(viewController)
    }
}
