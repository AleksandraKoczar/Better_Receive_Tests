import Neptune
import ReceiveKit
import ReceiveKitTestingSupport
@testable import ReceiveUIKit
import Testing
import TWTestingSupportKit
import WiseCore
import WiseCoreTestingSupport

struct PaymentLinkSharingViewModelMapperTests {
    private let mapper = PaymentLinkSharingViewModelMapperImpl()

    @Test
    func map() {
        let model = PaymentLinkSharingDetails(
            paymentRequest: .build(
                amount: .build(currency: .GBP, value: 12.5),
                payerSummary: .build(
                    name: "Steve"
                )
            ),
            qrCodeImage: UIImage.canned
        )

        let viewModel = mapper.map(model) { _ in }
        expectNoDifference(
            viewModel,
            .init(
                qrCodeImage: UIImage.canned,
                title: "Steve",
                amount: "12.50\u{00A0}GBP",
                navigationOptions: [
                    .init(
                        viewModel: .init(
                            title: "Share link",
                            avatar: .icon(Icons.shareIos.image)
                        ),
                        onTap: {}
                    ),
                    .init(
                        viewModel: .init(
                            title: "View request",
                            subtitle: "See details, close or mark this request as paid",
                            avatar: .icon(Icons.requestReceive.image)
                        ),
                        onTap: {}
                    ),
                ]
            )
        )
    }

    @Test
    func map_whenQrCodeImageIsNil_thenClientGeneratesImage() {
        let model = PaymentLinkSharingDetails(
            paymentRequest: .build(link: "wise.com"),
            qrCodeImage: nil
        )

        let viewModel = mapper.map(model) { _ in }
        #expect(viewModel.qrCodeImage.isNonNil)
    }

    @Test
    func map_whenPayerSummaryIsNil_thenTitleIsEmpty() {
        let model = PaymentLinkSharingDetails(paymentRequest: .build(payerSummary: nil), qrCodeImage: nil)

        let viewModel = mapper.map(model) { _ in }
        #expect(viewModel.title.isEmpty)
    }

    @Test
    func shareOption_triggersShareLinkAction() throws {
        let paymentRequest = PaymentRequestV2.canned
        let model = PaymentLinkSharingDetails(
            paymentRequest: paymentRequest,
            qrCodeImage: nil
        )

        var receivedAction: PaymentLinkSharingViewAction?
        let viewModel = mapper.map(model) { receivedAction = $0 }
        let shareOption = try #require(viewModel.navigationOptions[safe: 0])
        shareOption.onTap()

        expectNoDifference(receivedAction, .shareLink(paymentRequest))
    }

    @Test
    func viewRequestOption_triggersViewPaymentRequestAction() throws {
        let paymentRequestId = PaymentRequestId.canned
        let model = PaymentLinkSharingDetails(
            paymentRequest: .build(id: paymentRequestId),
            qrCodeImage: nil
        )

        var receivedAction: PaymentLinkSharingViewAction?
        let viewModel = mapper.map(model) { receivedAction = $0 }
        let viewRequestOption = try #require(viewModel.navigationOptions[safe: 1])
        viewRequestOption.onTap()

        expectNoDifference(receivedAction, .viewPaymentRequest(paymentRequestId))
    }
}
