import Neptune
import UIKit

enum CreatePaymentRequestConfirmationPrivacyNoticeViewControllerFactory {
    static func make(
        viewModel: CreatePaymentRequestConfirmationPrivacyNoticeViewModel,
        presenter: CreatePaymentRequestConfirmationPresenter
    ) -> UIViewController {
        let stackMarkdownLabel = StackContainerView<MarkdownLabel>(frame: .zero).with {
            $0.padding = .init(value: .defaultMargin)
            $0.setSeparatorHidden(true)
            $0.numberOfLines = 0
            $0.linkActionHandler = { [weak presenter] _ in
                presenter?.privacyPolicyTapped()
            }
            $0.markdownText = viewModel.info
        }
        return BottomSheetViewController(
            title: viewModel.title,
            arrangedSubviews: [
                stackMarkdownLabel,
                .spacer(.defaultMargin),
            ]
        )
    }
}
