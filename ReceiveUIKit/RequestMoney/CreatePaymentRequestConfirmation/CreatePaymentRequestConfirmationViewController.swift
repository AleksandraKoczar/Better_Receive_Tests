import TransferResources
import TWUI

// sourcery: AutoMockable
protocol CreatePaymentRequestConfirmationView: AnyObject {
    func configure(with viewModel: CreatePaymentRequestConfirmationViewModel)
    func showHud()
    func hideHud()
    func showDismissableAlert(title: String, message: String)
    func showSnackbar(message: String)
    func generateHapticFeedback()
    func showShareSheet(with text: String)
    func showPrivacyNotice(with viewModel: CreatePaymentRequestConfirmationPrivacyNoticeViewModel)
}

final class CreatePaymentRequestConfirmationViewController: AbstractViewController, OptsIntoAutoBackButton {
    private let presenter: CreatePaymentRequestConfirmationPresenter

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(
        contentView: stackView,
        margins: UIEdgeInsets(value: theme.spacing.horizontal.componentDefault)
    )

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            illustrationView,
            infoStackView,
            shareButtonStackView,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.componentDefault
    )

    private let illustrationView = IllustrationView()
    private lazy var infoStackView = UIStackView(
        arrangedSubviews: [
            titleLabel,
            infoLabel,
            privacyLabel,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.componentDefault
    )

    private let titleLabel = StackLabel()
    private let infoLabel = StackLabel().with {
        $0.numberOfLines = 0
    }

    private lazy var privacyLabel = StackMarkupLabel()

    private lazy var shareButtonStackView = UIStackView(
        axis: .horizontal
    ).with {
        $0.distribution = .fillEqually
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(
            top: theme.spacing.vertical.componentDefault,
            bottom: .zero,
            left: theme.spacing.horizontal.componentDefault,
            right: theme.spacing.horizontal.componentDefault
        )
    }

    private lazy var footerView = FooterView()

    // MARK: - Life cycle

    init(presenter: CreatePaymentRequestConfirmationPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredTheme = \.secondary
        setupSubviews()
        presenter.start(with: self)
    }

    private func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.safeContentArea)
        view.addSubview(footerView)
    }

    private func configurePrivacyLabel(with viewModel: CreatePaymentRequestConfirmationViewModel.LabelViewModel) {
        let textModel = MarkupLabelModel(
            text: viewModel.text ?? "",
            action: MarkupTapAction(
                accessibilityActionName: viewModel.text ?? "",
                handler: {
                    viewModel.action?()
                }
            )
        )
        privacyLabel.configure(with: MarkupLabel.Model(model: textModel))
        privacyLabel.setStyle(viewModel.style)
    }

    private func configureShareButtons(with viewModels: [CreatePaymentRequestConfirmationViewModel.ButtonViewModel]) {
        shareButtonStackView.removeAllArrangedSubviews()
        let buttons = viewModels.map { buttonViewModel in
            let button = CircularButton()
            button.setTitle(buttonViewModel.title, for: .normal)
            button.setIcon(buttonViewModel.icon, for: .normal)
            button.touchHandler = { buttonViewModel.action() }
            return button
        }
        shareButtonStackView.addArrangedSubviews(buttons)
    }
}

// MARK: - CustomDismissActionProvider

extension CreatePaymentRequestConfirmationViewController: CustomDismissActionProvider {
    func provideCustomDismissAction(ofType type: DismissActionType) -> (() -> Void)? {
        presenter.dismiss
    }
}

// MARK: - CreatePaymentRequestConfirmationView

extension CreatePaymentRequestConfirmationViewController: CreatePaymentRequestConfirmationView {
    func configure(with viewModel: CreatePaymentRequestConfirmationViewModel) {
        illustrationView.configure(with: viewModel.asset)
        titleLabel.configure(with: viewModel.title.text)
        titleLabel.setStyle(viewModel.title.style)
        infoLabel.configure(with: viewModel.info.text)
        infoLabel.setStyle(viewModel.info.style)
        configurePrivacyLabel(with: viewModel.privacyNotice)
        configureShareButtons(with: viewModel.shareButtons)

        if viewModel.shouldShowExtendedFooter {
            footerView.setConfiguration(.extended(
                primaryView: .primary,
                secondaryView: .tertiary
            ), animated: false)
            footerView.primaryViewModel = .init(title: L10n.PaymentRequest.Create.Confirm.FooterButton.title, handler: { [weak self] in
                self?.presenter.doneTapped()
            })
            footerView.secondaryViewModel = .init(title: L10n.PaymentRequest.Create.Confirm.GiveFeedback.title, handler: { [weak self] in
                self?.presenter.giveFeedbackTapped()
            })
        } else {
            footerView.setConfiguration(.simple(), animated: false)
            footerView.primaryViewModel = .init(title: L10n.PaymentRequest.Create.Confirm.FooterButton.title, handler: { [weak self] in
                self?.presenter.doneTapped()
            })
        }
    }

    func showSnackbar(message: String) {
        let configuration = SnackBarConfiguration(
            message: message
        )
        let snackBar = SnackBarView(configuration: configuration)
        snackBar.show(with: SnackBarBottomPosition(superview: view))
    }

    func generateHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func showShareSheet(with text: String) {
        guard let navigationController,
              let sourceView = shareButtonStackView.subviews.first else { return }
        let sharingController = UIActivityViewController.universalSharingController(
            forItems: [text],
            sourceView: sourceView
        )
        navigationController.present(sharingController, animated: UIView.shouldAnimate)
    }

    func showPrivacyNotice(with viewModel: CreatePaymentRequestConfirmationPrivacyNoticeViewModel) {
        let viewController = CreatePaymentRequestConfirmationPrivacyNoticeViewControllerFactory.make(
            viewModel: viewModel,
            presenter: presenter
        )
        let bottomSheet = presentBottomSheet(viewController)
        bottomSheet.shouldDismissOnDrag = true
    }
}
