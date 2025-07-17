import Combine
import LoggingKit
import Neptune
import SwiftUI
import TWUI
import UIKit

// sourcery: AutoMockable
protocol WisetagView: AnyObject {
    var traitCollection: UITraitCollection { get }
    func configure(with viewModel: WisetagViewModel)
    func configureWithError(with: ErrorViewModel)
    func showSnackbar(message: String)
    func showShareSheet(text: String)
    func showHud()
    func hideHud()
}

final class WisetagViewController: AbstractViewController, OptsIntoAutoBackButton {
    private let presenter: WisetagPresenter
    private var errorView: TemplateLayoutViewController?

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(contentView: stackView)

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            header,
            qrCodeStackView,
            shareButtonStackView,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.value24
    )

    let header = WisetagHeaderView()

    private lazy var qrCodeStackView = UIStackView()

    private lazy var shareButtonStackView = UIStackView(
        axis: .horizontal
    ).with {
        $0.distribution = .fillEqually
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(theme.spacing.horizontal.value40)
    }

    private var footerView: FooterView?

    // MARK: - Life cycle

    init(presenter: WisetagPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        presenter.start(with: self)
    }

    private func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)
        scrollView.constrainToSuperview(.safeContentArea)
    }

    // MARK: - Helpers

    private func configureShareButtons(with viewModels: [WisetagViewModel.ButtonViewModel]) {
        shareButtonStackView.removeAllArrangedSubviews()
        let buttons = viewModels.map { viewModel in
            let button = CircularButton()
            button.setTitle(viewModel.title, for: .normal)
            button.setIcon(viewModel.icon, for: .normal)
            button.touchHandler = { viewModel.action() }
            return button
        }
        shareButtonStackView.addArrangedSubviews(buttons)
    }

    private func configureFooter(with action: Action?) {
        self.footerView?.removeFromSuperview()
        guard let action else {
            return
        }
        let footerView = FooterView(
            configuration: .simple(separatorHidden: .never)
        )
        footerView.primaryViewModel = .init(action)
        view.addSubview(footerView)
        self.footerView = footerView
    }

    private func configureRightBarButtonItems(with viewModels: [WisetagViewModel.ButtonViewModel]) {
        navigationItem.rightBarButtonItems = []
        navigationItem.rightBarButtonItems = viewModels.map { viewModel in
            let barButtonItem = UIBarButtonItem()
            barButtonItem.customView = IconButtonView(
                icon: viewModel.icon,
                discoverabilityTitle: viewModel.title,
                style: .iconSecondaryNeutral(size: .size32),
                handler: viewModel.action
            )
            return barButtonItem
        }
        let spacingItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacingItem.width = theme.spacing.horizontal.componentDefault

        if navigationItem.rightBarButtonItems.isNonEmpty {
            navigationItem.rightBarButtonItems?.insert(spacingItem, at: 1)
        }
    }

    func configureWithError(with errorViewModel: ErrorViewModel) {
        tw_contentUnavailableConfiguration = nil
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }
}

// MARK: - WisetagView

extension WisetagViewController {
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
}

extension WisetagViewController: WisetagView {
    func configure(with viewModel: WisetagViewModel) {
        header.configure(with: viewModel.header)
        configureQRCodeView(viewModel: viewModel.qrCode)
        configureShareButtons(with: viewModel.shareButtons)
        configureFooter(with: viewModel.footerAction)
        configureRightBarButtonItems(with: viewModel.navigationBarButtons)
    }

    func showSnackbar(message: String) {
        let configuration = SnackBarConfiguration(
            message: message
        )
        let snackBar = SnackBarView(configuration: configuration)
        snackBar.show(with: SnackBarBottomPosition(superview: view))
    }

    func showShareSheet(text: String) {
        guard let navigationController,
              let sourceView = shareButtonStackView.subviews.first else { return }
        let sharingController = UIActivityViewController.universalSharingController(
            forItems: [text],
            sourceView: sourceView
        )
        navigationController.present(sharingController, animated: UIView.shouldAnimate)
    }
}

// MARK: - CustomDismissActionProvider

extension WisetagViewController: CustomDismissActionProvider {
    // We have to use `CustomDismissActionProvider` instead of `HasPreDismissAction`
    // because we want to avoid standard dismiss action of poping out the view controller
    func provideCustomDismissAction(ofType type: DismissActionType) -> (() -> Void)? {
        { [weak self] in
            self?.presenter.dismiss()
        }
    }
}
