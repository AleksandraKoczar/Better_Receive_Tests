import Combine
import LoggingKit
import Neptune
import SwiftUI
import TransferResources
import TWUI
import UIKit

// sourcery: AutoMockable
// sourcery: baseClass = "UIViewController"
protocol ReceiveMethodsQRSharingView: AnyObject {
    func configure(with viewModel: ReceiveMethodsQRSharingViewModel)
    func configureWithError(with: ErrorViewModel)
    func showSnackbar(message: String)
    func showShareSheet(text: String)
    func displayHud()
    func removeHud()
}

final class ReceiveMethodsQRSharingViewController: LCEViewController, OptsIntoAutoBackButton {
    private let presenter: ReceiveMethodsQRSharingPresenter
    private var errorView: TemplateLayoutViewController?

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(contentView: stackView)

    private lazy var titleLabel = StackLabel().with {
        $0.setStyle(\.screenTitle.centered)
        $0.padding = UIEdgeInsets(
            top: theme.spacing.vertical.value8,
            left: theme.spacing.horizontal.screen,
            right: theme.spacing.horizontal.screen
        )
    }

    private lazy var subtitleLabel = StackLabel().with {
        $0.setStyle(\.largeBody.centered)
        $0.padding = $0.theme.padding.screen.horizontal
    }

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            carouselStackView,
            shareButtonStackView,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.value24
    ).with {
        $0.setCustomSpacing(theme.spacing.vertical.value8, after: titleLabel)
    }

    private lazy var carouselStackView = UIStackView(alignment: .center).with {
        $0.distribution = .fill
    }

    private lazy var shareButtonStackView = UIStackView(
        axis: .horizontal
    ).with {
        $0.distribution = .fillEqually
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(theme.spacing.horizontal.value40)
    }

    private var footerView: FooterView?

    // MARK: - Life cycle

    init(presenter: ReceiveMethodsQRSharingPresenter) {
        self.presenter = presenter
        super.init(refreshAction: {})
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

    private func configureButtons(with viewModels: [ReceiveMethodsQRSharingViewModel.ButtonViewModel]) {
        shareButtonStackView.removeAllArrangedSubviews()
        let buttons = viewModels.map { viewModel in
            let style: any CircularButtonAppearance = viewModel.isPrimary
                ? PrimaryCircularButtonAppearance.primaryCircular
                : SecondaryCircularButtonAppearance.secondaryCircular
            let button = CircularButton(style: style)
            button.setTitle(viewModel.title, for: .normal)
            button.setIcon(viewModel.icon, for: .normal)
            button.touchHandler = { viewModel.action() }
            return button
        }
        shareButtonStackView.addArrangedSubviews(buttons)
        shareButtonStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -theme.spacing.vertical.value16).isActive = true
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

    func configureWithError(with errorViewModel: ErrorViewModel) {
        tw_contentUnavailableConfiguration = nil
        tw_contentUnavailableConfiguration = .error(errorViewModel)
    }
}

// MARK: - WisetagView

extension ReceiveMethodsQRSharingViewController {
    func configureQRCodeView(keys: [ReceiveMethodsQRSharingViewModel.Key]) {
        if #available(iOS 17.0, *) {
            var carouselView = CarouselView(
                items: keys,
                cardView: { key in
                    PixCardContentView(
                        item: PixCardContentViewModel(
                            image: key.qr,
                            value: key.value,
                            titleName: L10n.Receive.Pix.Share.pix,
                            typeName: key.type
                        )
                    )
                },
                onTap: { _ in },
                cardStyle: .pix
            )

            carouselView.activeIndexChanged = { [weak self] index in
                self?.presenter.activeIndexChanged(index)
            }

            let controller = SwiftUIHostingController<CarouselView>(
                content: { carouselView }
            )

            carouselStackView.addArrangedSubviews(controller.view)
        } else {
            // TODO: have a look
            let carouselTabView = CarouselTabView(
                items: keys,
                cardView: { key in
                    WisetagQRCodeView(
                        viewModel: WisetagQRCodeViewModel(
                            state: .qrCodeEnabled(
                                qrCode: key.qr,
                                enabledText: key.value,
                                enabledTextOnTap: key.method.name,
                                onTap: {}
                            )
                        )
                    )
                },
                onTap: { _ in },
                cardStyle: .regular
            )

            let controller = SwiftUIHostingController<CarouselTabView>(
                content: { carouselTabView }
            )

            carouselStackView.addArrangedSubviews(controller.view)
        }
    }
}

extension ReceiveMethodsQRSharingViewController: ReceiveMethodsQRSharingView {
    func configure(with viewModel: ReceiveMethodsQRSharingViewModel) {
        titleLabel.configure(with: viewModel.title)
        subtitleLabel.configure(with: viewModel.subtitle)
        configureQRCodeView(keys: viewModel.keys)
        configureButtons(with: viewModel.buttons)
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

    func displayHud() {
        showHud()
    }

    func removeHud() {
        hideHud()
    }
}
