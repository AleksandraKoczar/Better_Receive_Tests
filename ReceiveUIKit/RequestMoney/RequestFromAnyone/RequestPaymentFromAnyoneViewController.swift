import LoggingKit
import TransferResources
import TWFoundation
import TWUI
import WiseCore

// sourcery: AutoMockable
protocol RequestPaymentFromAnyoneView: AnyObject {
    func configure(with viewModel: RequestPaymentFromAnyoneViewModel)
    func showShareSheet(text: String)
    func showDismissableAlert(title: String, message: String)
    func showHud()
    func hideHud()
}

final class RequestPaymentFromAnyoneViewController: UIViewController, OptsIntoAutoBackButton {
    private let presenter: RequestFromAnyonePresenter

    init(presenter: RequestFromAnyonePresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "RequestPaymentFromAnyoneView"
        presenter.start(with: self)
        setupSubviews()
    }

    // MARK: - Helpers

    private func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.safeContentArea)
    }

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(
        contentView: stackView,
        margins: .horizontal(.defaultMargin)
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private let headerView = LargeTitleView()

    private lazy var footerView = FooterView()

    private lazy var qrCodeStackView = UIStackView()

    private lazy var stackView = UIStackView(arrangedSubviews: [
        headerView,
        qrCodeStackView,
    ])
    .with {
        $0.axis = .vertical
        $0.spacing = theme.spacing.vertical.value48
    }
}

extension RequestPaymentFromAnyoneViewController: RequestPaymentFromAnyoneView {
    func configure(with viewModel: RequestPaymentFromAnyoneViewModel) {
        headerView.configure(with: viewModel.titleViewModel)
        configureQRCodeView(viewModel: viewModel.qrCodeViewModel)
        configureFooter(with: viewModel.primaryActionFooter, with: viewModel.secondaryActionFooter)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: viewModel.doneAction)
    }

    func configureFooter(with primaryAction: Action, with secondaryAction: Action?) {
        self.footerView.removeFromSuperview()
        let footerView = FooterView(configuration: .extended(separatorHidden: .never))
        footerView.primaryViewModel = .init(primaryAction)
        footerView.secondaryViewModel = .init(secondaryAction)
        view.addSubview(footerView)
        self.footerView = footerView
    }

    func configureQRCodeView(viewModel: WisetagQRCodeViewModel) {
        qrCodeStackView.removeAllArrangedSubviews()
        let qrCodeView = WisetagQRCodeView(viewModel: viewModel)
        let controller = SwiftUIHostingController<WisetagQRCodeView>(
            content: { qrCodeView }
        )
        qrCodeStackView.addArrangedSubviews(controller.view)
        qrCodeStackView.alignment = .center
        qrCodeStackView.distribution = .fill
    }

    func showShareSheet(text: String) {
        guard let navigationController else { return }
        let sharingController = UIActivityViewController.universalSharingController(
            forItems: [text],
            sourceView: footerView
        )
        sharingController.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            self?.presenter.finishSharing(didShareWisetag: completed)
        }
        navigationController.present(sharingController, animated: UIView.shouldAnimate)
    }
}
