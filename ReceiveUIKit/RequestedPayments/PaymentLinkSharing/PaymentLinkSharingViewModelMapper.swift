import LoggingKit
import Neptune
import ReceiveKit
import TransferResources
import TWFoundation
import UIKit

typealias PaymentLinkSharingActionHandler = (PaymentLinkSharingViewAction) -> Void

// sourcery: AutoMockable
protocol PaymentLinkSharingViewModelMapper {
    func map(
        _ model: PaymentLinkSharingDetails,
        actionHandler: @escaping PaymentLinkSharingActionHandler
    ) -> PaymentLinkSharingViewModel
}

struct PaymentLinkSharingViewModelMapperImpl: PaymentLinkSharingViewModelMapper {
    func map(
        _ model: PaymentLinkSharingDetails,
        actionHandler: @escaping PaymentLinkSharingActionHandler
    ) -> PaymentLinkSharingViewModel {
        .init(
            qrCodeImage: qrCodeImage(from: model),
            title: title(from: model.paymentRequest.payerSummary),
            amount: amount(from: model.paymentRequest.amount),
            navigationOptions: navigationOptions(from: model, actionHandler: actionHandler)
        )
    }
}

private extension PaymentLinkSharingViewModelMapperImpl {
    func qrCodeImage(from model: PaymentLinkSharingDetails) -> UIImage? {
        let qrImage = model.qrCodeImage ?? UIImage.qrCode(from: model.paymentRequest.link)

        if qrImage.isNil {
            LogWarn("[REC]: Failed to fetch or generate payment link QR in Payment Link Sharing view.")
        }

        return qrImage
    }

    func title(from payer: PaymentRequestV2.PayerSummary?) -> String {
        guard let title = payer?.name else {
            LogWarn("[REC]: Payer name is missing in Payment Link Sharing view.")
            return ""
        }

        return title
    }

    func amount(from model: PaymentRequestAmount) -> String {
        MoneyFormatter.format(
            model.value,
            withCurrencyCode: model.currency
        )
    }

    func navigationOptions(
        from model: PaymentLinkSharingDetails,
        actionHandler: @escaping PaymentLinkSharingActionHandler
    ) -> [PaymentLinkSharingViewModel.NavigationOption] {
        let shareOption = PaymentLinkSharingViewModel.NavigationOption(
            viewModel: .init(
                title: L10n.PaymentRequest.Detail.PaymentLink.Options.share,
                avatar: .icon(Icons.shareIos.image)
            ),
            onTap: { actionHandler(.shareLink(model.paymentRequest)) }
        )

        let viewRequestOption = PaymentLinkSharingViewModel.NavigationOption(
            viewModel: .init(
                title: L10n.PaymentRequest.PaymentLinkSharing.Options.ViewRequest.title,
                subtitle: L10n.PaymentRequest.PaymentLinkSharing.Options.ViewRequest.subtitle,
                avatar: .icon(Icons.requestReceive.image)
            ),
            onTap: { actionHandler(.viewPaymentRequest(model.paymentRequest.id)) }
        )

        return [shareOption, viewRequestOption]
    }
}
