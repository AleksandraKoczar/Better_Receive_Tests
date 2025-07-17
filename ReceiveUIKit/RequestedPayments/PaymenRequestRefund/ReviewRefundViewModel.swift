import MacrosKit
import ReceiveKit
import SwiftUI
import TransferResources
import TWFoundation
import UserKit
import WiseCore

@Mock @MainActor
protocol ReviewRefundDelegate: AnyObject {
    func dismiss()
    func showSuccess(refund: Refund)
    func showFailure()
}

struct ReviewRefundContent: Equatable {
    struct Section: Identifiable, Equatable {
        struct Item: Identifiable, Equatable {
            var id: String { title }
            let title: String
            let subtitle: String
        }

        var id: String { title }
        let title: String
        let items: [Item]
    }

    let sections: [Section]
    let buttonTitle: String
}

final class ReviewRefundViewModel: ModelStateViewModel<ReviewRefundContent, Void, Error> {
    private let paymentId: String
    private let refund: Refund
    private let profileId: ProfileId
    private let useCase: AcquiringPaymentUseCase
    private weak var delegate: ReviewRefundDelegate?

    private let uuid = UUID()

    init(
        paymentId: String,
        refund: Refund,
        profileId: ProfileId,
        useCase: AcquiringPaymentUseCase = AcquiringPaymentUseCaseFactory.make(),
        delegate: ReviewRefundDelegate?
    ) {
        self.paymentId = paymentId
        self.refund = refund
        self.profileId = profileId
        self.useCase = useCase
        self.delegate = delegate
    }

    func configureView() {
        let refundSection = ReviewRefundContent.Section(
            title: L10n.PaymentRequest.Refund.Review.Refund.header,
            items: [
                .init(title: L10n.PaymentRequest.Refund.Review.Refund.title, subtitle: MoneyFormatter.format(refund.amount)),
                refund.reason.map { .init(title: L10n.PaymentRequest.Refund.Review.Refund.reason, subtitle: $0) },
            ].compactMap { $0 }
        )

        let customerDetailsSection: ReviewRefundContent.Section? = {
            guard let payerData = refund.payerData else { return nil }
            let nameItem = payerData.name.map {
                ReviewRefundContent.Section.Item(title: L10n.PaymentRequest.Refund.Review.CustomerDetails.refundTo, subtitle: $0)
            }
            let emailItem = payerData.email.map {
                ReviewRefundContent.Section.Item(title: L10n.PaymentRequest.Refund.Review.CustomerDetails.contact, subtitle: $0)
            }

            let items = [nameItem, emailItem].compactMap { $0 }
            guard items.isNonEmpty else { return nil }
            return ReviewRefundContent.Section(title: L10n.PaymentRequest.Refund.Review.CustomerDetails.header, items: items)
        }()

        state.content = ReviewRefundContent(
            sections: [refundSection] + [customerDetailsSection].compactMap { $0 },
            buttonTitle: L10n.PaymentRequest.Refund.Review.Button.refund(MoneyFormatter.format(refund.amount))
        )
    }

    @MainActor
    func refundTapped() async {
        let request = CreateRefundRequest(
            amount: .init(
                value: refund.amount.value,
                currency: refund.amount.currency.value
            ),
            note: refund.reason
        )

        state = .loading(state.content)

        do {
            try await useCase.refund(paymentId: paymentId, profileId: profileId, id: uuid, request: request)
            delegate?.showSuccess(refund: refund)
            guard let lastContent = state.content else { return }
            state = .content(lastContent, error: nil)
        } catch {
            delegate?.showFailure()

            guard let lastContent = state.content else { return }
            state = .content(lastContent, error: error)
        }
    }

    @MainActor
    func editTapped() {
        delegate?.dismiss()
    }
}
