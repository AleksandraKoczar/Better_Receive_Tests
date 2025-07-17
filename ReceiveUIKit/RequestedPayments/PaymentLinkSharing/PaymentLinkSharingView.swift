import Neptune
import UIKit

// sourcery: AutoMockable
// sourcery: baseClass = "LoadingPresentableMock"
@MainActor
protocol PaymentLinkSharingView: AnyObject, LoadingPresentable {
    func configure(with viewModel: PaymentLinkSharingViewModel)
}

final class PaymentLinkSharingViewController: LCEBottomSheetViewController, PaymentLinkSharingView {
    private let presenter: PaymentLinkSharingPresenter

    private lazy var qrCodeImageView = UIImageView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.layer.magnificationFilter = .nearest
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
    }

    private lazy var qrCodeContainer = UIStackView(arrangedSubviews: [qrCodeImageView]).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(theme.spacing.horizontal.value64)
    }

    private lazy var paymentLinkTitle = StackLabel().with {
        $0.setStyle(\.sectionTitle.centered)
        $0.padding = .horizontal(theme.spacing.horizontal.componentDefault)
    }

    private lazy var paymentLinkSubtitle = StackLabel().with {
        $0.setStyle(\.largeBody)
        $0.padding = .horizontal(theme.spacing.horizontal.componentDefault)
    }

    private lazy var paymentLinkDetailsView = UIStackView(
        arrangedSubviews: [paymentLinkTitle, paymentLinkSubtitle],
        axis: .vertical,
        alignment: .center
    )

    private lazy var actionsView = UIStackView(axis: .vertical).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(theme.spacing.horizontal.value8)
    }

    init(presenter: PaymentLinkSharingPresenter) {
        self.presenter = presenter
        super.init(refreshAction: presenter.refresh)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        presenter.viewLoaded(with: self)
    }

    func configure(with viewModel: PaymentLinkSharingViewModel) {
        qrCodeImageView.image = viewModel.qrCodeImage
        paymentLinkTitle.text = viewModel.title
        paymentLinkSubtitle.text = viewModel.amount

        actionsView.removeAllArrangedSubviews()
        for navigationOption in viewModel.navigationOptions {
            actionsView.addArrangedSubview(
                StackNavigationOptionView(
                    viewModel: navigationOption.viewModel,
                    onTap: navigationOption.onTap
                )
            )
        }
    }
}

private extension PaymentLinkSharingViewController {
    func setupViews() {
        arrangedSubviews = [
            qrCodeContainer,
            .spacer(theme.spacing.vertical.componentDefault),
            paymentLinkDetailsView,
            .spacer(theme.spacing.vertical.betweenText),
            actionsView,
        ]
    }
}
